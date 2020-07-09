//
//  YYWebImageModifier.h
//  YYWebImageDemo
//
//  Created by emmet7life on 2020/7/9.
//  Copyright © 2020 ibireme. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol YYWebImageModifier <NSObject>

- (UIImage *)modifyImage:(UIImage *)image options: (nullable NSDictionary<NSString *, id> *)info;

@end

@interface YYWebImageDefaultModifier : NSObject <YYWebImageModifier>

@end

NS_ASSUME_NONNULL_END
