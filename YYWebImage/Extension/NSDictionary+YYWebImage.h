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

///< Get stored image format type value.
- (YYImageType)yy_imageType;

///> Get stored image target size value.
- (CGSize)yy_targetSize;

///> Get stored image target scale value.
- (CGFloat)yy_targetScale;

///> Get stored image should be decode or not value.
- (Boolean)yy_shouldDecode;

///> Get stored image has been processed or not  by value YYWebImageProcessor.
- (Boolean)yy_beProcessed;

///> Get stored image has been transformed or not  by value transform block.
- (Boolean)yy_beTransformed;

///> Get stored image transform`s identifier.
- (NSString *)yy_transformIdentifier;

///> Get cache key for memory cache. generally format style is URL_widthPixel_x_heightPixel_[YYWebImageProcessor`s identifier].
- (NSString *)yy_cacheKeyForMemoryCache:(NSString *)cacheKey processorIdentifier:(nullable NSString *)identifier;

///> Get cache key for disk cache. generally format style is URL.
- (NSString *)yy_cacheKeyForDiskCache:(NSString *)cacheKey;

@end

NS_ASSUME_NONNULL_END
