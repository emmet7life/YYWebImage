//
//  YYWebImageProExample.m
//  YYWebImageDemo
//
//  Created by emmet7life on 2020/7/9.
//  Copyright © 2020 ibireme. All rights reserved.
//

#import "YYWebImageProExample.h"
#import "YYWebImage.h"

@interface YYWebImageProExample ()

@property (nullable, nonatomic, strong) UIImageView *imageView;

@end

@implementation YYWebImageProExample

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.whiteColor;
    
    UIImageView *imageView = [[YYAnimatedImageView alloc] init];
    imageView.frame = CGRectMake(10, 40, 400, 400);
    imageView.clipsToBounds = YES;
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    [self.view addSubview:imageView];
    _imageView = imageView;
    
    UIButton *button = [[UIButton alloc] init];
    button.frame = CGRectMake(100, 420, 220, 44);
    [button setTitle:@"Load_400x400" forState:UIControlStateNormal];
    [button setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    [self.view addSubview:button];
    [button addTarget:self action:@selector(buttonTapped) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *button2 = [[UIButton alloc] init];
    button2.frame = CGRectMake(100, 480, 220, 44);
    [button2 setTitle:@"Load_100x100" forState:UIControlStateNormal];
    [button2 setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    [self.view addSubview:button2];
    [button2 addTarget:self action:@selector(buttonTapped2) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *resetButton = [[UIButton alloc] init];
    resetButton.frame = CGRectMake(100, 540, 220, 44);
    [resetButton setTitle:@"Reset" forState:UIControlStateNormal];
    [resetButton setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    [self.view addSubview:resetButton];
    [resetButton addTarget:self action:@selector(resetTapped) forControlEvents:UIControlEventTouchUpInside];
}

- (void)buttonTapped {
    [self fetchImage: CGSizeMake(400, 400)];
}

- (void)buttonTapped2 {
    [self fetchImage: CGSizeMake(100, 100)];
}

- (void)resetTapped {
    self.imageView.image = nil;
}

- (void)fetchImage:(CGSize)targetSize {
    NSDictionary<NSString *, id> *info = @{
        kYYWebImageOptionTargetScale: @(UIScreen.mainScreen.scale),
        kYYWebImageOptionTargetSize: @(targetSize)
    };
    
//    NSString *imageUrl = @"https://timgsa.baidu.com/timg?image&quality=80&size=b9999_10000&sec=1594293055688&di=6c790e2f4d899d2f9b68f242d5c29987&imgtype=0&src=http%3A%2F%2Ft8.baidu.com%2Fit%2Fu%3D2247852322%2C986532796%26fm%3D79%26app%3D86%26f%3DJPEG%3Fw%3D1280%26h%3D853";
    NSString *imageUrl = @"http://img.manhua.weibo.com/comic/23/71323/315749/001_315749_shard_1.webp";
//    NSString *imageUrl = @"https://i.imgur.com/uoBwCLj.gif";
    
    NSURL *url = [NSURL URLWithString:imageUrl];
    
    [_imageView yy_setImageWithURL:url
                          placeholder:nil
                          options:YYWebImageOptionShowNetworkActivity | YYWebImageOptionSetImageWithFadeAnimation
                             info:info
                         progress:^(NSInteger receivedSize, NSInteger expectedSize) {
                            NSLog(@"receivedSize is %ld, expectedSize is %ld", (long)receivedSize, (long)expectedSize);
                         }
                         transform:nil
                         completion:^(UIImage *image, NSURL *url, YYWebImageFromType from, YYWebImageStage stage, NSError *error) {
                            if (stage == YYWebImageStageFinished) {
                                NSString *fromTypeStr = @"None";
                                switch (from) {
                                      case YYWebImageFromNone: {
                                          fromTypeStr = @"None";
                                      } break;
                                      case YYWebImageFromMemoryCacheFast: {
                                          fromTypeStr = @"MemoryFast";
                                      } break;
                                      case YYWebImageFromMemoryCache: {
                                          fromTypeStr = @"Memory";
                                      } break;
                                      case YYWebImageFromDiskCache: {
                                          fromTypeStr = @"Disk";
                                      } break;
                                      case YYWebImageFromRemote: {
                                          fromTypeStr = @"Remote";
                                      } break;
                                      default:
                                          break;
                                 }
                                 NSLog(@"加载成功啦！from %@ ✅", fromTypeStr);
                              }
                         }];
}

@end
