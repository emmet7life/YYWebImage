//
//  UIImageView+YYWebImage.h
//  YYWebImage <https://github.com/ibireme/YYWebImage>
//
//  Created by ibireme on 15/2/23.
//  Copyright (c) 2015 ibireme.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import <UIKit/UIKit.h>

#if __has_include(<YYWebImage/YYWebImage.h>)
#import <YYWebImage/YYWebImageManager.h>
#else
#import "YYWebImageManager.h"
#endif

NS_ASSUME_NONNULL_BEGIN

/**
 Web image methods for UIImageView.
 */
@interface UIImageView (YYWebImage)

#pragma mark - image

/**
 Current image URL.
 
 @discussion Set a new value to this property will cancel the previous request 
 operation and create a new request operation to fetch image. Set nil to clear 
 the image and image URL.
 */
@property (nullable, nonatomic, strong) NSURL *yy_imageURL;

/**
 Set the view's `image` with a specified URL.
 
 @param imageURL    The image url (remote or local file path).
 @param placeholder The image to be set initially, until the image request finishes.
 @param info   The dictionary info. generally only set value with kYYWebImageOptionTargetSize key. 
 */
- (void)yy_setImageWithURL:(nullable NSURL *)imageURL
               placeholder:(nullable UIImage *)placeholder
                      info:(nullable NSDictionary<NSString *, id> *)info;

/**
 Set the view's `image` with a specified URL.
 
 @param imageURL The image url (remote or local file path).
 @param options  The options to use when request the image.
 @param info   The dictionary info. generally only set value with kYYWebImageOptionTargetSize key.
 */
- (void)yy_setImageWithURL:(nullable NSURL *)imageURL
                   options:(YYWebImageOptions)options
                      info:(nullable NSDictionary<NSString *, id> *)info;

/**
 Set the view's `image` with a specified URL.
 
 @param imageURL    The image url (remote or local file path).
 @param placeholder The image to be set initially, until the image request finishes.
 @param options     The options to use when request the image.
 @param info   The dictionary info. generally only set value with kYYWebImageOptionTargetSize key.
 @param completion  The block invoked (on main thread) when image request completed.
 */
- (void)yy_setImageWithURL:(nullable NSURL *)imageURL
               placeholder:(nullable UIImage *)placeholder
                   options:(YYWebImageOptions)options
                      info:(nullable NSDictionary<NSString *, id> *)info
                completion:(nullable YYWebImageCompletionBlock)completion;

/**
 Set the view's `image` with a specified URL.
 
 @param imageURL    The image url (remote or local file path).
 @param placeholder The image to be set initially, until the image request finishes.
 @param options     The options to use when request the image.
 @param info   The dictionary info. generally only set value with kYYWebImageOptionTargetSize key.
 @param progress    The block invoked (on main thread) during image request.
 @param transform   The block invoked (on background thread) to do additional image process.
 @param completion  The block invoked (on main thread) when image request completed.
 */
- (void)yy_setImageWithURL:(nullable NSURL *)imageURL
               placeholder:(nullable UIImage *)placeholder
                   options:(YYWebImageOptions)options
                      info:(nullable NSDictionary<NSString *, id> *)info
                  progress:(nullable YYWebImageProgressBlock)progress
                 transform:(nullable YYWebImageTransformBlock)transform
                completion:(nullable YYWebImageCompletionBlock)completion;

/**
 Set the view's `image` with a specified URL.
 
 @param imageURL    The image url (remote or local file path).
 @param placeholder he image to be set initially, until the image request finishes.
 @param options     The options to use when request the image.
 @param info   The dictionary info. generally only set value with kYYWebImageOptionTargetSize key.
 @param manager     The manager to create image request operation.
 @param progress    The block invoked (on main thread) during image request.
 @param transform   The block invoked (on background thread) to do additional image process.
 @param completion  The block invoked (on main thread) when image request completed.
 */
- (void)yy_setImageWithURL:(nullable NSURL *)imageURL
               placeholder:(nullable UIImage *)placeholder
                   options:(YYWebImageOptions)options
                      info:(nullable NSDictionary<NSString *, id> *)info
                   manager:(nullable YYWebImageManager *)manager
                  progress:(nullable YYWebImageProgressBlock)progress
                 transform:(nullable YYWebImageTransformBlock)transform
                completion:(nullable YYWebImageCompletionBlock)completion;

/**
 Cancel the current image request.
 */
- (void)yy_cancelCurrentImageRequest;



#pragma mark - highlight image

/**
 Current highlighted image URL.
 
 @discussion Set a new value to this property will cancel the previous request
 operation and create a new request operation to fetch image. Set nil to clear
 the highlighted image and image URL.
 */
@property (nullable, nonatomic, strong) NSURL *yy_highlightedImageURL;

/**
 Set the view's `highlightedImage` with a specified URL.
 
 @param imageURL    The image url (remote or local file path).
 @param placeholder The image to be set initially, until the image request finishes.
 @param info   The dictionary info. generally only set value with kYYWebImageOptionTargetSize key.
 */
- (void)yy_setHighlightedImageWithURL:(nullable NSURL *)imageURL
                          placeholder:(nullable UIImage *)placeholder
                                 info:(nullable NSDictionary<NSString *, id> *)info;

/**
 Set the view's `highlightedImage` with a specified URL.
 
 @param imageURL The image url (remote or local file path).
 @param options  The options to use when request the image.
 @param info   The dictionary info. generally only set value with kYYWebImageOptionTargetSize key.
 */
- (void)yy_setHighlightedImageWithURL:(nullable NSURL *)imageURL
                              options:(YYWebImageOptions)options
                                 info:(nullable NSDictionary<NSString *, id> *)info;

/**
 Set the view's `highlightedImage` with a specified URL.
 
 @param imageURL    The image url (remote or local file path).
 @param placeholder The image to be set initially, until the image request finishes.
 @param options     The options to use when request the image.
 @param info   The dictionary info. generally only set value with kYYWebImageOptionTargetSize key.
 @param completion  The block invoked (on main thread) when image request completed.
 */
- (void)yy_setHighlightedImageWithURL:(nullable NSURL *)imageURL
                          placeholder:(nullable UIImage *)placeholder
                              options:(YYWebImageOptions)options
                                 info:(nullable NSDictionary<NSString *, id> *)info
                           completion:(nullable YYWebImageCompletionBlock)completion;

/**
 Set the view's `highlightedImage` with a specified URL.
 
 @param imageURL    The image url (remote or local file path).
 @param placeholder The image to be set initially, until the image request finishes.
 @param options     The options to use when request the image.
 @param info   The dictionary info. generally only set value with kYYWebImageOptionTargetSize key.
 @param progress    The block invoked (on main thread) during image request.
 @param transform   The block invoked (on background thread) to do additional image process.
 @param completion  The block invoked (on main thread) when image request completed.
 */
- (void)yy_setHighlightedImageWithURL:(nullable NSURL *)imageURL
                          placeholder:(nullable UIImage *)placeholder
                              options:(YYWebImageOptions)options
                                 info:(nullable NSDictionary<NSString *, id> *)info
                             progress:(nullable YYWebImageProgressBlock)progress
                            transform:(nullable YYWebImageTransformBlock)transform
                           completion:(nullable YYWebImageCompletionBlock)completion;

/**
 Set the view's `highlightedImage` with a specified URL.
 
 @param imageURL    The image url (remote or local file path).
 @param placeholder The image to be set initially, until the image request finishes.
 @param options     The options to use when request the image.
 @param info   The dictionary info. generally only set value with kYYWebImageOptionTargetSize key.
 @param manager     The manager to create image request operation.
 @param progress    The block invoked (on main thread) during image request.
 @param transform   The block invoked (on background thread) to do additional image process.
 @param completion  The block invoked (on main thread) when image request completed.
 */
- (void)yy_setHighlightedImageWithURL:(nullable NSURL *)imageURL
                          placeholder:(nullable UIImage *)placeholder
                              options:(YYWebImageOptions)options
                                 info:(nullable NSDictionary<NSString *, id> *)info
                              manager:(nullable YYWebImageManager *)manager
                             progress:(nullable YYWebImageProgressBlock)progress
                            transform:(nullable YYWebImageTransformBlock)transform
                           completion:(nullable YYWebImageCompletionBlock)completion;

/**
 Cancel the current highlighed image request.
 */
- (void)yy_cancelCurrentHighlightedImageRequest;

@end

NS_ASSUME_NONNULL_END
