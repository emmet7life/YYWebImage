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

- (YYImageType)yy_imageType;
- (CGSize)yy_targetSize;
- (Boolean)yy_shouldDecode;
- (Boolean)yy_beProcessed;
- (NSString *)yy_cacheKeyForMemoryCache:(NSString *)cacheKey ignoreBeProcessed:(Boolean)isIgnoreBeProcessed;
- (NSString *)yy_cacheKeyForDiskCache:(NSString *)cacheKey;

@end

NS_ASSUME_NONNULL_END
