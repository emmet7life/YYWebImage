//
//  YYWebImageItemOption.h
//  YYWebImageDemo
//
//  Created by emmet7life on 2020/7/14.
//  Copyright © 2020 ibireme. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YYImageCoder.h"

NS_ASSUME_NONNULL_BEGIN

@interface YYWebImageItemOption : NSObject

@property (nonatomic, assign) YYImageType imageType;            ///> The image format type.
@property (nonatomic, assign) CGSize targetSize;                ///> The target size, unit is point, the value generally is UIImageView`s size.
@property (nonatomic, assign) CGFloat targetScale;              ///> The target scale, generally is UIScreen.mainScreen`s scale.
@property (nonatomic, assign) Boolean beProcessed;              ///> Indicate whether the image has been processed  or not by YYWebImageProcessor.
@property (nonatomic, assign) Boolean beTransformed;            ///> Indicate whether the image has been transformed  or not by transform block.
@property (nonatomic, strong) NSString *transformIdentifier;    ///> The transform`s identifer. similar with processor`s identifier.

/**
 get cache key for memory cache. generally format style is URL_widthPixel_x_heightPixel_[YYWebImageProcessor`s identifier]_[transform`s identifier].
 */
- (NSString *)cacheKeyForMemoryCache:(NSString *)cacheKey processorIdentifier:(nullable NSString *)identifier;

/**
 get cache key for disk cache. generally format style is URL.
 */
- (NSString *)cacheKeyForDiskCache:(NSString *)cacheKey;

@end

NS_ASSUME_NONNULL_END
