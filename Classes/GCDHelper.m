//
//  GCD.m
//  XMWeekly
//
//  Created by fltx on 15/7/3.
//  Copyright (c) 2015年 XM. All rights reserved.
//

#import "GCDHelper.h"
@implementation GCDHelper

inline void onMain(dispatch_block_t block)
{
    if ([NSThread isMainThread]) {
        block();
    } else {
        dispatch_sync(dispatch_get_main_queue(), block);
    }
}

inline void asyncOnMain(dispatch_block_t block)
{
    dispatch_queue_t queue = dispatch_get_main_queue();
    dispatch_async(queue, block);
}

inline void onHigh(dispatch_block_t block)
{
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    dispatch_async(queue, block);
}

inline void onDefault(dispatch_block_t block)
{
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, block);
}

inline void onBackground(dispatch_block_t block)
{
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    dispatch_async(queue, block);
}

inline void onMyQueue(NSString *queueName, dispatch_block_t block)
{
    const char * cQueueName = [queueName UTF8String];
    dispatch_queue_t queue = dispatch_queue_create(cQueueName, 0);
    dispatch_async(queue, block);
}

inline void onDelay(double delaySeconds, dispatch_block_t block)
{
    dispatch_time_t delayTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delaySeconds * NSEC_PER_SEC));
    dispatch_after(delayTime, dispatch_get_main_queue(), block);
}
                   
inline void onDelayInQueue(double delaySeconds,dispatch_queue_t queue, dispatch_block_t block)
{
    dispatch_time_t delayTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delaySeconds * NSEC_PER_SEC));
    dispatch_after(delayTime, queue, block);
}

@end
