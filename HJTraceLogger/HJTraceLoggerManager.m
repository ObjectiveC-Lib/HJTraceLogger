//
//  HJTraceLoggerManager.m
//  HJTraceLogger
//
//  Created by navy on 2021/8/16.
//  Copyright © 2021 navy. All rights reserved.
//

#import "HJTraceLoggerManager.h"
#import <XLFacility/XLFacility.h>
#import <XLFacility/XLFacilityMacros.h>
#import <XLFacility/XLStandardLogger.h>
#import "HJHTTPServerLogger.h"

@interface HJTraceLoggerManager ()
@property (nonatomic, strong) HJHTTPServerLogger *httpServerLogger;
@end

@implementation HJTraceLoggerManager

+ (nonnull instancetype)sharedInstance {
    static dispatch_once_t once;
    static id instance;
    if ([NSThread isMainThread]) {
        dispatch_once(&once, ^{
            instance = [[self alloc] init];
        });
    } else {
        dispatch_sync(dispatch_get_main_queue(), ^{
            dispatch_once(&once, ^{
                instance = [[self alloc] init];
            });
        });
    }
    return instance;
}

- (instancetype)init {
    if(self = [super init]) {
    }
    return self;
}

+ (void)start {
    [[HJTraceLoggerManager sharedInstance] startServer];
}

+ (void)stop {
    [[HJTraceLoggerManager sharedInstance] stopServer];
}

- (HJHTTPServerLogger *)httpServerLogger {
    if (!_httpServerLogger) {
        _httpServerLogger = [[HJHTTPServerLogger alloc] initWithPort:8080];
        _httpServerLogger.format = @"<td>%d %P[%p:%r] %m%c</td>";
    }
    return _httpServerLogger;
}

- (void)startServer {
    [[XLStandardLogger sharedOutputLogger] setFormat:XLLoggerFormatString_NSLog];
    [[XLStandardLogger sharedErrorLogger] setFormat:XLLoggerFormatString_NSLog];
    [XLSharedFacility addLogger:[HJTraceLoggerManager sharedInstance].httpServerLogger];
    XLSharedFacility.minLogLevel = kXLLogLevel_Info;
    XLOG_INFO(@"[HJTraceLogger] 请在您的 PC 浏览器中打开 http://%@:%lu 浏览日志。", GCDTCPServerGetPrimaryIPAddress(false),(unsigned long)[HJTraceLoggerManager sharedInstance].httpServerLogger.TCPServer.port);
}

- (void)stopServer {
    @try {
        if(_httpServerLogger) {
            NSLog(@"[HJTraceLogger] 日志跟踪服务已停止。");
            [_httpServerLogger close];
        }
    } @catch (NSException *exception) {
        NSLog(@"[HJTraceLogger] 停止日志跟踪服务发生异常:【%@】%@, 原因:%@。", exception.name, exception.description, exception.reason);
    } @finally {
        _httpServerLogger = nil;
    }
}

@end
