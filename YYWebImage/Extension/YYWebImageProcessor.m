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
    return @"";
}

- (UIImage *)processImage:(UIImage *)image options:(NSDictionary<NSString *, id> *)info {
    return nil;
}

- (UIImage *)processData:(NSData *)data options:(NSDictionary<NSString *, id> *)info {
    YYImageType imageType = YYImageTypeOther;
    CGSize targetSize = CGSizeZero;
    Boolean shouldDecode = NO;
    
    if (info) {
        NSNumber *num = info[kYYWebImageOptionImageType];
        imageType = num.unsignedIntegerValue;
        
        num = info[kYYWebImageOptionTargetSize];
        targetSize = num.CGSizeValue;
        
        num = info[kYYWebImageOptionShouldDecode];
        shouldDecode = num.boolValue;
    }
    
    if (imageType == YYImageTypeOther) {
        imageType = YYImageDetectType((__bridge CFDataRef)data);
    }

    #ifdef DEBUG
    NSLog(@"YYWebImage >> shouldDecode is %@", shouldDecode ? @"YES" : @"NO");
    NSLog(@"YYWebImage >> imageType    is %lu", (unsigned long)imageType);
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
