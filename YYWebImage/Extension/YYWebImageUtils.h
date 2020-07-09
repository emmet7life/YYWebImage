//
//  YYWebImageUtils.h
//  YYWebImageDemo
//
//  Created by emmet7life on 2020/7/9.
//  Copyright © 2020 ibireme. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "YYImageCoder.h"

NS_ASSUME_NONNULL_BEGIN

@interface YYWebImageUtils : NSObject

/**
transform a data to image, the image will be resized to targetSize.
Attension: Only support for PNG/JPG/JPG2000? image format type.
 
@param targetSize   The image target size.
@param data   The Image Original Data.
@param imageType   The Image type. If type is unknown, use data to detect.
@param shouldDecode   The Image should be decode or not.
@return A resized  image.
*/
+ (nullable UIImage *)transformDataToImage:(CGSize)targetSize
                                  withData:(NSData *)data
                                 imageType:(YYImageType)imageType
                              shouldDecode:(Boolean)shouldDecode;

@end

NS_ASSUME_NONNULL_END
