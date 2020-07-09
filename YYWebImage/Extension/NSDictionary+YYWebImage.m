//
//  NSDictionary+YYWebImage.m
//  YYWebImageDemo
//
//  Created by emmet7life on 2020/7/9.
//  Copyright © 2020 ibireme. All rights reserved.
//

#import "NSDictionary+YYWebImage.h"

@implementation NSDictionary (YYWebImage)

- (YYImageType)yy_imageType {
    YYImageType imageType = YYImageTypeOther;
    NSNumber *num = self[kYYWebImageOptionImageType];
    imageType = num.unsignedIntegerValue;
    return imageType;
}

- (CGSize)yy_targetSize {
    CGSize targetSize = CGSizeZero;
    NSNumber *num = self[kYYWebImageOptionTargetSize];
    targetSize = num.CGSizeValue;
    return targetSize;
}

- (Boolean)yy_shouldDecode {
    Boolean shouldDecode = NO;
    NSNumber *num = self[kYYWebImageOptionShouldDecode];
    shouldDecode = num.boolValue;
    return shouldDecode;
}

- (Boolean)yy_beProcessed {
    Boolean beProcessed = NO;
    NSNumber *num = self[kYYWebImageOptionBeProcessed];
    beProcessed = num.boolValue;
    return beProcessed;
}

- (NSString *)yy_cacheKeyForMemoryCache:(NSString *)cacheKey ignoreBeProcessed:(Boolean)isIgnoreBeProcessed {
    NSString *tmp = cacheKey;
    if (isIgnoreBeProcessed || self.yy_beProcessed) {
        CGSize targetSize = self.yy_targetSize;
        if (!CGSizeEqualToSize(CGSizeZero, targetSize)) {
            tmp = [tmp stringByAppendingFormat:@"_%ld", (NSInteger)targetSize.width];
            tmp = [tmp stringByAppendingFormat:@"_%ld", (NSInteger)targetSize.height];
        }
    }
    return tmp;
}

- (NSString *)yy_cacheKeyForDiskCache:(NSString *)cacheKey {
    return cacheKey;
}

@end
