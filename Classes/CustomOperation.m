
//
//  CustomOperation.m
//  FTUIKit
//
//  Created by fltx on 2018/8/15.
//  Copyright © 2018年 www.apple.cn. All rights reserved.
//

#import "CustomOperation.h"
#import <UIKit/UIKit.h>
#import "TaskDefine.h"

@interface CustomOperation()

@property (readwrite, getter=isExecuting) BOOL executing;
@property (readwrite, getter=isFinished) BOOL finished;
@property (readwrite, getter=isCancelled) BOOL cancelled;
@property (readwrite, getter=isStarted) BOOL started;
@property (nonatomic, strong) NSRecursiveLock *lock;
@property (nonatomic, assign) UIBackgroundTaskIdentifier backgroundTaskId;
@property (nonatomic, copy) TaskBlock taskBlock;
@property (nonatomic, copy) TaskCompletionBlock completion;

@end

@implementation CustomOperation
@synthesize executing = _executing;
@synthesize finished = _finished;
@synthesize cancelled = _cancelled;

- (instancetype)initWithBlock:(TaskBlock _Nullable)taskBlock{
    if (self = [super init]) {
        _executing = NO;
        _finished = NO;
        _cancelled = NO;
        _backgroundTaskId = UIBackgroundTaskInvalid;
        _lock = [NSRecursiveLock new];
        _taskBlock = taskBlock;
    }
    return self;
}

- (void)dealloc {
    [_lock lock];
    [self _endBackgroundTask];
    if ([self isExecuting]) {
        self.cancelled = YES;
        self.finished = YES;
        if (_completion) {
            @autoreleasepool {
                _completion();
            }
        }
    }
    [_lock unlock];
}

- (void)_endBackgroundTask{
    if (!self.shouldContinueWhenAppEntersBackground) {
        return;
    }
    Class UIApplicationClass = NSClassFromString(@"UIApplication");
    if(!UIApplicationClass || ![UIApplicationClass respondsToSelector:@selector(sharedApplication)]) {
        return;
    }
    [_lock lock];
    if (self.backgroundTaskId != UIBackgroundTaskInvalid) {
        UIApplication *app = [UIApplication performSelector:@selector(sharedApplication)];
        [app endBackgroundTask:self.backgroundTaskId];
        self.backgroundTaskId = UIBackgroundTaskInvalid;
    }
    [_lock unlock];
}

- (void)_startBackgroundTask{
    Class UIApplicationClass = NSClassFromString(@"UIApplication");
    BOOL hasApplication = UIApplicationClass && [UIApplicationClass respondsToSelector:@selector(sharedApplication)];
    if (hasApplication && [self shouldContinueWhenAppEntersBackground]) {
        __weak __typeof__ (self) _self = self;
        UIApplication * app = [UIApplicationClass performSelector:@selector(sharedApplication)];
        self.backgroundTaskId = [app beginBackgroundTaskWithExpirationHandler:^{
            __strong __typeof (_self) self = _self;
            if (self) {
                [self cancel];
                self.finished = YES;
                [app endBackgroundTask:self.backgroundTaskId];
                self.backgroundTaskId = UIBackgroundTaskInvalid;
            }
        }];
    }
}

#pragma mark - Runs in operation thread

// execute task
- (void)_startOperation{
    if ([self isCancelled]) return;
    @autoreleasepool {
        if ([self.delegate respondsToSelector:@selector(customOperationDidStart)]) {
            [self.delegate customOperationDidStart];
        }
        if (self.taskBlock) {
            self.taskBlock();
        }
    }
}

// runs on network thread, called from outer "cancel"
- (void)_cancelOperation {
    @autoreleasepool {
        if (_completion) {
            _completion();
        }
        [self _endBackgroundTask];
    }
}

- (void)finishOperation{
    self.executing = NO;
    self.finished = YES;
    [self _endBackgroundTask];
}

#pragma mark - Override NSOperation
//concurrent 实现start方法
//none-concurrent 实现main方法
- (void)start {
    @autoreleasepool {
        [_lock lock];
        self.started = YES;
        if ([self isCancelled]) {
            [self performSelector:@selector(_cancelOperation) onThread:[NSThread currentThread] withObject:nil waitUntilDone:NO modes:@[NSDefaultRunLoopMode]];
            self.finished = YES;
        }else if ([self isReady] && ![self isFinished] && ![self isExecuting]) {
            self.executing = YES;
            [self performSelector:@selector(_startOperation) onThread:[NSThread currentThread] withObject:nil waitUntilDone:NO modes:@[NSDefaultRunLoopMode]];
            if (self.shouldContinueWhenAppEntersBackground) {
                [self _startBackgroundTask];
            }
        }
        [_lock unlock];
    }
}

- (void)cancel {
    if ([self.delegate respondsToSelector:@selector(customOperationDidCancel)]) {
        [self.delegate customOperationDidCancel];
    }
    [_lock lock];
    if (![self isCancelled]) {
        [super cancel];
        self.cancelled = YES;
        if ([self isExecuting]) {
            self.executing = NO;
            [self performSelector:@selector(_cancelOperation) onThread:[NSThread currentThread] withObject:nil waitUntilDone:NO modes:@[NSDefaultRunLoopMode]];
        }
        if (self.started) {
            self.finished = YES;
        }
    }
    [_lock unlock];
}

- (void)setExecuting:(BOOL)executing {
    [_lock lock];
    if (_executing != executing) {
        [self willChangeValueForKey:@"isExecuting"];
        _executing = executing;
        [self didChangeValueForKey:@"isExecuting"];
    }
    [_lock unlock];
}

- (BOOL)isExecuting {
    [_lock lock];
    BOOL executing = _executing;
    [_lock unlock];
    return executing;
}

- (void)setFinished:(BOOL)finished {
    if ([self.delegate respondsToSelector:@selector(customOperationDidFinish)]) {
        [self.delegate customOperationDidFinish];
    }
    [_lock lock];
    if (_finished != finished) {
        [self willChangeValueForKey:@"isFinished"];
        _finished = finished;
        [self didChangeValueForKey:@"isFinished"];
    }
    [_lock unlock];
}

- (BOOL)isFinished {
    [_lock lock];
    BOOL finished = _finished;
    [_lock unlock];
    return finished;
}

- (void)setCancelled:(BOOL)cancelled {
    [_lock lock];
    if (_cancelled != cancelled) {
        [self willChangeValueForKey:@"isCancelled"];
        _cancelled = cancelled;
        [self didChangeValueForKey:@"isCancelled"];
    }
    [_lock unlock];
}

- (BOOL)isCancelled {
    [_lock lock];
    BOOL cancelled = _cancelled;
    [_lock unlock];
    return cancelled;
}

- (BOOL)isConcurrent {
    return YES;
}

- (BOOL)isAsynchronous {
    return YES;
}

+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)key {
    if ([key isEqualToString:@"isExecuting"] ||
        [key isEqualToString:@"isFinished"] ||
        [key isEqualToString:@"isCancelled"]) {
        return NO;
    }
    return [super automaticallyNotifiesObserversForKey:key];
}

@end
