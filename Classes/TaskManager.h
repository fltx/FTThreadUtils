//
//  TaskManager.h
//  FTUIKit
//
//  Created by fltx on 2018/8/16.
//  Copyright © 2018年 www.apple.cn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TaskDefine.h"

#define scopeExit \
keywordify \
__strong cleanupBlock_t meta_join_(ft_exitBlock_, __LINE__) __attribute__((cleanup(executeCleanupBlock), unused)) = ^

@interface TaskManager : NSObject

+ (void)tasksInMainQueue:(nonnull NSArray <TaskBlock> *)tasks;

+ (void)dependencyTasks:(nonnull NSArray <TaskBlock> *)blocks;

+ (void)barrierTask:(nonnull NSArray <TaskBlock> *)tasks last:(_Nullable TaskBlock)lastTask completionHandler:(_Nullable TaskCompletionBlock)completionBlock;

+ (void)groupTasks:(nonnull NSArray <TaskBlock> *)tasks completionHandler:(_Nullable TaskCompletionBlock)completionBlock;

+ (void)asyncOperationTasks:(nonnull NSArray <id<TaskProtocol>> *)tasks completionHandler:(_Nullable TaskCompletionBlock)completionBlock;

+ (void)asyncTasks:(nonnull NSArray <id<TaskProtocol>> *)tasks completionHandler:(_Nullable TaskCompletionBlock)completionBlock;

@end
