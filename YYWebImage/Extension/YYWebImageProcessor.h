//
//  YYWebImageProcessor.h
//  YYWebImageDemo
//
//  Created by emmet7life on 2020/7/8.
//  Copyright © 2020 ibireme. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class YYWebImageItemOption;

// 图片处理器
@protocol YYWebImageProcessor <NSObject>

@required
- (NSString *)identifier;
- (nullable UIImage *)processImage:(UIImage *)image shouldDecode:(Boolean)shouldDecode itemOption:(nullable YYWebImageItemOption *)itemOption;
- (nullable UIImage *)processData:(NSData *)data shouldDecode:(Boolean)shouldDecode itemOption:(nullable YYWebImageItemOption *)itemOption;

@end

// 默认图片处理器
@interface YYWebImageDefaultProcessor : NSObject <YYWebImageProcessor>

@end

NS_ASSUME_NONNULL_END
