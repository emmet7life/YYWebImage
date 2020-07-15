//
//  YYWebImageProcessor.m
//  YYWebImageDemo
//
//  Created by emmet7life on 2020/7/8.
//  Copyright © 2020 ibireme. All rights reserved.
//

#import "YYWebImageProcessor.h"
#import "YYImageCoder.h"
#import "YYWebImageUtils.h"
#import "YYWebImageItemOption.h"
#import <UIKit/UIKit.h>

@implementation YYWebImageDefaultProcessor

- (NSString *)identifier {
    return NSStringFromClass([self class]);
}

- (UIImage *)processImage:(UIImage *)image shouldDecode:(Boolean)shouldDecode itemOption:(YYWebImageItemOption *)itemOption {
    return image;
}

- (UIImage *)processData:(NSData *)data shouldDecode:(Boolean)shouldDecode itemOption:(YYWebImageItemOption *)itemOption {
    YYImageType imageType = YYImageTypeUnknown;
    CGSize targetSize = CGSizeZero;
    CGFloat targetScale = 0;
    
    if (itemOption) {
        imageType = itemOption.imageType;
        targetSize = itemOption.targetSize;
        targetScale = itemOption.targetScale;
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
    
    if (imageType == YYImageTypeOther || imageType == YYImageTypeUnknown) {
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
                                                              targetScale:targetScale
                                                                imageType:imageType
                                                             shouldDecode:shouldDecode
                                                                 withData:data];
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
