//
//  YYWebImageCacheSerializer.h
//  YYWebImageDemo
//
//  Created by emmet7life on 2020/7/8.
//  Copyright © 2020 ibireme. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

// 图片序列化器
@protocol YYWebImageCacheSerializer <NSObject>
@required
- (nullable NSData *)dataWith:(UIImage *)image
                 originalData:(nullable NSData *)data;

- (nullable UIImage *)imageWith:(nullable NSData *)data
                 options:(nullable NSDictionary *)options;

@end

// 默认图片序列化器
@interface YYWebImageDefaultCacheSerializer : NSObject <YYWebImageCacheSerializer>

@end

NS_ASSUME_NONNULL_END
