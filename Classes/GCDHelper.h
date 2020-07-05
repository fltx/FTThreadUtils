//
//  GCD.h
//  XMWeekly
//
//  Created by fltx on 15/7/3.
//  Copyright (c) 2015年 XM. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GCDHelper : NSObject

inline void onMain(dispatch_block_t block);

inline void asyncOnMain(dispatch_block_t block);

extern void onHigh(dispatch_block_t block);

extern void onDefault(dispatch_block_t block);

extern void onBackground(dispatch_block_t block);

extern void onMyQueue(NSString *queueName, dispatch_block_t block);

extern void onDelay(double delaySeconds, dispatch_block_t block);

extern void onDelayInQueue(double delaySeconds,dispatch_queue_t queue, dispatch_block_t block);


@end
