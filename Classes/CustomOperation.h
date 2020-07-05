//
//  CustomOperation.h
//  FTUIKit
//
//  Created by fltx on 2018/8/15.
//  Copyright © 2018年 www.apple.cn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TaskDefine.h"

@protocol FTOperationProtocol <NSObject>

@optional
- (void)customOperationDidStart;
- (void)customOperationDidCancel;
- (void)customOperationDidFinish;

@end


@interface CustomOperation : NSOperation

@property (nonatomic,assign) BOOL shouldContinueWhenAppEntersBackground;
@property (nonatomic, weak) id<FTOperationProtocol> _Nullable delegate;

- (instancetype _Nonnull)init UNAVAILABLE_ATTRIBUTE;
+ (instancetype _Nonnull)new UNAVAILABLE_ATTRIBUTE;
- (instancetype _Nonnull)initWithBlock:(TaskBlock _Nullable)taskBlock;

- (void)finishOperation;

@end
