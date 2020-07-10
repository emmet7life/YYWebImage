//
//  NSDictionary+YYWebImage.m
//  YYWebImageDemo
//
//  Created by emmet7life on 2020/7/9.
//  Copyright © 2020 ibireme. All rights reserved.
//

#import "NSDictionary+YYWebImage.h"
#import <UIKit/UIKit.h>

@implementation NSDictionary (YYWebImage)

- (YYImageType)yy_imageType {
    YYImageType imageType = YYImageTypeOther;
    NSNumber *num = self[kYYWebImageOptionImageType];
    if (num) {
        imageType = num.unsignedIntegerValue;
    }
    return imageType;
}

- (CGSize)yy_targetSize {
    CGSize targetSize = CGSizeZero;
    NSNumber *num = self[kYYWebImageOptionTargetSize];
    if (num) {
        targetSize = num.CGSizeValue;
    }
    return targetSize;
}

- (CGFloat)yy_targetScale {
    CGFloat targetScale = 0;
    NSNumber *num = self[kYYWebImageOptionTargetScale];
    if (num) {
        targetScale = num.floatValue;
    }
    if (targetScale <= 0) {
        targetScale = [UIScreen mainScreen].scale;
    }
    return targetScale;
}

- (Boolean)yy_shouldDecode {
    Boolean shouldDecode = NO;
    NSNumber *num = self[kYYWebImageOptionShouldDecode];
    if (num) {
        shouldDecode = num.boolValue;
    }
    return shouldDecode;
}

- (Boolean)yy_beProcessed {
    Boolean beProcessed = NO;
    NSNumber *num = self[kYYWebImageOptionBeProcessed];
    if (num) {
        beProcessed = num.boolValue;
    }
    return beProcessed;
}

- (NSString *)yy_cacheKeyForMemoryCache:(NSString *)cacheKey
                    processorIdentifier:(nullable NSString *)identifier
                      ignoreBeProcessed:(Boolean)isIgnoreBeProcessed {
    NSString *tmp = cacheKey;
    if (isIgnoreBeProcessed || self.yy_beProcessed) {
        CGSize targetSize = self.yy_targetSize;
        CGFloat targetScale = self.yy_targetScale;
        if (targetSize.width > 0 && targetSize.height > 0) {
            tmp = [tmp stringByAppendingFormat:@"_%ld", (NSInteger)(targetSize.width * targetScale)];
            tmp = [tmp stringByAppendingFormat:@"_x_%ld", (NSInteger)(targetSize.height * targetScale)];
            if (identifier) {
                tmp = [tmp stringByAppendingFormat:@"_%@", identifier];
            }
        }
    }
    return tmp;
}

- (NSString *)yy_cacheKeyForDiskCache:(NSString *)cacheKey {
    return cacheKey;
}

@end
