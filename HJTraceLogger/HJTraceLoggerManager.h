//
//  HJTraceLoggerManager.h
//  HJTraceLogger
//
//  Created by navy on 2021/8/16.
//  Copyright © 2021 navy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XLFacility/XLFacilityMacros.h>

NS_ASSUME_NONNULL_BEGIN

@interface HJTraceLoggerManager : NSObject

/// 启动服务器
+ (void)start;

/// 停止服务器
+ (void)stop;

@end

NS_ASSUME_NONNULL_END
