//
//  UIImageView+YYWebImage.m
//  YYWebImage <https://github.com/ibireme/YYWebImage>
//
//  Created by ibireme on 15/2/23.
//  Copyright (c) 2015 ibireme.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "UIImageView+YYWebImage.h"
#import "YYWebImageOperation.h"
#import "_YYWebImageSetter.h"
#import <objc/runtime.h>

// Dummy class for category
@interface UIImageView_YYWebImage : NSObject @end
@implementation UIImageView_YYWebImage @end

static int _YYWebImageSetterKey;
static int _YYWebImageHighlightedSetterKey;


@implementation UIImageView (YYWebImage)

#pragma mark - image

- (NSURL *)yy_imageURL {
    _YYWebImageSetter *setter = objc_getAssociatedObject(self, &_YYWebImageSetterKey);
    return setter.imageURL;
}

- (NSString *)yy_memoryCacheKey {
    _YYWebImageSetter *setter = objc_getAssociatedObject(self, &_YYWebImageSetterKey);
    YYWebImageItemOption *itemOption = setter.itemOption;
    if (itemOption && setter.imageURL) {
        NSString *cacheKey = setter.imageURL.absoluteString;
        return [itemOption cacheKeyForMemoryCache:cacheKey];
    }
    return nil;
}

- (NSString *)yy_diskCacheKey {
    _YYWebImageSetter *setter = objc_getAssociatedObject(self, &_YYWebImageSetterKey);
    YYWebImageItemOption *itemOption = setter.itemOption;
    if (itemOption && setter.imageURL) {
        NSString *cacheKey = setter.imageURL.absoluteString;
        return [itemOption cacheKeyForDiskCache:cacheKey];
    }
    return nil;
}

- (void)setYy_imageURL:(NSURL *)imageURL {
    [self yy_setImageWithURL:imageURL
                 placeholder:nil
                     options:kNilOptions
                  itemOption:nil
                     manager:nil
                    progress:nil
                   transform:nil
                  completion:nil];
}

- (void)yy_setImageWithURL:(NSURL *)imageURL
               placeholder:(UIImage *)placeholder {
    [self yy_setImageWithURL:imageURL
                 placeholder:placeholder
                  targetSize:self.frame.size];
}

- (void)yy_setImageWithURL:(NSURL *)imageURL
                   options:(YYWebImageOptions)options {
    [self yy_setImageWithURL:imageURL
                     options:options
                  targetSize:self.frame.size];
}

- (void)yy_setImageWithURL:(NSURL *)imageURL
               placeholder:(UIImage *)placeholder
                targetSize:(CGSize)targetSize {
    YYWebImageItemOption *itemOption = [YYWebImageItemOption new];
    itemOption.targetSize = targetSize;
    [self yy_setImageWithURL:imageURL
                 placeholder:placeholder
                  itemOption:itemOption];
}

- (void)yy_setImageWithURL:(NSURL *)imageURL
               placeholder:(UIImage *)placeholder
                itemOption:(YYWebImageItemOption *)itemOption {
    [self yy_setImageWithURL:imageURL
                 placeholder:placeholder
                     options:kNilOptions
                  itemOption:itemOption
                     manager:nil
                    progress:nil
                   transform:nil
                  completion:nil];
}

- (void)yy_setImageWithURL:(NSURL *)imageURL
                   options:(YYWebImageOptions)options
                targetSize:(CGSize)targetSize {
    YYWebImageItemOption *itemOption = [YYWebImageItemOption new];
    itemOption.targetSize = targetSize;
    [self yy_setImageWithURL:imageURL
                     options:options
                  itemOption:itemOption];
}

- (void)yy_setImageWithURL:(NSURL *)imageURL
                   options:(YYWebImageOptions)options
                itemOption:(YYWebImageItemOption *)itemOption {
    [self yy_setImageWithURL:imageURL
                 placeholder:nil
                     options:options
                  itemOption:itemOption
                     manager:nil
                    progress:nil
                   transform:nil
                  completion:nil];
}

- (void)yy_setImageWithURL:(nullable NSURL *)imageURL
               placeholder:(nullable UIImage *)placeholder
                   options:(YYWebImageOptions)options
                completion:(nullable YYWebImageCompletionBlock)completion {
    
    [self yy_setImageWithURL:imageURL
                 placeholder:placeholder
                     options:options
                  targetSize:self.frame.size
                  completion:completion];
}

- (void)yy_setImageWithURL:(nullable NSURL *)imageURL
               placeholder:(nullable UIImage *)placeholder
                   options:(YYWebImageOptions)options
                targetSize:(CGSize)targetSize
                completion:(nullable YYWebImageCompletionBlock)completion {
    YYWebImageItemOption *itemOption = [YYWebImageItemOption new];
    itemOption.targetSize = targetSize;
    [self yy_setImageWithURL:imageURL
                 placeholder:placeholder
                     options:options
                  itemOption:itemOption
                  completion:completion];
}

- (void)yy_setImageWithURL:(NSURL *)imageURL
               placeholder:(UIImage *)placeholder
                   options:(YYWebImageOptions)options
                itemOption:(YYWebImageItemOption *)itemOption
                completion:(YYWebImageCompletionBlock)completion {
    [self yy_setImageWithURL:imageURL
                 placeholder:placeholder
                     options:options
                  itemOption:itemOption
                     manager:nil
                    progress:nil
                   transform:nil
                  completion:completion];
}

- (void)yy_setImageWithURL:(nullable NSURL *)imageURL
               placeholder:(nullable UIImage *)placeholder
                   options:(YYWebImageOptions)options
                targetSize:(CGSize)targetSize
                  progress:(nullable YYWebImageProgressBlock)progress
                 transform:(nullable YYWebImageTransformBlock)transform
                completion:(nullable YYWebImageCompletionBlock)completion {
    YYWebImageItemOption *itemOption = [YYWebImageItemOption new];
    itemOption.targetSize = targetSize;
    [self yy_setImageWithURL:imageURL
                 placeholder:placeholder
                     options:options
                  itemOption:itemOption
                    progress:progress
                   transform:transform
                  completion:completion];
}

- (void)yy_setImageWithURL:(NSURL *)imageURL
               placeholder:(UIImage *)placeholder
                   options:(YYWebImageOptions)options
                itemOption:(YYWebImageItemOption *)itemOption
                  progress:(YYWebImageProgressBlock)progress
                 transform:(YYWebImageTransformBlock)transform
                completion:(YYWebImageCompletionBlock)completion {
    [self yy_setImageWithURL:imageURL
                 placeholder:placeholder
                     options:options
                  itemOption:itemOption
                     manager:nil
                    progress:progress
                   transform:transform
                  completion:completion];
}

- (void)yy_setImageWithURL:(NSURL *)imageURL
               placeholder:(UIImage *)placeholder
                   options:(YYWebImageOptions)options
                itemOption:(YYWebImageItemOption *)itemOption
                   manager:(YYWebImageManager *)manager
                  progress:(YYWebImageProgressBlock)progress
                 transform:(YYWebImageTransformBlock)transform
                completion:(YYWebImageCompletionBlock)completion {
    if ([imageURL isKindOfClass:[NSString class]]) imageURL = [NSURL URLWithString:(id)imageURL];
    manager = manager ? manager : [YYWebImageManager sharedManager];
    
    _YYWebImageSetter *setter = objc_getAssociatedObject(self, &_YYWebImageSetterKey);
    if (!setter) {
        setter = [_YYWebImageSetter new];
        objc_setAssociatedObject(self, &_YYWebImageSetterKey, setter, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    int32_t sentinel = [setter cancelWithNewURL:imageURL];
    
    _yy_dispatch_sync_on_main_queue(^{
        if ((options & YYWebImageOptionSetImageWithFadeAnimation) &&
            !(options & YYWebImageOptionAvoidSetImage)) {
            if (!self.highlighted) {
                [self.layer removeAnimationForKey:_YYWebImageFadeAnimationKey];
            }
        }
        
        if (!imageURL) {
            if (!(options & YYWebImageOptionIgnorePlaceHolder)) {
                self.image = placeholder;
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
                self.image = imageFromMemory;
            }
            if(completion) completion(imageFromMemory, imageURL, YYWebImageFromMemoryCacheFast, YYWebImageStageFinished, nil);
            return;
        }
        
        if (!(options & YYWebImageOptionIgnorePlaceHolder)) {
            self.image = placeholder;
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
                        BOOL showFade = ((options & YYWebImageOptionSetImageWithFadeAnimation) && !self.highlighted);
                        if (showFade) {
                            CATransition *transition = [CATransition animation];
                            transition.duration = stage == YYWebImageStageFinished ? _YYWebImageFadeTime : _YYWebImageProgressiveFadeTime;
                            transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
                            transition.type = kCATransitionFade;
                            [self.layer addAnimation:transition forKey:_YYWebImageFadeAnimationKey];
                        }
                        self.image = image;
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

- (void)yy_cancelCurrentImageRequest {
    _YYWebImageSetter *setter = objc_getAssociatedObject(self, &_YYWebImageSetterKey);
    if (setter) [setter cancel];
}

- (void)yy_removeAllCache {
    [self yy_removeMemoryCache];
    [self yy_removeDiskCache];
}

- (void)yy_removeMemoryCache {
    [self yy_removeCache:YYImageCacheTypeMemory];
}

- (void)yy_removeDiskCache {
    [self yy_removeCache:YYImageCacheTypeDisk];
}

- (void)yy_removeCache:(YYImageCacheType)cacheType {
    if (cacheType & YYImageCacheTypeMemory) {
        NSString *memoryCacheKey = self.yy_memoryCacheKey;
        if (YYWebImageManager.sharedManager.cache && memoryCacheKey) {
            [YYWebImageManager.sharedManager.cache removeImageForKey:memoryCacheKey withType:YYImageCacheTypeMemory];
        }
    }
    
    if (cacheType & YYImageCacheTypeDisk) {
        NSString *diskCacheKey = self.yy_diskCacheKey;
        if (YYWebImageManager.sharedManager.cache && diskCacheKey) {
            [YYWebImageManager.sharedManager.cache removeImageForKey:diskCacheKey withType:YYImageCacheTypeDisk];
        }
    }
}

#pragma mark - highlighted image

- (NSURL *)yy_highlightedImageURL {
    _YYWebImageSetter *setter = objc_getAssociatedObject(self, &_YYWebImageHighlightedSetterKey);
    return setter.imageURL;
}

- (NSString *)yy_highlightedMemoryCacheKey {
    _YYWebImageSetter *setter = objc_getAssociatedObject(self, &_YYWebImageHighlightedSetterKey);
    YYWebImageItemOption *itemOption = setter.itemOption;
    if (itemOption && setter.imageURL) {
        NSString *cacheKey = setter.imageURL.absoluteString;
        return [itemOption cacheKeyForMemoryCache:cacheKey];
    }
    return nil;
}

- (NSString *)yy_highlightedDiskCacheKey {
    _YYWebImageSetter *setter = objc_getAssociatedObject(self, &_YYWebImageHighlightedSetterKey);
    YYWebImageItemOption *itemOption = setter.itemOption;
    if (itemOption && setter.imageURL) {
        NSString *cacheKey = setter.imageURL.absoluteString;
        return [itemOption cacheKeyForDiskCache:cacheKey];
    }
    return nil;
}

- (void)setYy_highlightedImageURL:(NSURL *)imageURL {
    [self yy_setHighlightedImageWithURL:imageURL
                            placeholder:nil
                                options:kNilOptions
                             itemOption:nil
                                manager:nil
                               progress:nil
                              transform:nil
                             completion:nil];
}

- (void)yy_setHighlightedImageWithURL:(NSURL *)imageURL
                          placeholder:(UIImage *)placeholder
                           itemOption:(YYWebImageItemOption *)itemOption {
    [self yy_setHighlightedImageWithURL:imageURL
                            placeholder:placeholder
                                options:kNilOptions
                             itemOption:itemOption
                                manager:nil
                               progress:nil
                              transform:nil
                             completion:nil];
}

- (void)yy_setHighlightedImageWithURL:(NSURL *)imageURL
                              options:(YYWebImageOptions)options
                           itemOption:(YYWebImageItemOption *)itemOption {
    [self yy_setHighlightedImageWithURL:imageURL
                            placeholder:nil
                                options:options
                             itemOption:itemOption
                                manager:nil
                               progress:nil
                              transform:nil
                             completion:nil];
}

- (void)yy_setHighlightedImageWithURL:(NSURL *)imageURL
                          placeholder:(UIImage *)placeholder
                              options:(YYWebImageOptions)options
                           itemOption:(YYWebImageItemOption *)itemOption
                           completion:(YYWebImageCompletionBlock)completion {
    [self yy_setHighlightedImageWithURL:imageURL
                            placeholder:placeholder
                                options:options
                             itemOption:itemOption
                                manager:nil
                               progress:nil
                              transform:nil
                             completion:completion];
}

- (void)yy_setHighlightedImageWithURL:(NSURL *)imageURL
                          placeholder:(UIImage *)placeholder
                              options:(YYWebImageOptions)options
                           itemOption:(YYWebImageItemOption *)itemOption
                             progress:(YYWebImageProgressBlock)progress
                            transform:(YYWebImageTransformBlock)transform
                           completion:(YYWebImageCompletionBlock)completion {
    [self yy_setHighlightedImageWithURL:imageURL
                            placeholder:placeholder
                                options:options
                             itemOption:itemOption
                                manager:nil
                               progress:progress
                              transform:nil
                             completion:completion];
}

- (void)yy_setHighlightedImageWithURL:(NSURL *)imageURL
                          placeholder:(UIImage *)placeholder
                              options:(YYWebImageOptions)options
                           itemOption:(YYWebImageItemOption *)itemOption
                              manager:(YYWebImageManager *)manager
                             progress:(YYWebImageProgressBlock)progress
                            transform:(YYWebImageTransformBlock)transform
                           completion:(YYWebImageCompletionBlock)completion {
    if ([imageURL isKindOfClass:[NSString class]]) imageURL = [NSURL URLWithString:(id)imageURL];
    manager = manager ? manager : [YYWebImageManager sharedManager];
    
    _YYWebImageSetter *setter = objc_getAssociatedObject(self, &_YYWebImageHighlightedSetterKey);
    if (!setter) {
        setter = [_YYWebImageSetter new];
        objc_setAssociatedObject(self, &_YYWebImageHighlightedSetterKey, setter, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    int32_t sentinel = [setter cancelWithNewURL:imageURL];
    
    _yy_dispatch_sync_on_main_queue(^{
        if ((options & YYWebImageOptionSetImageWithFadeAnimation) &&
            !(options & YYWebImageOptionAvoidSetImage)) {
            if (self.highlighted) {
                [self.layer removeAnimationForKey:_YYWebImageFadeAnimationKey];
            }
        }
        if (!imageURL) {
            if (!(options & YYWebImageOptionIgnorePlaceHolder)) {
                self.highlightedImage = placeholder;
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
                self.highlightedImage = imageFromMemory;
            }
            if(completion) completion(imageFromMemory, imageURL, YYWebImageFromMemoryCacheFast, YYWebImageStageFinished, nil);
            return;
        }
        
        if (!(options & YYWebImageOptionIgnorePlaceHolder)) {
            self.highlightedImage = placeholder;
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
                BOOL showFade = ((options & YYWebImageOptionSetImageWithFadeAnimation) && self.highlighted);
                dispatch_async(dispatch_get_main_queue(), ^{
                    BOOL sentinelChanged = weakSetter && weakSetter.sentinel != newSentinel;
                    if (setImage && self && !sentinelChanged) {
                        if (showFade) {
                            CATransition *transition = [CATransition animation];
                            transition.duration = stage == YYWebImageStageFinished ? _YYWebImageFadeTime : _YYWebImageProgressiveFadeTime;
                            transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
                            transition.type = kCATransitionFade;
                            [self.layer addAnimation:transition forKey:_YYWebImageFadeAnimationKey];
                        }
                        self.highlightedImage = image;
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

- (void)yy_cancelCurrentHighlightedImageRequest {
    _YYWebImageSetter *setter = objc_getAssociatedObject(self, &_YYWebImageHighlightedSetterKey);
    if (setter) [setter cancel];
}

- (void)yy_removeAllHighlightedCache {
    [self yy_removeHighlightedMemoryCache];
    [self yy_removeHighlightedDiskCache];
}

- (void)yy_removeHighlightedMemoryCache {
    [self yy_removeCache:YYImageCacheTypeMemory];
}

- (void)yy_removeHighlightedDiskCache {
    [self yy_removeCache:YYImageCacheTypeDisk];
}

- (void)yy_removeHighlightedCache:(YYImageCacheType)cacheType {
    if (cacheType & YYImageCacheTypeMemory) {
        NSString *highlightedMemoryCacheKey = self.yy_highlightedMemoryCacheKey;
        if (YYWebImageManager.sharedManager.cache && highlightedMemoryCacheKey) {
            [YYWebImageManager.sharedManager.cache removeImageForKey:highlightedMemoryCacheKey withType:YYImageCacheTypeMemory];
        }
    }
    
    if (cacheType & YYImageCacheTypeDisk) {
        NSString *highlightedDiskCacheKey = self.yy_highlightedDiskCacheKey;
        if (YYWebImageManager.sharedManager.cache && highlightedDiskCacheKey) {
            [YYWebImageManager.sharedManager.cache removeImageForKey:highlightedDiskCacheKey withType:YYImageCacheTypeDisk];
        }
    }
}

@end
