//
//  UIButton+YYWebImage.m
//  YYWebImage <https://github.com/ibireme/YYWebImage>
//
//  Created by ibireme on 15/2/23.
//  Copyright (c) 2015 ibireme.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "UIButton+YYWebImage.h"
#import "YYWebImageOperation.h"
#import "_YYWebImageSetter.h"
#import <objc/runtime.h>

// Dummy class for category
@interface UIButton_YYWebImage : NSObject @end
@implementation UIButton_YYWebImage @end

static inline NSNumber *UIControlStateSingle(UIControlState state) {
    if (state & UIControlStateHighlighted) return @(UIControlStateHighlighted);
    if (state & UIControlStateDisabled) return @(UIControlStateDisabled);
    if (state & UIControlStateSelected) return @(UIControlStateSelected);
    return @(UIControlStateNormal);
}

static inline NSArray *UIControlStateMulti(UIControlState state) {
    NSMutableArray *array = [NSMutableArray new];
    if (state & UIControlStateHighlighted) [array addObject:@(UIControlStateHighlighted)];
    if (state & UIControlStateDisabled) [array addObject:@(UIControlStateDisabled)];
    if (state & UIControlStateSelected) [array addObject:@(UIControlStateSelected)];
    if ((state & 0xFF) == 0) [array addObject:@(UIControlStateNormal)];
    return array;
}

static int _YYWebImageSetterKey;
static int _YYWebImageBackgroundSetterKey;


@interface _YYWebImageSetterDicForButton : NSObject
- (_YYWebImageSetter *)setterForState:(NSNumber *)state;
- (_YYWebImageSetter *)lazySetterForState:(NSNumber *)state;
@end

@implementation _YYWebImageSetterDicForButton {
    NSMutableDictionary *_dic;
    dispatch_semaphore_t _lock;
}
- (instancetype)init {
    self = [super init];
    _lock = dispatch_semaphore_create(1);
    _dic = [NSMutableDictionary new];
    return self;
}
- (_YYWebImageSetter *)setterForState:(NSNumber *)state {
    dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER);
    _YYWebImageSetter *setter = _dic[state];
    dispatch_semaphore_signal(_lock);
    return setter;
    
}
- (_YYWebImageSetter *)lazySetterForState:(NSNumber *)state {
    dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER);
    _YYWebImageSetter *setter = _dic[state];
    if (!setter) {
        setter = [_YYWebImageSetter new];
        _dic[state] = setter;
    }
    dispatch_semaphore_signal(_lock);
    return setter;
}
@end


@implementation UIButton (YYWebImage)

#pragma mark - image

- (void)_yy_setImageWithURL:(NSURL *)imageURL
             forSingleState:(NSNumber *)state
                placeholder:(UIImage *)placeholder
                    options:(YYWebImageOptions)options
                 itemOption:(YYWebImageItemOption *)itemOption
                    manager:(YYWebImageManager *)manager
                   progress:(YYWebImageProgressBlock)progress
                  transform:(YYWebImageTransformBlock)transform
                 completion:(YYWebImageCompletionBlock)completion {
    if ([imageURL isKindOfClass:[NSString class]]) imageURL = [NSURL URLWithString:(id)imageURL];
    manager = manager ? manager : [YYWebImageManager sharedManager];
    
    _YYWebImageSetterDicForButton *dic = objc_getAssociatedObject(self, &_YYWebImageSetterKey);
    if (!dic) {
        dic = [_YYWebImageSetterDicForButton new];
        objc_setAssociatedObject(self, &_YYWebImageSetterKey, dic, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    _YYWebImageSetter *setter = [dic lazySetterForState:state];
    int32_t sentinel = [setter cancelWithNewURL:imageURL];
    
    _yy_dispatch_sync_on_main_queue(^{
        if (!imageURL) {
            if (!(options & YYWebImageOptionIgnorePlaceHolder)) {
                [self setImage:placeholder forState:state.integerValue];
            }
            return;
        }
        
        YYWebImageItemOption *_itemOption = itemOption;
        if (!_itemOption) {
            _itemOption = [[YYWebImageItemOption alloc] init];
        }
        
        [setter setItemOption:_itemOption];
        
        // get the image from memory as quickly as possible
        UIImage *imageFromMemory = nil;
        if (manager.cache &&
            !(options & YYWebImageOptionUseNSURLCache) &&
            !(options & YYWebImageOptionRefreshImageCache)) {
            // if transform is not nil then temporary set kYYWebImageOptionBeTransformed to YES try to hit memory cache
            if (transform) {
                _itemOption.beTransformed = YES;
            }
            
            // if processor is not nil then temporary set kYYWebImageOptionBeProcessed to YES try to hit memory cache
            if (manager.processor) {
                _itemOption.beProcessed = YES;
            }
            
            NSString *originalCacheKey = [manager cacheKeyForURL:imageURL];
            
            if (manager.processor) {
                _itemOption.processorIdentifier = manager.processor.identifier;
            }
            
            // try key mode: URL_widthPixel_x_heightPixel_[YYWebImageProcessor`s identifier]_[transform`s identifier]
            NSString *memoryCacheKey = [_itemOption cacheKeyForMemoryCache:originalCacheKey];
            imageFromMemory = [manager.cache getImageForKey:memoryCacheKey withType:YYImageCacheTypeMemory];
            
            // try key mode: URL_widthPixel_x_heightPixel_[transform`s identifier]
            if (!imageFromMemory) {
                _itemOption.beProcessed = NO;
                memoryCacheKey = [_itemOption cacheKeyForMemoryCache:originalCacheKey];
                imageFromMemory = [manager.cache getImageForKey:memoryCacheKey withType:YYImageCacheTypeMemory];
            }
            
            // try key mode: URL
            if (!imageFromMemory && (!transform || (options & YYWebImageOptionAllowHitMemoryByDiskKeyWithValidTransform))) {
                NSString *diskCacheKey = [_itemOption cacheKeyForDiskCache:originalCacheKey];
                if (![memoryCacheKey isEqualToString:diskCacheKey]) {
                    imageFromMemory = [manager.cache getImageForKey:diskCacheKey withType:YYImageCacheTypeMemory];
                }
            }
        }
        if (imageFromMemory) {
            if (!(options & YYWebImageOptionAvoidSetImage)) {
                [self setImage:imageFromMemory forState:state.integerValue];
            }
            if(completion) completion(imageFromMemory, imageURL, YYWebImageFromMemoryCacheFast, YYWebImageStageFinished, nil);
            return;
        }
        
        
        if (!(options & YYWebImageOptionIgnorePlaceHolder)) {
            [self setImage:placeholder forState:state.integerValue];
        }
        
        _itemOption.beProcessed = NO;
        _itemOption.beTransformed = NO;
        
        __weak typeof(self) _self = self;
        dispatch_async([_YYWebImageSetter setterQueue], ^{
            YYWebImageProgressBlock _progress = nil;
            if (progress) _progress = ^(NSInteger receivedSize, NSInteger expectedSize) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    progress(receivedSize, expectedSize);
                });
            };
            
            __block int32_t newSentinel = 0;
            __block __weak typeof(setter) weakSetter = nil;
            YYWebImageCompletionBlock _completion = ^(UIImage *image, NSURL *url, YYWebImageFromType from, YYWebImageStage stage, NSError *error) {
                __strong typeof(_self) self = _self;
                BOOL setImage = (stage == YYWebImageStageFinished || stage == YYWebImageStageProgress) && image && !(options & YYWebImageOptionAvoidSetImage);
                dispatch_async(dispatch_get_main_queue(), ^{
                    BOOL sentinelChanged = weakSetter && weakSetter.sentinel != newSentinel;
                    if (setImage && self && !sentinelChanged) {
                        [self setImage:image forState:state.integerValue];
                    }
                    if (completion) {
                        if (sentinelChanged) {
                            completion(nil, url, YYWebImageFromNone, YYWebImageStageCancelled, nil);
                        } else {
                            completion(image, url, from, stage, error);
                        }
                    }
                });
            };
            
            newSentinel = [setter setOperationWithSentinel:sentinel url:imageURL options:options itemOption:_itemOption manager:manager progress:_progress transform:transform completion:_completion];
            weakSetter = setter;
        });
    });
}

- (void)_yy_cancelImageRequestForSingleState:(NSNumber *)state {
    _YYWebImageSetterDicForButton *dic = objc_getAssociatedObject(self, &_YYWebImageSetterKey);
    _YYWebImageSetter *setter = [dic setterForState:state];
    if (setter) [setter cancel];
}

- (NSURL *)yy_imageURLForState:(UIControlState)state {
    _YYWebImageSetterDicForButton *dic = objc_getAssociatedObject(self, &_YYWebImageSetterKey);
    _YYWebImageSetter *setter = [dic setterForState:UIControlStateSingle(state)];
    return setter.imageURL;
}

- (NSString *)yy_imageMemoryCacheKeyForState:(UIControlState)state {
    _YYWebImageSetterDicForButton *dic = objc_getAssociatedObject(self, &_YYWebImageSetterKey);
    _YYWebImageSetter *setter = [dic setterForState:UIControlStateSingle(state)];
    YYWebImageItemOption *itemOption = setter.itemOption;
    if (itemOption && setter.imageURL) {
        NSString *cacheKey = setter.imageURL.absoluteString;
        return [itemOption cacheKeyForMemoryCache:cacheKey];
    }
    return nil;
}

- (NSString *)yy_imageDiskCacheKeyForState:(UIControlState)state {
    _YYWebImageSetterDicForButton *dic = objc_getAssociatedObject(self, &_YYWebImageSetterKey);
    _YYWebImageSetter *setter = [dic setterForState:UIControlStateSingle(state)];
    YYWebImageItemOption *itemOption = setter.itemOption;
    if (itemOption && setter.imageURL) {
        NSString *cacheKey = setter.imageURL.absoluteString;
        return [itemOption cacheKeyForDiskCache:cacheKey];
    }
    return nil;
}

- (void)yy_setImageWithURL:(NSURL *)imageURL
                  forState:(UIControlState)state
               placeholder:(UIImage *)placeholder
                itemOption:(YYWebImageItemOption *)itemOption {
    [self yy_setImageWithURL:imageURL
                 forState:state
              placeholder:placeholder
                  options:kNilOptions
               itemOption:itemOption
                  manager:nil
                 progress:nil
                transform:nil
               completion:nil];
}

- (void)yy_setImageWithURL:(NSURL *)imageURL
                  forState:(UIControlState)state
                   options:(YYWebImageOptions)options
                itemOption:(YYWebImageItemOption *)itemOption {
    [self yy_setImageWithURL:imageURL
                    forState:state
                 placeholder:nil
                     options:options
                  itemOption:itemOption
                     manager:nil
                    progress:nil
                   transform:nil
                  completion:nil];
}

- (void)yy_setImageWithURL:(NSURL *)imageURL
                  forState:(UIControlState)state
               placeholder:(UIImage *)placeholder
                   options:(YYWebImageOptions)options
                itemOption:(YYWebImageItemOption *)itemOption
                completion:(YYWebImageCompletionBlock)completion {
    [self yy_setImageWithURL:imageURL
                    forState:state
                 placeholder:placeholder
                     options:options
                  itemOption:itemOption
                     manager:nil
                    progress:nil
                   transform:nil
                  completion:completion];
}

- (void)yy_setImageWithURL:(NSURL *)imageURL
                  forState:(UIControlState)state
               placeholder:(UIImage *)placeholder
                   options:(YYWebImageOptions)options
                itemOption:(YYWebImageItemOption *)itemOption
                  progress:(YYWebImageProgressBlock)progress
                 transform:(YYWebImageTransformBlock)transform
                completion:(YYWebImageCompletionBlock)completion {
    [self yy_setImageWithURL:imageURL
                    forState:state
                 placeholder:placeholder
                     options:options
                  itemOption:itemOption
                     manager:nil
                    progress:progress
                   transform:transform
                  completion:completion];
}

- (void)yy_setImageWithURL:(NSURL *)imageURL
                  forState:(UIControlState)state
               placeholder:(UIImage *)placeholder
                   options:(YYWebImageOptions)options
                itemOption:(YYWebImageItemOption *)itemOption
                   manager:(YYWebImageManager *)manager
                  progress:(YYWebImageProgressBlock)progress
                 transform:(YYWebImageTransformBlock)transform
                completion:(YYWebImageCompletionBlock)completion {
    for (NSNumber *num in UIControlStateMulti(state)) {
        [self _yy_setImageWithURL:imageURL
                   forSingleState:num
                      placeholder:placeholder
                          options:options
                       itemOption:itemOption
                          manager:manager
                         progress:progress
                        transform:transform
                       completion:completion];
    }
}

- (void)yy_cancelImageRequestForState:(UIControlState)state {
    for (NSNumber *num in UIControlStateMulti(state)) {
        [self _yy_cancelImageRequestForSingleState:num];
    }
}


#pragma mark - background image

- (void)_yy_setBackgroundImageWithURL:(NSURL *)imageURL
                       forSingleState:(NSNumber *)state
                          placeholder:(UIImage *)placeholder
                              options:(YYWebImageOptions)options
                           itemOption:(YYWebImageItemOption *)itemOption
                              manager:(YYWebImageManager *)manager
                             progress:(YYWebImageProgressBlock)progress
                            transform:(YYWebImageTransformBlock)transform
                           completion:(YYWebImageCompletionBlock)completion {
    if ([imageURL isKindOfClass:[NSString class]]) imageURL = [NSURL URLWithString:(id)imageURL];
    manager = manager ? manager : [YYWebImageManager sharedManager];
    
    _YYWebImageSetterDicForButton *dic = objc_getAssociatedObject(self, &_YYWebImageBackgroundSetterKey);
    if (!dic) {
        dic = [_YYWebImageSetterDicForButton new];
        objc_setAssociatedObject(self, &_YYWebImageBackgroundSetterKey, dic, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    _YYWebImageSetter *setter = [dic lazySetterForState:state];
    int32_t sentinel = [setter cancelWithNewURL:imageURL];
    
    _yy_dispatch_sync_on_main_queue(^{
        if (!imageURL) {
            if (!(options & YYWebImageOptionIgnorePlaceHolder)) {
                [self setBackgroundImage:placeholder forState:state.integerValue];
            }
            return;
        }
        
        YYWebImageItemOption *_itemOption = itemOption;
        if (!_itemOption) {
            _itemOption = [[YYWebImageItemOption alloc] init];
        }
        
        [setter setItemOption:_itemOption];
        
        // get the image from memory as quickly as possible
        UIImage *imageFromMemory = nil;
        if (manager.cache &&
            !(options & YYWebImageOptionUseNSURLCache) &&
            !(options & YYWebImageOptionRefreshImageCache)) {
            // if transform is not nil then temporary set kYYWebImageOptionBeTransformed to YES try to hit memory cache
            if (transform) {
                _itemOption.beTransformed = YES;
            }
            
            // if processor is not nil then temporary set kYYWebImageOptionBeProcessed to YES try to hit memory cache
            if (manager.processor) {
                _itemOption.beProcessed = YES;
            }
            
            NSString *originalCacheKey = [manager cacheKeyForURL:imageURL];
            
            if (manager.processor) {
                _itemOption.processorIdentifier = manager.processor.identifier;
            }
            
            // try key mode: URL_widthPixel_x_heightPixel_[YYWebImageProcessor`s identifier]_[transform`s identifier]
            NSString *memoryCacheKey = [_itemOption cacheKeyForMemoryCache:originalCacheKey];
            imageFromMemory = [manager.cache getImageForKey:memoryCacheKey withType:YYImageCacheTypeMemory];
            
            // try key mode: URL_widthPixel_x_heightPixel_[transform`s identifier]
            if (!imageFromMemory) {
                _itemOption.beProcessed = NO;
                memoryCacheKey = [_itemOption cacheKeyForMemoryCache:originalCacheKey];
                imageFromMemory = [manager.cache getImageForKey:memoryCacheKey withType:YYImageCacheTypeMemory];
            }
            
            // try key mode: URL
            if (!imageFromMemory && (!transform || (options & YYWebImageOptionAllowHitMemoryByDiskKeyWithValidTransform))) {
                NSString *diskCacheKey = [_itemOption cacheKeyForDiskCache:originalCacheKey];
                if (![memoryCacheKey isEqualToString:diskCacheKey]) {
                    imageFromMemory = [manager.cache getImageForKey:diskCacheKey withType:YYImageCacheTypeMemory];
                }
            }
        }
        if (imageFromMemory) {
            if (!(options & YYWebImageOptionAvoidSetImage)) {
                [self setBackgroundImage:imageFromMemory forState:state.integerValue];
            }
            if(completion) completion(imageFromMemory, imageURL, YYWebImageFromMemoryCacheFast, YYWebImageStageFinished, nil);
            return;
        }
        
        
        if (!(options & YYWebImageOptionIgnorePlaceHolder)) {
            [self setBackgroundImage:placeholder forState:state.integerValue];
        }
        
        _itemOption.beProcessed = NO;
        _itemOption.beTransformed = NO;
        
        __weak typeof(self) _self = self;
        dispatch_async([_YYWebImageSetter setterQueue], ^{
            YYWebImageProgressBlock _progress = nil;
            if (progress) _progress = ^(NSInteger receivedSize, NSInteger expectedSize) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    progress(receivedSize, expectedSize);
                });
            };
            
            __block int32_t newSentinel = 0;
            __block __weak typeof(setter) weakSetter = nil;
            YYWebImageCompletionBlock _completion = ^(UIImage *image, NSURL *url, YYWebImageFromType from, YYWebImageStage stage, NSError *error) {
                __strong typeof(_self) self = _self;
                BOOL setImage = (stage == YYWebImageStageFinished || stage == YYWebImageStageProgress) && image && !(options & YYWebImageOptionAvoidSetImage);
                dispatch_async(dispatch_get_main_queue(), ^{
                    BOOL sentinelChanged = weakSetter && weakSetter.sentinel != newSentinel;
                    if (setImage && self && !sentinelChanged) {
                        [self setBackgroundImage:image forState:state.integerValue];
                    }
                    if (completion) {
                        if (sentinelChanged) {
                            completion(nil, url, YYWebImageFromNone, YYWebImageStageCancelled, nil);
                        } else {
                            completion(image, url, from, stage, error);
                        }
                    }
                });
            };
            
            newSentinel = [setter setOperationWithSentinel:sentinel url:imageURL options:options itemOption:_itemOption manager:manager progress:_progress transform:transform completion:_completion];
            weakSetter = setter;
        });
    });
}

- (void)_yy_cancelBackgroundImageRequestForSingleState:(NSNumber *)state {
    _YYWebImageSetterDicForButton *dic = objc_getAssociatedObject(self, &_YYWebImageBackgroundSetterKey);
    _YYWebImageSetter *setter = [dic setterForState:state];
    if (setter) [setter cancel];
}

- (NSURL *)yy_backgroundImageURLForState:(UIControlState)state {
    _YYWebImageSetterDicForButton *dic = objc_getAssociatedObject(self, &_YYWebImageBackgroundSetterKey);
    _YYWebImageSetter *setter = [dic setterForState:UIControlStateSingle(state)];
    return setter.imageURL;
}

- (void)yy_setBackgroundImageWithURL:(NSURL *)imageURL
                            forState:(UIControlState)state
                         placeholder:(UIImage *)placeholder
                          itemOption:(YYWebImageItemOption *)itemOption {
    [self yy_setBackgroundImageWithURL:imageURL
                              forState:state
                           placeholder:placeholder
                               options:kNilOptions
                            itemOption:itemOption
                               manager:nil
                              progress:nil
                             transform:nil
                            completion:nil];
}

- (void)yy_setBackgroundImageWithURL:(NSURL *)imageURL
                            forState:(UIControlState)state
                             options:(YYWebImageOptions)options
                          itemOption:(YYWebImageItemOption *)itemOption {
    [self yy_setBackgroundImageWithURL:imageURL
                              forState:state
                           placeholder:nil
                               options:options
                            itemOption:itemOption
                               manager:nil
                              progress:nil
                             transform:nil
                            completion:nil];
}

- (void)yy_setBackgroundImageWithURL:(NSURL *)imageURL
                            forState:(UIControlState)state
                         placeholder:(UIImage *)placeholder
                             options:(YYWebImageOptions)options
                          itemOption:(YYWebImageItemOption *)itemOption
                          completion:(YYWebImageCompletionBlock)completion {
    [self yy_setBackgroundImageWithURL:imageURL
                              forState:state
                           placeholder:placeholder
                               options:options
                            itemOption:itemOption
                               manager:nil
                              progress:nil
                             transform:nil
                            completion:completion];
}

- (void)yy_setBackgroundImageWithURL:(NSURL *)imageURL
                            forState:(UIControlState)state
                         placeholder:(UIImage *)placeholder
                             options:(YYWebImageOptions)options
                          itemOption:(YYWebImageItemOption *)itemOption
                            progress:(YYWebImageProgressBlock)progress
                           transform:(YYWebImageTransformBlock)transform
                          completion:(YYWebImageCompletionBlock)completion {
    [self yy_setBackgroundImageWithURL:imageURL
                              forState:state
                           placeholder:placeholder
                               options:options
                            itemOption:itemOption
                               manager:nil
                              progress:progress
                             transform:transform
                            completion:completion];
}

- (void)yy_setBackgroundImageWithURL:(NSURL *)imageURL
                            forState:(UIControlState)state
                         placeholder:(UIImage *)placeholder
                             options:(YYWebImageOptions)options
                          itemOption:(YYWebImageItemOption *)itemOption
                             manager:(YYWebImageManager *)manager
                            progress:(YYWebImageProgressBlock)progress
                           transform:(YYWebImageTransformBlock)transform
                          completion:(YYWebImageCompletionBlock)completion {
    for (NSNumber *num in UIControlStateMulti(state)) {
        [self _yy_setBackgroundImageWithURL:imageURL
                             forSingleState:num
                                placeholder:placeholder
                                    options:options
                                 itemOption:itemOption
                                    manager:manager
                                   progress:progress
                                  transform:transform
                                 completion:completion];
    }
}

- (void)yy_cancelBackgroundImageRequestForState:(UIControlState)state {
    for (NSNumber *num in UIControlStateMulti(state)) {
        [self _yy_cancelBackgroundImageRequestForSingleState:num];
    }
}

- (void)yy_removeAllCacheForState:(UIControlState)state {
    [self yy_removeMemoryCache:state];
    [self yy_removeDiskCache:state];
}

- (void)yy_removeMemoryCache:(UIControlState)state {
    [self yy_removeCache:YYImageCacheTypeMemory forState:state];
}

- (void)yy_removeDiskCache:(UIControlState)state {
    [self yy_removeCache:YYImageCacheTypeDisk forState:state];
}

- (void)yy_removeCache:(YYImageCacheType)cacheType forState:(UIControlState)state {
    if (cacheType & YYImageCacheTypeMemory) {
        NSString *memoryCacheKey = [self yy_imageMemoryCacheKeyForState:state];
        if (YYWebImageManager.sharedManager.cache && memoryCacheKey) {
            [YYWebImageManager.sharedManager.cache removeImageForKey:memoryCacheKey withType:YYImageCacheTypeMemory];
        }
    }
    
    if (cacheType & YYImageCacheTypeDisk) {
        NSString *diskCacheKey = [self yy_imageDiskCacheKeyForState:state];
        if (YYWebImageManager.sharedManager.cache && diskCacheKey) {
            [YYWebImageManager.sharedManager.cache removeImageForKey:diskCacheKey withType:YYImageCacheTypeDisk];
        }
    }
}

@end
