//
//  HJTraceLoggerManager.m
//  HJTraceLogger
//
//  Created by navy on 2021/8/16.
//  Copyright © 2021 navy. All rights reserved.
//

#import "HJTraceLoggerManager.h"
#import "HJTraceLoggerServer.h"
#import "HJMarsLogger.h"
#import "HJTraceLoggerMacros.h""
#import <XLFacility/XLFacilityMacros.h>
#import <XLFacility/XLFacility.h>
#import <XLFacility/XLStandardLogger.h>
#import <XLFacility/XLUIKitOverlayLogger.h>
#import <XLFacility/XLCallbackLogger.h>
#import <SSZipArchive/SSZipArchive.h>

static NSString *_logPath = nil;
const NSString *HJLoggerFormatString_NSLog = @"%d %P[%p:%r][%l][%g] %m";
const NSString *HJLoggerFormatString_Server = @"[%d] %m";

@interface HJTraceLoggerManager ()
@property (nonatomic, strong) HJTraceLoggerServer *httpServerLogger;
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
    if (self = [super init]) {
        _logPath = [self.class logPath];
    }
    return self;
}

+ (void)setupLog:(NSString *)logPath pubKey:(NSString *)pubKey {
    [[HJTraceLoggerManager sharedInstance] setupLog:logPath pubKey:pubKey];
    TLogFile(@"您正在使用 HJTraceLogger 日志服务!");
}

+ (void)flushLog {
    [[HJTraceLoggerManager sharedInstance] flushLog];
}

+ (void)closeLog {
    [[HJTraceLoggerManager sharedInstance] closeLog];
}

+ (BOOL)shouldLog:(TLLogLevel)level {
    return [[HJTraceLoggerManager sharedInstance] shouldLog:level];
}

+ (void)uploadLog:(UIViewController *)rootVC completion:(void (^)(NSString *zipPath))completion {
    [[HJTraceLoggerManager sharedInstance] uploadLog:rootVC completion:completion];
}

+ (void)logZipPath:(void (^)(NSString *zipPath))completion {
    [[HJTraceLoggerManager sharedInstance] logZipPath:completion];
}

- (void)setupLog:(NSString *)logPath pubKey:(NSString *)pubKey {
    if (logPath && logPath.length > 0) {
        _logPath = logPath;
    }
    
    // XLFacility
    [[XLStandardLogger sharedOutputLogger] setFormat:HJLoggerFormatString_NSLog];
    [[XLStandardLogger sharedErrorLogger] setFormat:HJLoggerFormatString_NSLog];
#if DEBUG
    XLSharedFacility.minLogLevel = TLLogLevel_Info;
#else
    XLSharedFacility.minLogLevel = TLLogLevel_Info;
#endif
    //    [XLSharedFacility addLogger:[XLUIKitOverlayLogger sharedLogger]];
    //    [XLSharedFacility addLogger:[XLCallbackLogger loggerWithCallback:^(XLCallbackLogger *logger,
    //                                                                       XLLogRecord *record) {
    //        // Do something with the log record
    //         printf("%s\n", [record.message UTF8String]);
    //    }]];
    [[HJTraceLoggerManager sharedInstance] startServer];
    
    // Mars
    [HJMarsLogger setupLog:NO
                   logName:@"tl_xlog"
                   logPath:_logPath
                    pubKey:pubKey];
}

- (void)flushLog {
    [HJMarsLogger flushLog];
}

- (void)closeLog {
    [[HJTraceLoggerManager sharedInstance] stopServer];
    [HJMarsLogger closeLog];
}

- (void)startServer {
#if DEBUG
    [XLSharedFacility addLogger:[HJTraceLoggerManager sharedInstance].httpServerLogger];
    TLog(@"[HJTraceLogger] 请在您的 PC 浏览器中打开 http://%@:%lu 浏览日志。",
         GCDTCPServerGetPrimaryIPAddress(false),
         (unsigned long)[HJTraceLoggerManager sharedInstance].httpServerLogger.TCPServer.port);
#endif
}

- (void)stopServer {
#if DEBUG
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
#endif
}

- (BOOL)shouldLog:(TLLogLevel)level {
    return (XLSharedFacility.minLogLevel <= level);
}

- (void)uploadLog:(UIViewController *)rootVC completion:(void (^)(NSString *zipPath))completion {
    [self logZipPath:^(NSString *zipPath) {
        if (completion) {
            completion(zipPath);
        }
        if (zipPath && rootVC) {
            NSURL *url = [NSURL fileURLWithPath:zipPath];
            UIActivityViewController *controller = [[UIActivityViewController alloc] initWithActivityItems:@[url]
                                                                                     applicationActivities:nil];
            if ([(NSString *)[UIDevice currentDevice].model hasPrefix:@"iPad"]) {
                controller.popoverPresentationController.sourceView = rootVC.view;
                controller.popoverPresentationController.sourceRect = CGRectMake([UIScreen mainScreen].bounds.size.width * 0.5,
                                                                                 [UIScreen mainScreen].bounds.size.height,
                                                                                 10,
                                                                                 10);
            }
            [rootVC presentViewController:controller
                                 animated:YES
                               completion:nil];
            
            
        }
    }];
}

- (void)logZipPath:(void (^)(NSString *zipPath))completion {
    NSDateFormatter *formatter = [NSDateFormatter new];
    formatter.dateFormat = @"YYYY_MM-dd_HH-mm";
    NSString *logName = [NSString stringWithFormat:@"tl_xlog_%@.zip", [formatter stringFromDate:NSDate.date]];
    NSString *zipPath = [NSTemporaryDirectory() stringByAppendingPathComponent:logName];
    if ([NSFileManager.defaultManager fileExistsAtPath:zipPath]) {
        NSError *error;
        [NSFileManager.defaultManager removeItemAtPath:zipPath error:&error];
        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) {
                    completion(nil);
                }
                return;
            });
        }
    }
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        BOOL result = [SSZipArchive createZipFileAtPath:zipPath withContentsOfDirectory:_logPath];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(result?zipPath:nil);
            }
        });
    });
}

- (HJTraceLoggerServer *)httpServerLogger {
    if (!_httpServerLogger) {
        _httpServerLogger = [[HJTraceLoggerServer alloc] initWithPort:8080];
        _httpServerLogger.format = [NSString stringWithFormat:@"<td>%@</td>", HJLoggerFormatString_Server];
    }
    return _httpServerLogger;
}

+ (NSString *)logPath {
    static NSString *path = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        path = [[self documentsPath] stringByAppendingPathComponent:@"XLog"];
        NSError *error = nil;
        if (![[NSFileManager defaultManager] createDirectoryAtPath:path
                                       withIntermediateDirectories:YES
                                                        attributes:nil
                                                             error:&error]) {
        }
    });
    return path;
}

+ (NSString *)documentsPath {
    static NSString *path = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSArray *array = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        if (array.count) {
            path = array.firstObject;
        }
    });
    return path;
}

@end


@implementation HJTraceLoggerManager (Logging)

+ (void)logMessage:(NSString *)message
           withTag:(NSString *)tag
             level:(TLLogLevel)level
           logFile:(BOOL)logFile
        logConsole:(BOOL)logConsole
          fileName:(NSString *)fileName
          funcName:(NSString *)funcName
        lineNumber:(NSInteger)lineNumber {
    [self logMessage:message
             withTag:tag
               level:level
             logFile:logFile
          logConsole:logConsole
            fileName:fileName
            funcName:funcName
          lineNumber:lineNumber
            metadata:nil];
}

+ (void)logMessage:(NSString *)message
           withTag:(NSString *)tag
             level:(TLLogLevel)level
           logFile:(BOOL)logFile
        logConsole:(BOOL)logConsole
          fileName:(NSString *)fileName
          funcName:(NSString *)funcName
        lineNumber:(NSInteger)lineNumber
          metadata:(NSDictionary<NSString*, id>*)metadata {
    if (logConsole) {
        [XLSharedFacility logMessage:message withTag:tag level:level metadata:metadata];
    }
    
    if (logFile) {
        [HJMarsLogger logWrite:@""
                         level:level
                      fileName:fileName
                      funcName:funcName
                    lineNumber:lineNumber
                       message:message];
    }
}

+ (void)logMessageWithTag:(NSString *)tag
                    level:(TLLogLevel)level
                  logFile:(BOOL)logFile
               logConsole:(BOOL)logConsole
                 fileName:(NSString *)fileName
                 funcName:(NSString *)funcName
               lineNumber:(NSInteger)lineNumber
                   format:(NSString *)format, ... {
    [self logMessageWithTag:tag
                      level:level
                    logFile:logFile
                 logConsole:logConsole
                   fileName:fileName
                   funcName:funcName
                 lineNumber:lineNumber
                   metadata:nil
                     format:format];
}

+ (void)logMessageWithTag:(NSString *)tag
                    level:(TLLogLevel)level
                  logFile:(BOOL)logFile
               logConsole:(BOOL)logConsole
                 metadata:(NSDictionary<NSString*, id>*)metadata
                 fileName:(NSString *)fileName
                 funcName:(NSString *)funcName
               lineNumber:(NSInteger)lineNumber
                   format:(NSString *)format, ... {
    if (logConsole) {
        [XLSharedFacility logMessageWithTag:tag level:level metadata:metadata format:format];
    }
    
    if (logFile) {
        va_list arguments;
        va_start(arguments, format);
        NSString *message = [[NSString alloc] initWithFormat:format arguments:arguments];
        va_end(arguments);
        [HJMarsLogger logWrite:@""
                         level:level
                      fileName:fileName
                      funcName:funcName
                    lineNumber:lineNumber
                       message:message];
    }
}

+ (void)logException:(NSException *)exception
             withTag:(NSString *)tag
             logFile:(BOOL)logFile
          logConsole:(BOOL)logConsole
            fileName:(NSString *)fileName
            funcName:(NSString *)funcName
          lineNumber:(NSInteger)lineNumber {
    [self logException:exception
               withTag:tag
               logFile:logFile
            logConsole:logConsole
              fileName:fileName
              funcName:funcName
            lineNumber:lineNumber
              metadata:nil];
}

+ (void)logException:(NSException *)exception
             withTag:(NSString *)tag
             logFile:(BOOL)logFile
          logConsole:(BOOL)logConsole
            fileName:(NSString *)fileName
            funcName:(NSString *)funcName
          lineNumber:(NSInteger)lineNumber
            metadata:(NSDictionary<NSString*, id>*)metadata {
    if (logConsole) {
        [XLSharedFacility logException:exception withTag:tag metadata:metadata];
    }
    
    if (logFile) {
        NSString *message = [NSString stringWithFormat:@"%@ %@", exception.name, exception.reason];
        [HJMarsLogger logWrite:@""
                         level:TLLogLevel_Exception
                      fileName:fileName
                      funcName:funcName
                    lineNumber:lineNumber
                       message:message];
    }
}

@end
