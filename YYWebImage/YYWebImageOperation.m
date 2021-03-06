//
//  YYWebImageOperation.m
//  YYWebImage <https://github.com/ibireme/YYWebImage>
//
//  Created by ibireme on 15/2/15.
//  Copyright (c) 2015 ibireme.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "YYWebImageOperation.h"
#import "UIImage+YYWebImage.h"
#import <ImageIO/ImageIO.h>
#import <libkern/OSAtomic.h>

#if __has_include(<YYImage/YYImage.h>)
#import <YYImage/YYImage.h>
#else
#import "YYImage.h"
#endif


#define MIN_PROGRESSIVE_TIME_INTERVAL 0.2
#define MIN_PROGRESSIVE_BLUR_TIME_INTERVAL 0.4


/// Returns nil in App Extension.
static UIApplication *_YYSharedApplication() {
    static BOOL isAppExtension = NO;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class cls = NSClassFromString(@"UIApplication");
        if(!cls || ![cls respondsToSelector:@selector(sharedApplication)]) isAppExtension = YES;
        if ([[[NSBundle mainBundle] bundlePath] hasSuffix:@".appex"]) isAppExtension = YES;
    });
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    return isAppExtension ? nil : [UIApplication performSelector:@selector(sharedApplication)];
#pragma clang diagnostic pop
}

/// Returns YES if the right-bottom pixel is filled.
static BOOL YYCGImageLastPixelFilled(CGImageRef image) {
    if (!image) return NO;
    size_t width = CGImageGetWidth(image);
    size_t height = CGImageGetHeight(image);
    if (width == 0 || height == 0) return NO;
    CGContextRef ctx = CGBitmapContextCreate(NULL, 1, 1, 8, 0, YYCGColorSpaceGetDeviceRGB(), kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrderDefault);
    if (!ctx) return NO;
    CGContextDrawImage(ctx, CGRectMake( -(int)width + 1, 0, width, height), image);
    uint8_t *bytes = CGBitmapContextGetData(ctx);
    BOOL isAlpha = bytes && bytes[0] == 0;
    CFRelease(ctx);
    return !isAlpha;
}

/// Returns JPEG SOS (Start Of Scan) Marker
static NSData *JPEGSOSMarker() {
    // "Start Of Scan" Marker
    static NSData *marker = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        uint8_t bytes[2] = {0xFF, 0xDA};
        marker = [NSData dataWithBytes:bytes length:2];
    });
    return marker;
}


static NSMutableSet *URLBlacklist;
static dispatch_semaphore_t URLBlacklistLock;

static void URLBlacklistInit() {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        URLBlacklist = [NSMutableSet new];
        URLBlacklistLock = dispatch_semaphore_create(1);
    });
}

static BOOL URLBlackListContains(NSURL *url) {
    if (!url || url == (id)[NSNull null]) return NO;
    URLBlacklistInit();
    dispatch_semaphore_wait(URLBlacklistLock, DISPATCH_TIME_FOREVER);
    BOOL contains = [URLBlacklist containsObject:url];
    dispatch_semaphore_signal(URLBlacklistLock);
    return contains;
}

static void URLInBlackListAdd(NSURL *url) {
    if (!url || url == (id)[NSNull null]) return;
    URLBlacklistInit();
    dispatch_semaphore_wait(URLBlacklistLock, DISPATCH_TIME_FOREVER);
    [URLBlacklist addObject:url];
    dispatch_semaphore_signal(URLBlacklistLock);
}


/// A proxy used to hold a weak object.
@interface _YYWebImageWeakProxy : NSProxy
@property (nonatomic, weak, readonly) id target;
- (instancetype)initWithTarget:(id)target;
+ (instancetype)proxyWithTarget:(id)target;
@end

@implementation _YYWebImageWeakProxy
- (instancetype)initWithTarget:(id)target {
    _target = target;
    return self;
}
+ (instancetype)proxyWithTarget:(id)target {
    return [[_YYWebImageWeakProxy alloc] initWithTarget:target];
}
- (id)forwardingTargetForSelector:(SEL)selector {
    return _target;
}
- (void)forwardInvocation:(NSInvocation *)invocation {
    void *null = NULL;
    [invocation setReturnValue:&null];
}
- (NSMethodSignature *)methodSignatureForSelector:(SEL)selector {
    return [NSObject instanceMethodSignatureForSelector:@selector(init)];
}
- (BOOL)respondsToSelector:(SEL)aSelector {
    return [_target respondsToSelector:aSelector];
}
- (BOOL)isEqual:(id)object {
    return [_target isEqual:object];
}
- (NSUInteger)hash {
    return [_target hash];
}
- (Class)superclass {
    return [_target superclass];
}
- (Class)class {
    return [_target class];
}
- (BOOL)isKindOfClass:(Class)aClass {
    return [_target isKindOfClass:aClass];
}
- (BOOL)isMemberOfClass:(Class)aClass {
    return [_target isMemberOfClass:aClass];
}
- (BOOL)conformsToProtocol:(Protocol *)aProtocol {
    return [_target conformsToProtocol:aProtocol];
}
- (BOOL)isProxy {
    return YES;
}
- (NSString *)description {
    return [_target description];
}
- (NSString *)debugDescription {
    return [_target debugDescription];
}
@end

@interface YYWebImageImageSources : NSObject

@property (nullable, nonatomic, strong) UIImage *finalImage;
@property (nullable, nonatomic, strong) UIImage *originalImage;

@end

@implementation YYWebImageImageSources

@end

@interface YYWebImageOperation() <NSURLConnectionDelegate>
@property (readwrite, getter=isExecuting) BOOL executing;
@property (readwrite, getter=isFinished) BOOL finished;
@property (readwrite, getter=isCancelled) BOOL cancelled;
@property (readwrite, getter=isStarted) BOOL started;
@property (nonatomic, strong) NSRecursiveLock *lock;
@property (nonatomic, strong) NSURLConnection *connection;
@property (nonatomic, strong) NSMutableData *data;
@property (nonatomic, assign) NSInteger expectedSize;
@property (nonatomic, assign) UIBackgroundTaskIdentifier taskID;

@property (nonatomic, assign) NSTimeInterval lastProgressiveDecodeTimestamp;
@property (nonatomic, strong) YYImageDecoder *progressiveDecoder;
@property (nonatomic, assign) BOOL progressiveIgnored;
@property (nonatomic, assign) BOOL progressiveDetected;
@property (nonatomic, assign) NSUInteger progressiveScanedLength;
@property (nonatomic, assign) NSUInteger progressiveDisplayCount;

@property (nonatomic, copy) YYWebImageProgressBlock progress;
@property (nonatomic, copy) YYWebImageTransformBlock transform;
@property (nonatomic, copy) YYWebImageCompletionBlock completion;
@end


@implementation YYWebImageOperation
@synthesize executing = _executing;
@synthesize finished = _finished;
@synthesize cancelled = _cancelled;

/// Network thread entry point.
+ (void)_networkThreadMain:(id)object {
    @autoreleasepool {
        [[NSThread currentThread] setName:@"com.ibireme.webimage.request"];
        NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
        [runLoop addPort:[NSMachPort port] forMode:NSDefaultRunLoopMode];
        [runLoop run];
    }
}

/// Global image request network thread, used by NSURLConnection delegate.
+ (NSThread *)_networkThread {
    static NSThread *thread = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        thread = [[NSThread alloc] initWithTarget:self selector:@selector(_networkThreadMain:) object:nil];
        if ([thread respondsToSelector:@selector(setQualityOfService:)]) {
            thread.qualityOfService = NSQualityOfServiceBackground;
        }
        [thread start];
    });
    return thread;
}

/// Global image queue, used for image reading and decoding.
+ (dispatch_queue_t)_imageQueue {
    #define MAX_QUEUE_COUNT 16
    static int queueCount;
    static dispatch_queue_t queues[MAX_QUEUE_COUNT];
    static dispatch_once_t onceToken;
    static int32_t counter = 0;
    dispatch_once(&onceToken, ^{
        queueCount = (int)[NSProcessInfo processInfo].activeProcessorCount;
        queueCount = queueCount < 1 ? 1 : queueCount > MAX_QUEUE_COUNT ? MAX_QUEUE_COUNT : queueCount;
        if ([UIDevice currentDevice].systemVersion.floatValue >= 8.0) {
            for (NSUInteger i = 0; i < queueCount; i++) {
                dispatch_queue_attr_t attr = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_UTILITY, 0);
                queues[i] = dispatch_queue_create("com.ibireme.image.decode", attr);
            }
        } else {
            for (NSUInteger i = 0; i < queueCount; i++) {
                queues[i] = dispatch_queue_create("com.ibireme.image.decode", DISPATCH_QUEUE_SERIAL);
                dispatch_set_target_queue(queues[i], dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0));
            }
        }
    });
    int32_t cur = OSAtomicIncrement32(&counter);
    if (cur < 0) cur = -cur;
    return queues[(cur) % queueCount];
    #undef MAX_QUEUE_COUNT
}

- (instancetype)init {
    @throw [NSException exceptionWithName:@"YYWebImageOperation init error" reason:@"YYWebImageOperation must be initialized with a request. Use the designated initializer to init." userInfo:nil];
    return [self initWithRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@""]] options:0 itemOption:nil cache:nil cacheKey:nil processor:nil progress:nil transform:nil completion:nil];
}

- (instancetype)initWithRequest:(NSURLRequest *)request
                        options:(YYWebImageOptions)options
                     itemOption:(YYWebImageItemOption *)itemOption
                          cache:(YYImageCache *)cache
                       cacheKey:(NSString *)cacheKey
                      processor:(id<YYWebImageProcessor>)processor
                       progress:(YYWebImageProgressBlock)progress
                      transform:(YYWebImageTransformBlock)transform
                     completion:(YYWebImageCompletionBlock)completion {
    self = [super init];
    if (!self) return nil;
    if (!request) return nil;
    _request = request;
    _options = options;
    _cache = cache;
    _cacheKey = cacheKey ? cacheKey : request.URL.absoluteString;
    _processor = processor;
    _shouldUseCredentialStorage = YES;
    _progress = progress;
    _transform = transform;
    _completion = completion;
    _executing = NO;
    _finished = NO;
    _cancelled = NO;
    _taskID = UIBackgroundTaskInvalid;
    _lock = [NSRecursiveLock new];
    _itemOption = itemOption;
    return self;
}

- (void)dealloc {
    [_lock lock];
    if (_taskID != UIBackgroundTaskInvalid) {
        [_YYSharedApplication() endBackgroundTask:_taskID];
        _taskID = UIBackgroundTaskInvalid;
    }
    if ([self isExecuting]) {
        self.cancelled = YES;
        self.finished = YES;
        if (_connection) {
            [_connection cancel];
            if (![_request.URL isFileURL] && (_options & YYWebImageOptionShowNetworkActivity)) {
                [YYWebImageManager decrementNetworkActivityCount];
            }
        }
        if (_completion) {
            @autoreleasepool {
                _completion(nil, _request.URL, YYWebImageFromNone, YYWebImageStageCancelled, nil);
            }
        }
    }
    [_lock unlock];
}

- (void)_endBackgroundTask {
    [_lock lock];
    if (_taskID != UIBackgroundTaskInvalid) {
        [_YYSharedApplication() endBackgroundTask:_taskID];
        _taskID = UIBackgroundTaskInvalid;
    }
    [_lock unlock];
}

#pragma mark - Runs in operation thread

- (void)_finish {
    self.executing = NO;
    self.finished = YES;
    [self _endBackgroundTask];
}

// runs on network thread
- (void)_startOperation {
    if ([self isCancelled]) return;
    @autoreleasepool {
        // get image from cache
        if (_cache &&
            !(_options & YYWebImageOptionUseNSURLCache) &&
            !(_options & YYWebImageOptionRefreshImageCache)) {
            
            // if processor is not nil then temporary set kYYWebImageOptionBeProcessed to YES try to hit memory cache
            if (self.processor) {
                _itemOption.beProcessed = YES;
            }
            
            // if transform is not nil then temporary set kYYWebImageOptionBeTransformed to YES try to hit memory cache
            if (self.transform) {
                _itemOption.beTransformed = YES;
            }
            
            // diffrent cache type use diffrent cache key
            NSString *memoryCacheKey = [_itemOption cacheKeyForMemoryCache:_cacheKey];
            NSString *diskCacheKey = [_itemOption cacheKeyForDiskCache:_cacheKey];
            
            // try key mode: URL_widthPixel_x_heightPixel_[YYWebImageProcessor`s identifier]_[transform`s identifier]
            UIImage *image = [_cache getImageForKey:memoryCacheKey withType:YYImageCacheTypeMemory];

            // try key mode: URL_widthPixel_x_heightPixel_[transform`s identifier]
            if (!image) {
                _itemOption.beProcessed = NO;
                memoryCacheKey = [_itemOption cacheKeyForMemoryCache:_cacheKey];
                image = [_cache getImageForKey:memoryCacheKey withType:YYImageCacheTypeMemory];
            }
            
            // try key mode: URL. if needed.
            if (!image && (!self.transform || (self.options & YYWebImageOptionAllowHitMemoryByDiskKeyWithValidTransform))) {
                if (![diskCacheKey isEqualToString:memoryCacheKey]) {
                    image = [_cache getImageForKey:diskCacheKey withType:YYImageCacheTypeMemory];
                }
            }
            
            if (image) {
                [_lock lock];
                if (![self isCancelled]) {
                    if (_completion) _completion(image, _request.URL, YYWebImageFromMemoryCache, YYWebImageStageFinished, nil);
                }
                [self _finish];
                [_lock unlock];
                return;
            }
            
            // reset beProcessed and beTransformed to NO
            _itemOption.beProcessed = NO;
            _itemOption.beTransformed = NO;
            
            if (!(_options & YYWebImageOptionIgnoreDiskCache)) {
                __weak typeof(self) _self = self;
                dispatch_async([self.class _imageQueue], ^{
                    __strong typeof(_self) self = _self;
                    if (!self || [self isCancelled]) return;
                    UIImage *image = [self _getImageFromDisk:diskCacheKey];
                    if (image) {
                        // add to memory cache
                        NSString *cacheKey = diskCacheKey;
                        if (self.itemOption.beProcessed || self.itemOption.beTransformed) {
                            // generate a new memoryCacheKey because of information has changed
                            NSString *memoryCacheKey = [self.itemOption cacheKeyForMemoryCache:self.cacheKey];
                            cacheKey = memoryCacheKey;
                        }
                        [self.cache setImage:image imageData:nil forKey:cacheKey withType:YYImageCacheTypeMemory];
                        [self performSelector:@selector(_didReceiveImageFromDiskCache:) onThread:[self.class _networkThread] withObject:image waitUntilDone:NO];
                    } else {
                        [self performSelector:@selector(_startRequest:) onThread:[self.class _networkThread] withObject:nil waitUntilDone:NO];
                    }
                });
                return;
            }
        }
    }
    [self performSelector:@selector(_startRequest:) onThread:[self.class _networkThread] withObject:nil waitUntilDone:NO];
}

// runs on network thread
- (void)_startRequest:(id)object {
    if ([self isCancelled]) return;
    @autoreleasepool {
        if ((_options & YYWebImageOptionIgnoreFailedURL) && URLBlackListContains(_request.URL)) {
            NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorFileDoesNotExist userInfo:@{ NSLocalizedDescriptionKey : @"Failed to load URL, blacklisted." }];
            [_lock lock];
            if (![self isCancelled]) {
                if (_completion) _completion(nil, _request.URL, YYWebImageFromNone, YYWebImageStageFinished, error);
            }
            [self _finish];
            [_lock unlock];
            return;
        }
        
        if (_request.URL.isFileURL) {
            NSArray *keys = @[NSURLFileSizeKey];
            NSDictionary *attr = [_request.URL resourceValuesForKeys:keys error:nil];
            NSNumber *fileSize = attr[NSURLFileSizeKey];
            _expectedSize = (fileSize != nil) ? fileSize.unsignedIntegerValue : -1;
        }
        
        // request image from web
        [_lock lock];
        if (![self isCancelled]) {
            _connection = [[NSURLConnection alloc] initWithRequest:_request delegate:[_YYWebImageWeakProxy proxyWithTarget:self]];
            [_connection start];
            if (![_request.URL isFileURL] && (_options & YYWebImageOptionShowNetworkActivity)) {
                [YYWebImageManager incrementNetworkActivityCount];
            }
        }
        [_lock unlock];
    }
}

// runs on network thread, called from outer "cancel"
- (void)_cancelOperation {
    @autoreleasepool {
        if (_connection) {
            if (![_request.URL isFileURL] && (_options & YYWebImageOptionShowNetworkActivity)) {
                [YYWebImageManager decrementNetworkActivityCount];
            }
        }
        [_connection cancel];
        _connection = nil;
        if (_completion) _completion(nil, _request.URL, YYWebImageFromNone, YYWebImageStageCancelled, nil);
        [self _endBackgroundTask];
    }
}


// runs on network thread
- (void)_didReceiveImageFromDiskCache:(UIImage *)image {
    @autoreleasepool {
        [_lock lock];
        if (![self isCancelled]) {
            if (image) {
                if (_completion) _completion(image, _request.URL, YYWebImageFromDiskCache, YYWebImageStageFinished, nil);
                [self _finish];
            } else {
                [self _startRequest:nil];
            }
        }
        [_lock unlock];
    }
}

- (void)_didReceiveImageFromWeb:(YYWebImageImageSources *)imageSources {
    @autoreleasepool {
        [_lock lock];
        if (![self isCancelled]) {
            UIImage *finalImage = imageSources.finalImage;
            UIImage *originalImage = imageSources.originalImage;
            if (_cache) {
                if (finalImage || (_options & YYWebImageOptionRefreshImageCache)) {
                    [self _cacheImage:finalImage originalImage:originalImage imageData: _data];
                }
            }
            _data = nil;
            NSError *error = nil;
            if (!finalImage) {
                error = [NSError errorWithDomain:@"com.ibireme.image" code:-1 userInfo:@{ NSLocalizedDescriptionKey : @"Web image decode fail." }];
                if (_options & YYWebImageOptionIgnoreFailedURL) {
                    if (URLBlackListContains(_request.URL)) {
                        error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorFileDoesNotExist userInfo:@{ NSLocalizedDescriptionKey : @"Failed to load URL, blacklisted." }];
                    } else {
                        URLInBlackListAdd(_request.URL);
                    }
                }
            }
            if (_completion) _completion(finalImage, _request.URL, YYWebImageFromRemote, YYWebImageStageFinished, error);
            [self _finish];
        }
        [_lock unlock];
    }
}

#pragma mark - Cache Operation. Include get from cache and store to cache

- (nullable UIImage *)_getImageFromDisk:(NSString *)cacheKey {
    UIImage *image;
    YYImageType imageType = YYImageTypeUnknown;
    BOOL hasAnimation = NO;
    
    NSData *data = (id)[_cache objectForKey:cacheKey withType:YYImageCacheTypeDisk];
    if (data) {
        imageType = YYImageDetectType((__bridge CFDataRef)data);
        BOOL shouldDecode = (_options & YYWebImageOptionIgnoreImageDecoding) == 0;
        BOOL allowAnimation = (_options & YYWebImageOptionIgnoreAnimatedImage) == 0;
        _itemOption.imageType = imageType;
        switch (imageType) {
            case YYImageTypeJPEG:
            case YYImageTypePNG: {
                // try use processor handler
                if (self.processor) {
                    UIImage * processedImage = [_processor processData:data shouldDecode:shouldDecode itemOption:_itemOption];
                    if (processedImage) {
                        image = processedImage;
                        _itemOption.beProcessed = YES;
                    }
                }
            } break;
            default: break;
        }

        if ([self isCancelled]) return nil;
        
        if (!image) {
            image = [_cache getImageFromData:data];
        }
        
        if (allowAnimation) {
            if ([image isKindOfClass:[YYImage class]]) {
                if (((YYImage *)image).animatedImageFrameCount > 1) {
                    hasAnimation = YES;
                }
            }
        }
    }
    
    if ([self isCancelled]) return nil;
    
    // transform image if needed.
    Boolean allowAnimatedImageTransform = (_options & YYWebImageOptionAllowAnimatedImageTransform);
    if (_transform && image && (!hasAnimation || allowAnimatedImageTransform)) {
        UIImage *newImage = _transform(imageType, image, _request.URL);
        if (newImage != image) {
            image = newImage;
            _itemOption.beTransformed = YES;
        }
        if ([self isCancelled]) return nil;
    }
    
    return image;
}

- (void)_cacheImage:(UIImage *)finalImage originalImage:(UIImage *)originalImage imageData:(NSData *)imageData {
    NSString *originalCacheKey = _cacheKey;
    if (!originalCacheKey || (finalImage == nil && originalImage == nil && imageData.length == 0)) return;
    
    // diffrent cache type use diffrent cache key
    NSString *diskCacheKey = [_itemOption cacheKeyForDiskCache:_cacheKey];
    NSString *memoryCacheKey = diskCacheKey;
    if (_itemOption.beProcessed || _itemOption.beTransformed) {
        memoryCacheKey = [_itemOption cacheKeyForMemoryCache:_cacheKey];
    }
    
    NSData *data = _data;
    
    // dispatch to _imageQueue execute task
    dispatch_async([YYWebImageOperation _imageQueue], ^{
        YYImageCacheType cacheType = (_options & YYWebImageOptionIgnoreDiskCache) ? YYImageCacheTypeMemory : YYImageCacheTypeAll;

        if (cacheType & YYImageCacheTypeMemory) { // add to memory cache
            [_cache setImage:finalImage imageData:data forKey:memoryCacheKey withType:YYImageCacheTypeMemory];
        }
        
        if (cacheType & YYImageCacheTypeDisk) { // add to disk cache
            [_cache setImage:originalImage imageData:data forKey:diskCacheKey withType:YYImageCacheTypeDisk];
        }
    });
}

#pragma mark - NSURLConnectionDelegate runs in operation thread

- (BOOL)connectionShouldUseCredentialStorage:(NSURLConnection *)connection {
    return _shouldUseCredentialStorage;
}

- (void)connection:(NSURLConnection *)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    @autoreleasepool {
        if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
            if (!(_options & YYWebImageOptionAllowInvalidSSLCertificates) &&
                [challenge.sender respondsToSelector:@selector(performDefaultHandlingForAuthenticationChallenge:)]) {
                [challenge.sender performDefaultHandlingForAuthenticationChallenge:challenge];
            } else {
                NSURLCredential *credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
                [[challenge sender] useCredential:credential forAuthenticationChallenge:challenge];
            }
        } else {
            if ([challenge previousFailureCount] == 0) {
                if (_credential) {
                    [[challenge sender] useCredential:_credential forAuthenticationChallenge:challenge];
                } else {
                    [[challenge sender] continueWithoutCredentialForAuthenticationChallenge:challenge];
                }
            } else {
                [[challenge sender] continueWithoutCredentialForAuthenticationChallenge:challenge];
            }
        }
    }
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse {
    if (!cachedResponse) return cachedResponse;
    if (_options & YYWebImageOptionUseNSURLCache) {
        return cachedResponse;
    } else {
        // ignore NSURLCache
        return nil;
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    @autoreleasepool {
        NSError *error = nil;
        if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
            NSHTTPURLResponse *httpResponse = (id) response;
            NSInteger statusCode = httpResponse.statusCode;
            if (statusCode >= 400 || statusCode == 304) {
                error = [NSError errorWithDomain:NSURLErrorDomain code:statusCode userInfo:nil];
            }
        }
        if (error) {
            [_connection cancel];
            [self connection:_connection didFailWithError:error];
        } else {
            if (response.expectedContentLength) {
                _expectedSize = (NSInteger)response.expectedContentLength;
                if (_expectedSize < 0) _expectedSize = -1;
            }
            _data = [NSMutableData dataWithCapacity:_expectedSize > 0 ? _expectedSize : 0];
            if (_progress) {
                [_lock lock];
                if (![self isCancelled]) _progress(0, _expectedSize);
                [_lock unlock];
            }
        }
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    @autoreleasepool {
        [_lock lock];
        BOOL canceled = [self isCancelled];
        [_lock unlock];
        if (canceled) return;
        
        if (data) [_data appendData:data];
        if (_progress) {
            [_lock lock];
            if (![self isCancelled]) {
                _progress(_data.length, _expectedSize);
            }
            [_lock unlock];
        }
        
        /*--------------------------- progressive ----------------------------*/
        BOOL progressive = (_options & YYWebImageOptionProgressive) > 0;
        BOOL progressiveBlur = (_options & YYWebImageOptionProgressiveBlur) > 0;
        if (!_completion || !(progressive || progressiveBlur)) return;
        if (data.length <= 16) return;
        if (_expectedSize > 0 && data.length >= _expectedSize * 0.99) return;
        if (_progressiveIgnored) return;
        
        NSTimeInterval min = progressiveBlur ? MIN_PROGRESSIVE_BLUR_TIME_INTERVAL : MIN_PROGRESSIVE_TIME_INTERVAL;
        NSTimeInterval now = CACurrentMediaTime();
        if (now - _lastProgressiveDecodeTimestamp < min) return;
        
        if (!_progressiveDecoder) {
            _progressiveDecoder = [[YYImageDecoder alloc] initWithScale:[UIScreen mainScreen].scale];
        }
        [_progressiveDecoder updateData:_data final:NO];
        if ([self isCancelled]) return;
        
        if (_progressiveDecoder.type == YYImageTypeUnknown ||
            _progressiveDecoder.type == YYImageTypeWebP ||
            _progressiveDecoder.type == YYImageTypeOther) {
            _progressiveDecoder = nil;
            _progressiveIgnored = YES;
            return;
        }
        if (progressiveBlur) { // only support progressive JPEG and interlaced PNG
            if (_progressiveDecoder.type != YYImageTypeJPEG &&
                _progressiveDecoder.type != YYImageTypePNG) {
                _progressiveDecoder = nil;
                _progressiveIgnored = YES;
                return;
            }
        }
        if (_progressiveDecoder.frameCount == 0) return;
        
        if (!progressiveBlur) {
            YYImageFrame *frame = [_progressiveDecoder frameAtIndex:0 decodeForDisplay:YES];
            if (frame.image) {
                [_lock lock];
                if (![self isCancelled]) {
                    _completion(frame.image, _request.URL, YYWebImageFromRemote, YYWebImageStageProgress, nil);
                    _lastProgressiveDecodeTimestamp = now;
                }
                [_lock unlock];
            }
            return;
        } else {
            if (_progressiveDecoder.type == YYImageTypeJPEG) {
                if (!_progressiveDetected) {
                    NSDictionary *dic = [_progressiveDecoder framePropertiesAtIndex:0];
                    NSDictionary *jpeg = dic[(id)kCGImagePropertyJFIFDictionary];
                    NSNumber *isProg = jpeg[(id)kCGImagePropertyJFIFIsProgressive];
                    if (!isProg.boolValue) {
                        _progressiveIgnored = YES;
                        _progressiveDecoder = nil;
                        return;
                    }
                    _progressiveDetected = YES;
                }
                
                NSInteger scanLength = (NSInteger)_data.length - (NSInteger)_progressiveScanedLength - 4;
                if (scanLength <= 2) return;
                NSRange scanRange = NSMakeRange(_progressiveScanedLength, scanLength);
                NSRange markerRange = [_data rangeOfData:JPEGSOSMarker() options:kNilOptions range:scanRange];
                _progressiveScanedLength = _data.length;
                if (markerRange.location == NSNotFound) return;
                if ([self isCancelled]) return;
                
            } else if (_progressiveDecoder.type == YYImageTypePNG) {
                if (!_progressiveDetected) {
                    NSDictionary *dic = [_progressiveDecoder framePropertiesAtIndex:0];
                    NSDictionary *png = dic[(id)kCGImagePropertyPNGDictionary];
                    NSNumber *isProg = png[(id)kCGImagePropertyPNGInterlaceType];
                    if (!isProg.boolValue) {
                        _progressiveIgnored = YES;
                        _progressiveDecoder = nil;
                        return;
                    }
                    _progressiveDetected = YES;
                }
            }
            
            YYImageFrame *frame = [_progressiveDecoder frameAtIndex:0 decodeForDisplay:YES];
            UIImage *image = frame.image;
            if (!image) return;
            if ([self isCancelled]) return;
            
            if (!YYCGImageLastPixelFilled(image.CGImage)) return;
            _progressiveDisplayCount++;
            
            CGFloat radius = 32;
            if (_expectedSize > 0) {
                radius *= 1.0 / (3 * _data.length / (CGFloat)_expectedSize + 0.6) - 0.25;
            } else {
                radius /= (_progressiveDisplayCount);
            }
            image = [image yy_imageByBlurRadius:radius tintColor:nil tintMode:0 saturation:1 maskImage:nil];
            
            if (image) {
                [_lock lock];
                if (![self isCancelled]) {
                    _completion(image, _request.URL, YYWebImageFromRemote, YYWebImageStageProgress, nil);
                    _lastProgressiveDecodeTimestamp = now;
                }
                [_lock unlock];
            }
        }
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    @autoreleasepool {
        [_lock lock];
        _connection = nil;
        if (![self isCancelled]) {
            __weak typeof(self) _self = self;
            dispatch_async([self.class _imageQueue], ^{
                __strong typeof(_self) self = _self;
                if (!self) return;
                
                /*
                 copy info.
                 */
                /*NSMutableDictionary<NSString *, id> *info = [[NSMutableDictionary alloc] init];
                [_info enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                    [info setValue:obj forKey:key];
                }];*/
                
                YYImageType imageType = YYImageDetectType((__bridge CFDataRef)self.data);
                BOOL shouldDecode = (self.options & YYWebImageOptionIgnoreImageDecoding) == 0;
                BOOL allowAnimation = (self.options & YYWebImageOptionIgnoreAnimatedImage) == 0;
                
                /*
                 append info.
                 */
                self.itemOption.imageType = imageType;
                self.itemOption.beProcessed = NO;
                self.itemOption.beTransformed = NO;
                
                UIImage *finalImage;
                UIImage *originalImage;
                BOOL hasAnimation = NO;
                
                /*
                 try handle by processor.
                 */
                if (self.processor) {
                    UIImage * processedImage = [self.processor processData:self.data shouldDecode:shouldDecode itemOption:self.itemOption];
                    if (processedImage) {
                        finalImage = processedImage;
                        self.itemOption.beProcessed = YES;
                    }
                }
                
                /*
                 processor handle failed, continue with default handler.
                 */
                if (!finalImage) {
                    if (allowAnimation) {
                        finalImage = [[YYImage alloc] initWithData:self.data scale:[UIScreen mainScreen].scale];
                        
                        if (!finalImage.yy_isDecodedForDisplay) {
                            if (shouldDecode) finalImage = [finalImage yy_imageByDecoded];
                        }
                        
                        if ([((YYImage *)finalImage) animatedImageFrameCount] > 1) {
                            hasAnimation = YES;
                        }
                    } else {
                        YYImageDecoder *decoder = [YYImageDecoder decoderWithData:self.data scale:[UIScreen mainScreen].scale];
                        finalImage = [decoder frameAtIndex:0 decodeForDisplay:shouldDecode].image;
                    }
                    
                    originalImage = finalImage;
                }
                
                /*
                 If the image has animation, save the original image data to disk cache.
                 If the image is not PNG or JPEG, re-encode the image to PNG or JPEG for
                 better decoding performance.
                 */
                switch (imageType) {
                    case YYImageTypeJPEG:
                    case YYImageTypeGIF:
                    case YYImageTypePNG:
                    case YYImageTypeWebP: { // save to disk cache
                        if (!hasAnimation) {
                            if (imageType == YYImageTypeGIF ||
                                imageType == YYImageTypeWebP) {
                                self.data = nil; // clear the data, re-encode for disk cache
                            }
                        }
                    } break;
                    default: {
                        self.data = nil; // clear the data, re-encode for disk cache
                    } break;
                }
                if ([self isCancelled]) return;
                
                // transform image if needed.
                Boolean allowAnimatedImageTransform = (self.options & YYWebImageOptionAllowAnimatedImageTransform);
                if (self.transform && finalImage && (!hasAnimation || allowAnimatedImageTransform)) {
                    UIImage *newImage = self.transform(imageType, finalImage, self.request.URL);
                    if (newImage != finalImage) {
                        finalImage = newImage;
                        self.itemOption.beTransformed = YES;
                    }
                    if ([self isCancelled]) return;
                }
                
                YYWebImageImageSources *imageSources = [YYWebImageImageSources new];
                imageSources.finalImage = finalImage;
                imageSources.originalImage = originalImage;
                [self performSelector:@selector(_didReceiveImageFromWeb:) onThread:[self.class _networkThread] withObject:imageSources waitUntilDone:NO];
            });
            if (![self.request.URL isFileURL] && (self.options & YYWebImageOptionShowNetworkActivity)) {
                [YYWebImageManager decrementNetworkActivityCount];
            }
        }
        [_lock unlock];
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    @autoreleasepool {
        [_lock lock];
        if (![self isCancelled]) {
            if (_completion) {
                _completion(nil, _request.URL, YYWebImageFromNone, YYWebImageStageFinished, error);
            }
            _connection = nil;
            _data = nil;
            if (![_request.URL isFileURL] && (_options & YYWebImageOptionShowNetworkActivity)) {
                [YYWebImageManager decrementNetworkActivityCount];
            }
            [self _finish];
            
            if (_options & YYWebImageOptionIgnoreFailedURL) {
                if (error.code != NSURLErrorNotConnectedToInternet &&
                    error.code != NSURLErrorCancelled &&
                    error.code != NSURLErrorTimedOut &&
                    error.code != NSURLErrorUserCancelledAuthentication &&
                    error.code != NSURLErrorNetworkConnectionLost) {
                    URLInBlackListAdd(_request.URL);
                }
            }
        }
        [_lock unlock];
    }
}

#pragma mark - Override NSOperation

- (void)start {
    @autoreleasepool {
        [_lock lock];
        self.started = YES;
        if ([self isCancelled]) {
            [self performSelector:@selector(_cancelOperation) onThread:[[self class] _networkThread] withObject:nil waitUntilDone:NO modes:@[NSDefaultRunLoopMode]];
            self.finished = YES;
        } else if ([self isReady] && ![self isFinished] && ![self isExecuting]) {
            if (!_request) {
                self.finished = YES;
                if (_completion) {
                    NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorFileDoesNotExist userInfo:@{NSLocalizedDescriptionKey:@"request in nil"}];
                    _completion(nil, _request.URL, YYWebImageFromNone, YYWebImageStageFinished, error);
                }
            } else {
                self.executing = YES;
                [self performSelector:@selector(_startOperation) onThread:[[self class] _networkThread] withObject:nil waitUntilDone:NO modes:@[NSDefaultRunLoopMode]];
                if ((_options & YYWebImageOptionAllowBackgroundTask) && _YYSharedApplication()) {
                    __weak __typeof__ (self) _self = self;
                    if (_taskID == UIBackgroundTaskInvalid) {
                        _taskID = [_YYSharedApplication() beginBackgroundTaskWithExpirationHandler:^{
                            __strong __typeof (_self) self = _self;
                            if (self) {
                                [self cancel];
                                self.finished = YES;
                            }
                        }];
                    }
                }
            }
        }
        [_lock unlock];
    }
}

- (void)cancel {
    [_lock lock];
    if (![self isCancelled]) {
        [super cancel];
        self.cancelled = YES;
        if ([self isExecuting]) {
            self.executing = NO;
            [self performSelector:@selector(_cancelOperation) onThread:[[self class] _networkThread] withObject:nil waitUntilDone:NO modes:@[NSDefaultRunLoopMode]];
        }
        if (self.started) {
            self.finished = YES;
        }
    }
    [_lock unlock];
}

- (void)setExecuting:(BOOL)executing {
    [_lock lock];
    if (_executing != executing) {
        [self willChangeValueForKey:@"isExecuting"];
        _executing = executing;
        [self didChangeValueForKey:@"isExecuting"];
    }
    [_lock unlock];
}

- (BOOL)isExecuting {
    [_lock lock];
    BOOL executing = _executing;
    [_lock unlock];
    return executing;
}

- (void)setFinished:(BOOL)finished {
    [_lock lock];
    if (_finished != finished) {
        [self willChangeValueForKey:@"isFinished"];
        _finished = finished;
        [self didChangeValueForKey:@"isFinished"];
    }
    [_lock unlock];
}

- (BOOL)isFinished {
    [_lock lock];
    BOOL finished = _finished;
    [_lock unlock];
    return finished;
}

- (void)setCancelled:(BOOL)cancelled {
    [_lock lock];
    if (_cancelled != cancelled) {
        [self willChangeValueForKey:@"isCancelled"];
        _cancelled = cancelled;
        [self didChangeValueForKey:@"isCancelled"];
    }
    [_lock unlock];
}

- (BOOL)isCancelled {
    [_lock lock];
    BOOL cancelled = _cancelled;
    [_lock unlock];
    return cancelled;
}

- (BOOL)isConcurrent {
    return YES;
}

- (BOOL)isAsynchronous {
    return YES;
}

+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)key {
    if ([key isEqualToString:@"isExecuting"] ||
        [key isEqualToString:@"isFinished"] ||
        [key isEqualToString:@"isCancelled"]) {
        return NO;
    }
    return [super automaticallyNotifiesObserversForKey:key];
}

- (NSString *)description {
    NSMutableString *string = [NSMutableString stringWithFormat:@"<%@: %p ",self.class, self];
    [string appendFormat:@" executing:%@", [self isExecuting] ? @"YES" : @"NO"];
    [string appendFormat:@" finished:%@", [self isFinished] ? @"YES" : @"NO"];
    [string appendFormat:@" cancelled:%@", [self isCancelled] ? @"YES" : @"NO"];
    [string appendString:@">"];
    return string;
}

@end
