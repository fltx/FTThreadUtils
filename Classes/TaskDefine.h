//
//  TaskDefine.h
//  FTUIKit
//
//  Created by fltx on 2018/9/7.
//  Copyright © 2018年 Neo. All rights reserved.
//

#ifndef TaskDefine_h

typedef void (^cleanupBlock_t)(void);
static inline void executeCleanupBlock (__strong cleanupBlock_t * block) {
    (*block)();
}

/**
 * Returns A and B concatenated after full macro expansion.
 */
#define meta_join_(A, B) A ## B

#if DEBUG
#define keywordify autoreleasepool {}
#else
#define keywordify try {} @catch (...) {}
#endif

#define scopeExit \
keywordify \
__strong cleanupBlock_t meta_join_(ft_exitBlock_, __LINE__) __attribute__((cleanup(executeCleanupBlock), unused)) = ^


#define TaskDefine_h

#import "GCDHelper.h"

/**
 ThreadKit block
 */
typedef void (^TaskBlock)(void);
typedef void (^TaskCompletionBlock)(void);



/**
 TaskProtocol
 */
@protocol TaskProtocol <NSObject>

@required
@property (nonatomic, copy, nonnull) TaskBlock finishBlock;


/**
 Serial or Cocurrent
 */
@property (nonatomic, assign) BOOL isSerial;

@end

#endif /* TaskDefine_h */
