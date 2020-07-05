//
//  TaskManager.m
//  FTUIKit
//
//  Created by fltx on 2018/8/16.
//  Copyright © 2018年 www.apple.cn. All rights reserved.
//

#import "TaskManager.h"
#import "DispatchQueuePool.h"
#import "CustomOperation.h"
#import "TaskDefine.h"

@implementation TaskManager

+ (void)tasksInMainQueue:(nonnull NSArray <TaskBlock> *)tasks{
    if (FTArray(tasks).count < 1) {
        return;
    }
    for (TaskBlock block in tasks) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:block];
    }
}

+ (void)dependencyTasks:(nonnull NSArray <TaskBlock> *)blocks{
    if (FTArray(blocks).count < 1) {
        return;
    }
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    queue.name = @"com.ft.thread.manager.processing";
    queue.maxConcurrentOperationCount = 5;
    NSBlockOperation *previousOperation;
    for(TaskBlock block in blocks){
        NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock: block];
        if (previousOperation) {
            [operation addDependency:previousOperation];
        }
        previousOperation = operation;
        if (!operation.isFinished) {
            [queue addOperation:operation];
        }
    }
}

+ (void)groupTasks:(nonnull NSArray <TaskBlock> *)tasks completionHandler:(_Nullable TaskCompletionBlock)completionBlock{
    if (FTArray(tasks).count < 1) {
        return;
    }
    NSRecursiveLock *objectLock = [[NSRecursiveLock alloc] init];
    objectLock.name = [NSString stringWithFormat:@"%@%d",@"com.thread.ft.manager.lock",__LINE__];
    [objectLock lock];
    @scopeExit {
        [objectLock unlock];
    };
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    queue.name = @"com.ft.thread.manager.processing";
    queue.maxConcurrentOperationCount = 5;
    NSBlockOperation *lastOperation = [NSBlockOperation blockOperationWithBlock:^{
        !completionBlock ? : completionBlock();
    }];
    for(TaskBlock task in tasks){
        NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock: task];
        [queue addOperation:operation];
        [lastOperation addDependency:operation];
    }
    [queue addOperation:lastOperation];
}

+ (void)barrierTask:(nonnull NSArray <TaskBlock> *)tasks last:(_Nullable TaskBlock)lastTask completionHandler:(_Nullable TaskCompletionBlock)completionBlock{
    if (FTArray(tasks).count < 1) {
        return;
    }
    NSRecursiveLock *objectLock = [[NSRecursiveLock alloc] init];
    objectLock.name = [NSString stringWithFormat:@"%@%d",@"com.thread.ft.manager.lock",__LINE__];
    [objectLock lock];
    @scopeExit {
        [objectLock unlock];
    };
    dispatch_queue_t queue = dispatch_queue_create("com.ft.thread.manager.processing", DISPATCH_QUEUE_CONCURRENT);
    dispatch_async_limit(queue, 5, ^{
        for(TaskBlock task in tasks){
            task();
        }
    });
    //dispatch_barrier_async，该函数只能搭配自定义并行队列dispatch_queue_t使用 不能使用：dispatch_get_global_queue
    dispatch_barrier_async(queue, ^{
        !lastTask ? : lastTask();
        !completionBlock ? : completionBlock();
    });
}

+ (void)asyncOperationTasks:(nonnull NSArray <id<TaskProtocol>> *)tasks completionHandler:(_Nullable TaskCompletionBlock)completionBlock{
    if (FTArray(tasks).count < 1) {
        return;
    }
    NSRecursiveLock *objectLock = [[NSRecursiveLock alloc] init];
    objectLock.name = [NSString stringWithFormat:@"%@%d",@"com.thread.ft.manager.lock",__LINE__];
    [objectLock lock];
    @scopeExit {
        [objectLock unlock];
    };
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    queue.name = @"com.ft.thread.manager.processing";
    queue.maxConcurrentOperationCount = 5;
    NSBlockOperation *lastOperation = [NSBlockOperation blockOperationWithBlock:^{
        !completionBlock ? : completionBlock();
    }];
    
    for(id<TaskProtocol> task in tasks){
        CustomOperation *operation = [[CustomOperation alloc] initWithBlock: nil];
        if (!task.isSerial) {
            task.finishBlock = ^{
                [operation finishOperation];
            };
            [queue addOperation:operation];
            [lastOperation addDependency:operation];
        }else{
            [operation finishOperation];
        }
    }
    [queue addOperation:lastOperation];
}

+ (void)asyncTasks:(nonnull NSArray <id<TaskProtocol>> *)tasks completionHandler:(_Nullable TaskCompletionBlock)completionBlock{
    if (FTArray(tasks).count < 1) {
        return;
    }
    NSRecursiveLock *objectLock = [[NSRecursiveLock alloc] init];
    objectLock.name = [NSString stringWithFormat:@"%@%d",@"com.thread.ft.manager.lock",__LINE__];
    [objectLock lock];
    @scopeExit {
        [objectLock unlock];
    };
    dispatch_queue_t queue = dispatch_queue_create("com.ft.thread.manager.processing", DISPATCH_QUEUE_CONCURRENT);
    dispatch_group_t group = dispatch_group_create();
    for(id<TaskProtocol> task in tasks){
        if (!task.isSerial) {
            dispatch_group_enter(group);
        }
        dispatch_group_async(group, queue, ^{
            if (!task.isSerial) {
                task.finishBlock = ^{
                    dispatch_group_leave(group);
                };
            }
        });
    }
    //dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC);
    //dispatch_group_wait(group, time); Waits synchronously
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        !completionBlock ? : completionBlock();
    });
}

/// Global image queue, used for image reading and decoding.
+ (dispatch_queue_t)managerQueue {
#ifdef DispatchQueuePool_h
    return DispatchQueueGetForQOS(NSQualityOfServiceUtility);
#else
#define MAX_QUEUE_COUNT 16
    static int queueCount;
    static dispatch_queue_t queues[MAX_QUEUE_COUNT];
    static dispatch_once_t onceToken;
    static int32_t counter = 0;
    dispatch_once(&onceToken, ^{
        queueCount = (int)[NSProcessInfo processInfo].activeProcessorCount;
        queueCount = queueCount < 1 ? 1 : queueCount > MAX_QUEUE_COUNT ? MAX_QUEUE_COUNT : queueCount;
        if ([UIDevice currentDevice].systemVersion.floatValue >= 8.0) {
            for (NSUInteger i = 0; i < queueCount; i++) {
                dispatch_queue_attr_t attr = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_UTILITY, 0);
                queues[i] = dispatch_queue_create("com.thread.ft.manager.queue", attr);
            }
        } else {
            for (NSUInteger i = 0; i < queueCount; i++) {
                queues[i] = dispatch_queue_create("com.thread.ft.manager.queue", DISPATCH_QUEUE_SERIAL);
                dispatch_set_target_queue(queues[i], dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0));
            }
        }
    });
    int32_t cur = OSAtomicIncrement32(&counter);
    if (cur < 0) cur = -cur;
    return queues[(cur) % queueCount];
#undef MAX_QUEUE_COUNT
#endif
}


void dispatch_async_limit(__nonnull dispatch_queue_t concurrentQueue,NSUInteger limitSemaphoreCount, TaskCompletionBlock block) {
    //控制并发数的信号量
    static dispatch_semaphore_t limitSemaphore;
    //专门控制并发等待的线程
    static dispatch_queue_t receiverQueue;
    
    //使用 dispatch_once而非 lazy 模式，防止可能的多线程抢占问题
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        limitSemaphore = dispatch_semaphore_create(limitSemaphoreCount);
        receiverQueue = dispatch_queue_create("receiver", DISPATCH_QUEUE_SERIAL);
    });
    
    dispatch_async(receiverQueue, ^{
        dispatch_semaphore_wait(limitSemaphore, DISPATCH_TIME_FOREVER);
        dispatch_async(concurrentQueue, ^{
            !block ? : block();
            //release signal
            dispatch_semaphore_signal(limitSemaphore);
        });
    });
    
    dispatch_barrier_sync(receiverQueue, ^{
        !block ? : block();
    });
}

NSArray *FTArray(id obj){
    if (!isNSArray(obj) || ((NSArray *)obj).count == 0) {
        return @[];
    }
    return obj;
}

BOOL isNSArray(id obj)
{
    if(obj && [obj isKindOfClass:[NSArray class]])
        return YES;
    else
        return NO;
}

@end
