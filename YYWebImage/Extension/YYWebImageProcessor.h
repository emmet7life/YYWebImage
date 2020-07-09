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

// 图片处理器
@protocol YYWebImageProcessor <NSObject>

@required
- (NSString *)identifier;
- (nullable UIImage *)processImage:(UIImage *)image options: (nullable NSDictionary<NSString *, id> *)info;
- (nullable UIImage *)processData:(NSData *)data options: (nullable NSDictionary<NSString *, id> *)info;

@end

// 默认图片处理器
@interface YYWebImageDefaultProcessor : NSObject <YYWebImageProcessor>

@end

NS_ASSUME_NONNULL_END
