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
#import "NSDictionary+YYWebImage.h"
#import <UIKit/UIKit.h>

@implementation YYWebImageDefaultProcessor

- (NSString *)identifier {
    return NSStringFromClass([self class]);
}

- (UIImage *)processImage:(UIImage *)image options:(NSDictionary<NSString *, id> *)info {
    return image;
}

- (UIImage *)processData:(NSData *)data options:(NSDictionary<NSString *, id> *)info {
    YYImageType imageType = YYImageTypeOther;
    CGSize targetSize = CGSizeZero;
    CGFloat targetScale = 0;
    Boolean shouldDecode = YES;// default YES
    
    if (info) {
        imageType = info.yy_imageType;
        targetSize = info.yy_targetSize;
        targetScale = info.yy_targetScale;
        shouldDecode = info.yy_shouldDecode;
    }
    
    // convert point unit to pixel unit if needed
    if (targetSize.width > 0 && targetSize.height > 0) {
        if (targetScale <= 0) {
            targetScale = [UIScreen mainScreen].scale;
        }
        CGFloat widthPixel = targetSize.width * targetScale;
        CGFloat heightPixel = targetSize.height * targetScale;
        targetSize = CGSizeMake(widthPixel, heightPixel);
    }
    
    if (imageType == YYImageTypeOther) {
        imageType = YYImageDetectType((__bridge CFDataRef)data);
    }

    #ifdef DEBUG
    NSLog(@"YYWebImage >> shouldDecode is %@", shouldDecode ? @"YES" : @"NO");
    NSLog(@"YYWebImage >> imageType    is %@", YYImageTypeGetExtension(imageType));
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
