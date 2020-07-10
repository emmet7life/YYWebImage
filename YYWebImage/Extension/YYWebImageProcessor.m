//
//  YYWebImageProcessor.m
//  YYWebImageDemo
//
//  Created by emmet7life on 2020/7/8.
//  Copyright © 2020 ibireme. All rights reserved.
//

#import "YYWebImageProcessor.h"
#import "YYImageCoder.h"
#import "YYWebImageConstMacro.h"
#import "YYWebImageUtils.h"
#import <UIKit/UIKit.h>

@implementation YYWebImageDefaultProcessor

- (NSString *)identifier {
    return NSStringFromClass([self class]);
}

- (UIImage *)processImage:(UIImage *)image options:(NSDictionary<NSString *, id> *)info {
    return nil;
}

- (UIImage *)processData:(NSData *)data options:(NSDictionary<NSString *, id> *)info {
    YYImageType imageType = YYImageTypeOther;
    CGSize targetSize = CGSizeZero;
    CGFloat targetScale = 1.0;
    Boolean shouldDecode = NO;
    
    if (info) {
        NSNumber *num = info[kYYWebImageOptionImageType];
        imageType = num.unsignedIntegerValue;
        
        num = info[kYYWebImageOptionTargetSize];
        targetSize = num.CGSizeValue;
        
        num = info[kYYWebImageOptionTargetScale];
        targetScale = num.floatValue;
        
        num = info[kYYWebImageOptionShouldDecode];
        shouldDecode = num.boolValue;
    }
    
    // convert point unit to pixel unit if needed
    if (targetSize.width > 0 && targetSize.height > 0) {
        if (targetScale <= 0) {
            targetScale = 1.0;
        }
        CGFloat widthPixel = targetSize.width * targetScale;
        CGFloat heightPixel = targetSize.height * targetScale;
        targetSize = CGSizeMake(widthPixel, heightPixel);
    }
    
    if (imageType == YYImageTypeOther) {
        imageType = YYImageDetectType((__bridge CFDataRef)data);
    }

    #ifdef DEBUG
    CFStringRef imageTypeRef = YYImageTypeToUTType(imageType);
    NSLog(@"YYWebImage >> shouldDecode is %@", shouldDecode ? @"YES" : @"NO");
    NSLog(@"YYWebImage >> imageType    is %@", (__bridge NSString *)imageTypeRef);
    NSLog(@"YYWebImage >> targetSize   is %@", NSStringFromCGSize(targetSize));
    #endif
    
    switch (imageType) {
        case YYImageTypePNG:
        case YYImageTypeJPEG: {// TODO is YYImageTypeJPEG2000 ok?
            UIImage *decodedImage = [YYWebImageUtils transformDataToImage:targetSize
                                                                 withData:data
                                                                imageType:imageType
                                                             shouldDecode:shouldDecode];
            if (decodedImage && shouldDecode) {
                [decodedImage setYy_isDecodedForDisplay:YES];
            }
            return decodedImage;
        } break;
        default:
            break;
    }
    return nil;
}

@end
