//
//  YYWebImageConstMacro.h
//  YYWebImageDemo
//
//  Created by emmet7life on 2020/7/8.
//  Copyright © 2020 ibireme. All rights reserved.
//

#ifndef YYWebImageConstMacro_h
#define YYWebImageConstMacro_h

UIKIT_EXTERN NSString *const kYYWebImageOptionImageType;             ///> The image format type.
UIKIT_EXTERN NSString *const kYYWebImageOptionTargetSize;            ///> The target size, unit is point, the value generally is UIImageView`s size.
UIKIT_EXTERN NSString *const kYYWebImageOptionTargetScale;           ///> The target scale, generally is UIScreen.mainScreen`s scale.
UIKIT_EXTERN NSString *const kYYWebImageOptionShouldDecode;          ///> Indicate should decode image or not.
UIKIT_EXTERN NSString *const kYYWebImageOptionBeProcessed;           ///> Indicate whether the image has been processed  or not by YYWebImageProcessor.
UIKIT_EXTERN NSString *const kYYWebImageOptionBeTransformed;         ///> Indicate whether the image has been transformed  or not by transform block.
UIKIT_EXTERN NSString *const kYYWebImageOptionTransformIdentifier;   ///> The transform`s identifer. similar with processor`s identifier.

#endif /* YYWebImageConstMacro_h */
