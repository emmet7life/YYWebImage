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

- (NSString *)yy_transformIdentifier {
    NSString *transformIdentifier = @"";
    NSValue *value = self[kYYWebImageOptionTransformIdentifier];
    if (value) {
        transformIdentifier = (NSString *)value.pointerValue;
    }
    return transformIdentifier;
}

- (NSString *)yy_cacheKeyForMemoryCache:(NSString *)cacheKey
                    processorIdentifier:(nullable NSString *)identifier {
    NSString *tmp = cacheKey;
    
    CGSize targetSize = self.yy_targetSize;
    if (targetSize.width > 0 && targetSize.height > 0) {
        CGFloat targetScale = self.yy_targetScale;
        NSInteger widthPixel = (NSInteger)(targetSize.width * targetScale);
        NSInteger heightPixel = (NSInteger)(targetSize.height * targetScale);
        tmp = [tmp stringByAppendingFormat:@"_%ld_x_%ld", widthPixel, heightPixel];
    }
    
    if (identifier && identifier.length > 0) {
        tmp = [tmp stringByAppendingFormat:@"_%@", identifier];
    }
    
    NSString *transformIdentifier = self.yy_transformIdentifier;
    if (transformIdentifier && transformIdentifier.length > 0) {
        tmp = [tmp stringByAppendingFormat:@"_%@", transformIdentifier];
    }
    
    return tmp;
}

- (NSString *)yy_cacheKeyForDiskCache:(NSString *)cacheKey {
    return cacheKey;
}

@end
