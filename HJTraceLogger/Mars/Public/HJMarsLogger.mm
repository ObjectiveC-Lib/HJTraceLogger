//
//  HJMarsLogger.m
//  HJTraceLogger
//
//  Created by navy on 2022/7/11.
//  Copyright © 2022 navy. All rights reserved.
//

#import "HJMarsLogger.h"
#import <sys/xattr.h>
#import <mars/xlog/xlogger.h>
#import <mars/xlog/xlogger_interface.h>
#import <mars/xlog/appender.h>
#import <mars/xlog/xloggerbase.h>

@implementation HJMarsLogger

+ (void)setupLog:(BOOL)consoleLog
         logName:(NSString *)logName
         logPath:(NSString *)logPath
          pubKey:(NSString *)pubKey {
    // set do not backup for logpath
    const char* attrName = "com.apple.MobileBackup";
    u_int8_t attrValue = 1;
    setxattr([logPath UTF8String], attrName, &attrValue, sizeof(attrValue), 0, 0);
    
    // init xlogger
    mars::xlog::appender_set_console_log(consoleLog);
#if DEBUG
    xlogger_SetLevel(kLevelDebug);
#else
    xlogger_SetLevel(kLevelInfo);
#endif
    
    mars::xlog::XLogConfig config;
    config.pub_key_ = [pubKey UTF8String];
    config.logdir_ = [logPath UTF8String];
    config.nameprefix_ = [logName UTF8String];
    config.cachedir_ = "";
    config.cache_days_ = 7;
    config.mode_ = mars::xlog::kAppenderAsync;
    config.compress_mode_ = mars::xlog::kZlib;
    config.compress_level_ = 6;
    mars::xlog::appender_open(config);
}

+ (void)closeLog {
    mars::xlog::appender_close();
}

+ (void)flushLog {
    mars::xlog::appender_flush();
}

+ (void)logWrite:(NSString *)tag
           level:(TLLogLevel)level
        fileName:(NSString *)fileName
        funcName:(NSString *)funcName
      lineNumber:(NSInteger)lineNumber
         message:(NSString *)message {
    message = [message stringByAppendingString:@"\n"];
    
    TLogLevel logLevel = kLevelNone;
    switch (level) {
        case TLLogLevel_Debug:
            logLevel = kLevelDebug;
            break;
        case TLLogLevel_Verbose:
            logLevel = kLevelVerbose;
            break;
        case TLLogLevel_Info:
            logLevel = kLevelInfo;
            break;
        case TLLogLevel_Warning:
            logLevel = kLevelWarn;
            break;
        case TLLogLevel_Error:
            logLevel = kLevelError;
            break;
        case TLLogLevel_Exception:
            logLevel = kLevelFatal;
            break;
        case TLLogLevel_Abort:
            logLevel = kLevelFatal;
            break;
        default:
            logLevel = kLevelNone;
            break;
    }
    
    XLoggerInfo info;
    info.level = logLevel;
    info.tag = [tag UTF8String];
    info.filename = [fileName UTF8String];
    info.func_name = [funcName UTF8String];
    info.line = lineNumber;
    gettimeofday(&info.timeval, NULL);
    info.tid = (uintptr_t)[NSThread currentThread];
    info.maintid = (uintptr_t)[NSThread mainThread];
    info.pid = getpid();
    xlogger_Write(&info, [message UTF8String]);
}

@end
