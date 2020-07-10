//
//  NSDictionary+YYWebImage.h
//  YYWebImageDemo
//
//  Created by emmet7life on 2020/7/9.
//  Copyright © 2020 ibireme. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "YYImageCoder.h"
#import "YYWebImageConstMacro.h"

NS_ASSUME_NONNULL_BEGIN

@interface NSDictionary (YYWebImage)

- (YYImageType)yy_imageType;                                                ///< Get stored image format type value.
- (CGSize)yy_targetSize;                                                    ///> Get stored image target size value.
- (CGFloat)yy_targetScale;                                                  ///> Get stored image target scale value.
- (Boolean)yy_shouldDecode;                                                 ///> Get stored image should be decode or not value.
- (Boolean)yy_beProcessed;                                                  ///> Get stored image has been processed or not  by value YYWebImageProcessor.
- (NSString *)yy_transformIdentifier;                                       ///> Get stored image transform`s identifier.
- (NSString *)yy_cacheKeyForMemoryCache:(NSString *)cacheKey                ///> Get cache key for memory cache. generally format style is URL_widthPixel_x_heightPixel_[YYWebImageProcessor`s identifier].
                    processorIdentifier:(nullable NSString *)identifier;
- (NSString *)yy_cacheKeyForDiskCache:(NSString *)cacheKey;                 ///> Get cache key for disk cache. generally format style is URL.

@end

NS_ASSUME_NONNULL_END
