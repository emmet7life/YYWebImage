//
//  MKAnnotationView+YYWebImage.h
//  YYWebImage <https://github.com/ibireme/YYWebImage>
//
//  Created by ibireme on 15/2/23.
//  Copyright (c) 2015 ibireme.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

#if __has_include(<YYWebImage/YYWebImage.h>)
#import <YYWebImage/YYWebImageManager.h>
#else
#import "YYWebImageManager.h"
#endif

NS_ASSUME_NONNULL_BEGIN

/**
 Web image methods for MKAnnotationView.
 */
@interface MKAnnotationView (YYWebImage)

/**
 Current image URL.
 
 @discussion Set a new value to this property will cancel the previous request
 operation and create a new request operation to fetch image. Set nil to clear
 the image and image URL.
 */
@property (nullable, nonatomic, strong) NSURL *yy_imageURL;


/**
 Associate memory cache key.
 */
@property (nullable, nonatomic, strong, readonly) NSString *yy_memoryCacheKey;

/**
 Associate disk cache key.
 */
@property (nullable, nonatomic, strong, readonly) NSString *yy_diskCacheKey;

/**
 Set the view's `image` with a specified URL.
 
 @param imageURL    The image url (remote or local file path).
 @param placeholder The image to be set initially, until the image request finishes.
 @param itemOption   The options to use or indicate state when get or store image or data to cache.
 */
- (void)yy_setImageWithURL:(nullable NSURL *)imageURL
               placeholder:(nullable UIImage *)placeholder
                itemOption:(nullable YYWebImageItemOption *)itemOption;

/**
 Set the view's `image` with a specified URL.
 
 @param imageURL The image url (remote or local file path).
 @param options  The options to use when request the image.
 @param itemOption   The options to use or indicate state when get or store image or data to cache.
 */
- (void)yy_setImageWithURL:(nullable NSURL *)imageURL
                   options:(YYWebImageOptions)options
                itemOption:(nullable YYWebImageItemOption *)itemOption;

/**
 Set the view's `image` with a specified URL.
 
 @param imageURL    The image url (remote or local file path).
 @param placeholder The image to be set initially, until the image request finishes.
 @param options     The options to use when request the image.
 @param itemOption   The options to use or indicate state when get or store image or data to cache.
 @param completion  The block invoked (on main thread) when image request completed.
 */
- (void)yy_setImageWithURL:(nullable NSURL *)imageURL
               placeholder:(nullable UIImage *)placeholder
                   options:(YYWebImageOptions)options
                itemOption:(nullable YYWebImageItemOption *)itemOption
                completion:(nullable YYWebImageCompletionBlock)completion;

/**
 Set the view's `image` with a specified URL.
 
 @param imageURL    The image url (remote or local file path).
 @param placeholder The image to be set initially, until the image request finishes.
 @param options     The options to use when request the image.
 @param itemOption   The options to use or indicate state when get or store image or data to cache.
 @param progress    The block invoked (on main thread) during image request.
 @param transform   The block invoked (on background thread) to do additional image process.
 @param completion  The block invoked (on main thread) when image request completed.
 */
- (void)yy_setImageWithURL:(nullable NSURL *)imageURL
               placeholder:(nullable UIImage *)placeholder
                   options:(YYWebImageOptions)options
                itemOption:(nullable YYWebImageItemOption *)itemOption
                  progress:(nullable YYWebImageProgressBlock)progress
                 transform:(nullable YYWebImageTransformBlock)transform
                completion:(nullable YYWebImageCompletionBlock)completion;

/**
 Set the view's `image` with a specified URL.
 
 @param imageURL    The image url (remote or local file path).
 @param placeholder he image to be set initially, until the image request finishes.
 @param options     The options to use when request the image.
 @param itemOption   The options to use or indicate state when get or store image or data to cache.
 @param manager     The manager to create image request operation.
 @param progress    The block invoked (on main thread) during image request.
 @param transform   The block invoked (on background thread) to do additional image process.
 @param completion  The block invoked (on main thread) when image request completed.
 */
- (void)yy_setImageWithURL:(nullable NSURL *)imageURL
               placeholder:(nullable UIImage *)placeholder
                   options:(YYWebImageOptions)options
                itemOption:(nullable YYWebImageItemOption *)itemOption
                   manager:(nullable YYWebImageManager *)manager
                  progress:(nullable YYWebImageProgressBlock)progress
                 transform:(nullable YYWebImageTransformBlock)transform
                completion:(nullable YYWebImageCompletionBlock)completion;

/**
 Cancel the current image request.
 */
- (void)yy_cancelCurrentImageRequest;

/**
 Remove all cache. both memory cache and disk cache.
 */
- (void)yy_removeAllCache;

/**
 Remove memory cache.
 */
- (void)yy_removeMemoryCache;

/**
 Remove disk cache.
 */
- (void)yy_removeDiskCache;

/**
 Remove cache with specified cache type.
 */
- (void)yy_removeCache:(YYImageCacheType)cacheType;

@end

NS_ASSUME_NONNULL_END
