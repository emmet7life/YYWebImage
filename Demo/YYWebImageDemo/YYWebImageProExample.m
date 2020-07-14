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
    
    UIButton *button = [[UIButton alloc] init];
    button.frame = CGRectMake(10, 100, 220, 44);
    [button setTitle:@"Load_400x400" forState:UIControlStateNormal];
    [button setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    [self.view addSubview:button];
    [button addTarget:self action:@selector(buttonTapped) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *button2 = [[UIButton alloc] init];
    button2.frame = CGRectMake(10, 150, 220, 44);
    [button2 setTitle:@"Load_100x100" forState:UIControlStateNormal];
    [button2 setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    [self.view addSubview:button2];
    [button2 addTarget:self action:@selector(buttonTapped2) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *button3 = [[UIButton alloc] init];
    button3.frame = CGRectMake(10, 200, 220, 44);
    [button3 setTitle:@"Load_NoTransform" forState:UIControlStateNormal];
    [button3 setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    [self.view addSubview:button3];
    [button3 addTarget:self action:@selector(buttonTapped3) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *resetButton = [[UIButton alloc] init];
    resetButton.frame = CGRectMake(10, 250, 220, 44);
    [resetButton setTitle:@"Reset" forState:UIControlStateNormal];
    [resetButton setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    [self.view addSubview:resetButton];
    [resetButton addTarget:self action:@selector(resetTapped) forControlEvents:UIControlEventTouchUpInside];
    
    UIImageView *imageView = [[YYAnimatedImageView alloc] init];
    imageView.frame = CGRectMake(10, 300, 365, 365);
    imageView.clipsToBounds = YES;
    imageView.backgroundColor = [UIColor darkGrayColor];
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.view addSubview:imageView];
    _imageView = imageView;
}

- (void)buttonTapped {
    CGSize size = CGSizeMake(365, 365);
    CGRect frame = _imageView.frame;
    frame.size = size;
    _imageView.frame = frame;
    [self fetchImageWithTransform:size];
//    [self fetchImageWithNoTransform: size];
}

- (void)buttonTapped2 {
    CGSize size = CGSizeMake(180, 180);
    CGRect frame = _imageView.frame;
    frame.size = size;
    _imageView.frame = frame;
    [self fetchImageWithTransform:size];
//    [self fetchImageWithNoTransform: size];
}

- (void)buttonTapped3 {
    [self fetchImageWithNoTransform:_imageView.frame.size];
}

- (void)resetTapped {
    self.imageView.image = nil;
}

/// With Transform Handler
- (void)fetchImageWithTransform:(CGSize)targetSize {
    __weak typeof(self) _self = self;
    [self fetchImage:targetSize withTransform:^UIImage * _Nullable(YYImageType imageType, UIImage * _Nonnull image, NSURL * _Nonnull url) {
        __strong typeof(_self) self = _self;
        if (self) {
            image = [image yy_imageByResizeToSize:targetSize contentMode:UIViewContentModeScaleAspectFill];
            image = [image yy_imageByRoundCornerRadius:targetSize.width * 0.1 borderWidth:2.0 borderColor:[UIColor yellowColor]];
            return image;
        }
        return nil;
    }];
}

/// With None Transform Handler
- (void)fetchImageWithNoTransform:(CGSize)targetSize {
    [self fetchImage:targetSize withTransform:nil];
}

- (void)fetchImage:(CGSize)targetSize withTransform:(YYWebImageTransformBlock)transform {
    NSString *transformIdentifier = [NSString stringWithFormat:@"Transform%@", NSStringFromCGSize(targetSize)];
    YYWebImageItemOption *itemOption = [[YYWebImageItemOption alloc] init];
    itemOption.targetSize = targetSize;
    itemOption.transformIdentifier = transformIdentifier;
    
//    NSString *imageUrl = @"https://timgsa.baidu.com/timg?image&quality=80&size=b9999_10000&sec=1594293055688&di=6c790e2f4d899d2f9b68f242d5c29987&imgtype=0&src=http%3A%2F%2Ft8.baidu.com%2Fit%2Fu%3D2247852322%2C986532796%26fm%3D79%26app%3D86%26f%3DJPEG%3Fw%3D1280%26h%3D853";// jpg
    NSString *imageUrl = @"http://img.manhua.weibo.com/comic/23/71323/315749/001_315749_shard_1.webp";// webp
//    NSString *imageUrl = @"https://i.imgur.com/uoBwCLj.gif";// gif
    
    NSURL *url = [NSURL URLWithString:imageUrl];
    
    [_imageView yy_setImageWithURL:url
                          placeholder:nil
                          options:YYWebImageOptionShowNetworkActivity | YYWebImageOptionSetImageWithFadeAnimation | YYWebImageOptionAllowHitMemoryByDiskKeyWithValidTransform
                       itemOption:itemOption
                         progress:^(NSInteger receivedSize, NSInteger expectedSize) {
//                            NSLog(@"receivedSize is %ld, expectedSize is %ld", (long)receivedSize, (long)expectedSize);
                         }
                         transform: transform
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
