//
//  YYWebImageItemOption.m
//  YYWebImageDemo
//
//  Created by emmet7life on 2020/7/14.
//  Copyright © 2020 ibireme. All rights reserved.
//

#import "YYWebImageItemOption.h"

@implementation YYWebImageItemOption

- (YYImageType)imageType {
    if (!_imageType) {
        _imageType = YYImageTypeUnknown;
    }
    return _imageType;
}

- (CGFloat)targetScale {
    if (_targetScale <= 0) {
        _targetScale = [[UIScreen mainScreen] scale];
    }
    return _targetScale;
}

- (NSString *)cacheKeyForMemoryCache:(NSString *)cacheKey processorIdentifier:(NSString *)identifier {
    NSString *tmp = cacheKey;
    
    if (self.beProcessed) {
        CGSize targetSize = self.targetSize;
        if (targetSize.width > 0 && targetSize.height > 0) {
            CGFloat targetScale = self.targetScale;
            NSInteger widthPixel = (NSInteger)(targetSize.width * targetScale);
            NSInteger heightPixel = (NSInteger)(targetSize.height * targetScale);
            tmp = [tmp stringByAppendingFormat:@"_%ld_x_%ld", widthPixel, heightPixel];
        }
        
        if (identifier && identifier.length > 0) {
            tmp = [tmp stringByAppendingFormat:@"_%@", identifier];
        } else {
            tmp = [tmp stringByAppendingFormat:@"_DefaultProcessorIdentifier"];
        }
    }
    
    if (self.beTransformed) {
        NSString *transformIdentifier = self.transformIdentifier;
        if (transformIdentifier && transformIdentifier.length > 0) {
           tmp = [tmp stringByAppendingFormat:@"_%@", transformIdentifier];
        } else {
            tmp = [tmp stringByAppendingFormat:@"_DefaultTransformIdentifier"];
        }
    }
        
    return tmp;
}

- (NSString *)cacheKeyForDiskCache:(NSString *)cacheKey {
    return cacheKey;
}


@end
