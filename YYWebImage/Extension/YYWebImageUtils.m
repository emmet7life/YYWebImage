//
//  YYWebImageUtils.m
//  YYWebImageDemo
//
//  Created by emmet7life on 2020/7/9.
//  Copyright © 2020 ibireme. All rights reserved.
//

#import "YYWebImageUtils.h"
#import <ImageIO/ImageIO.h>
#import "YYImageCoder.h"

@implementation YYWebImageUtils

+ (nullable UIImage *)transformDataToImage:(CGSize)targetSize
                               targetScale:(CGFloat)targetScale
                                 imageType:(YYImageType)imageType
                              shouldDecode:(Boolean)shouldDecode
                                  withData:(NSData *)data {
    CGFloat maxPixelSize = MAX(targetSize.width, targetSize.height);
    if (maxPixelSize <= 0) {
        maxPixelSize = 99999999;// a big value, can not set to CGFLOAT_MAX.
    }
    
    if (imageType == YYImageTypeOther || imageType == YYImageTypeUnknown) {
        imageType = YYImageDetectType((__bridge CFDataRef)data);
    }
    
    if (imageType == YYImageTypeJPEG
        /* || imageType == YYImageTypeJPEG2000 */// TODO is YYImageTypeJPEG2000 ok?
        || imageType == YYImageTypePNG) {
        CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)data, (CFDictionaryRef)@{(id)kCGImageSourceShouldCache: @(NO)});
        if (!source) {
            return nil;
        }
        NSDictionary *info = @{
            (id)kCGImageSourceThumbnailMaxPixelSize: @(maxPixelSize),
            (id)kCGImageSourceShouldCacheImmediately: @(shouldDecode),
            (id)kCGImageSourceCreateThumbnailWithTransform: @(YES),
            (id)kCGImageSourceCreateThumbnailFromImageAlways: @(YES),
        };
        CFDictionaryRef options = (__bridge CFDictionaryRef)info;
        CGImageRef decoded = CGImageSourceCreateThumbnailAtIndex(source, 0, options);
        if (!decoded) {
            CFRelease(source);
            return nil;
        }
        CGFloat scale = targetScale;
        if (scale <= 0) {
            scale = [[UIScreen mainScreen] scale];
        }
        UIImage *decodedImage = [UIImage imageWithCGImage:decoded scale:scale orientation:UIImageOrientationUp];
        CFRelease(source);
        CFRelease(decoded);
        
        #ifdef DEBUG
        if (decodedImage) {
            NSLog(@"YYWebImage >> transformDataToImage >> decodedImage size is %@，✅", NSStringFromCGSize(decodedImage.size));
        } else {
            NSLog(@"YYWebImage >> transformDataToImage >> decodedImage is NULL ⚠️");
        }
        #endif
        
        return decodedImage;
    }
    return nil;
}

@end
