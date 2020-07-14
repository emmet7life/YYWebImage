//
//  CALayer+YYWebImage.m
//  YYWebImage <https://github.com/ibireme/YYWebImage>
//
//  Created by ibireme on 15/2/23.
//  Copyright (c) 2015 ibireme.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "CALayer+YYWebImage.h"
#import "YYWebImageOperation.h"
#import "_YYWebImageSetter.h"
#import <objc/runtime.h>

// Dummy class for category
@interface CALayer_YYWebImage : NSObject @end
@implementation CALayer_YYWebImage @end


static int _YYWebImageSetterKey;

@implementation CALayer (YYWebImage)

- (NSURL *)yy_imageURL {
    _YYWebImageSetter *setter = objc_getAssociatedObject(self, &_YYWebImageSetterKey);
    return setter.imageURL;
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
            [self removeAnimationForKey:_YYWebImageFadeAnimationKey];
        }
        
        if (!imageURL) {
            if (!(options & YYWebImageOptionIgnorePlaceHolder)) {
                self.contents = (id)placeholder.CGImage;
            }
            return;
        }

        YYWebImageItemOption *_itemOption = itemOption;
        if (!_itemOption) {
            _itemOption = [[YYWebImageItemOption alloc] init];
        }
        
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
            
            // try key mode: URL_widthPixel_x_heightPixel_[YYWebImageProcessor`s identifier]_[transform`s identifier]
            NSString *memoryCacheKey = [_itemOption cacheKeyForMemoryCache:originalCacheKey processorIdentifier:manager.processor.identifier];
            imageFromMemory = [manager.cache getImageForKey:memoryCacheKey withType:YYImageCacheTypeMemory];
            
            // try key mode: URL_widthPixel_x_heightPixel_[transform`s identifier]
            if (!imageFromMemory) {
                _itemOption.beProcessed = NO;
                memoryCacheKey = [_itemOption cacheKeyForMemoryCache:originalCacheKey processorIdentifier:manager.processor.identifier];
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
                self.contents = (id)imageFromMemory.CGImage;
            }
            if(completion) completion(imageFromMemory, imageURL, YYWebImageFromMemoryCacheFast, YYWebImageStageFinished, nil);
            return;
        }
        
        if (!(options & YYWebImageOptionIgnorePlaceHolder)) {
            self.contents = (id)placeholder.CGImage;
        }
        
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
                BOOL showFade = (options & YYWebImageOptionSetImageWithFadeAnimation);
                dispatch_async(dispatch_get_main_queue(), ^{
                    BOOL sentinelChanged = weakSetter && weakSetter.sentinel != newSentinel;
                    if (setImage && self && !sentinelChanged) {
                        if (showFade) {
                            CATransition *transition = [CATransition animation];
                            transition.duration = stage == YYWebImageStageFinished ? _YYWebImageFadeTime : _YYWebImageProgressiveFadeTime;
                            transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
                            transition.type = kCATransitionFade;
                            [self addAnimation:transition forKey:_YYWebImageFadeAnimationKey];
                        }
                        self.contents = (id)image.CGImage;
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

@end
