//
//  HJTraceLoggerManager.h
//  HJTraceLogger
//
//  Created by navy on 2021/8/16.
//  Copyright © 2021 navy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HJTraceLoggerPublic.h"
#import <XLFacility/XLFacilityMacros.h>

NS_ASSUME_NONNULL_BEGIN

@interface HJTraceLoggerManager : NSObject

// "application:didFinishLaunchingWithOptions:"
+ (void)setupLog:(nullable NSString *)logPath pubKey:(nullable NSString *)pubKey;

// "applicationWillTerminate:"
+ (void)flushLog;
+ (void)closeLog;

// helper
+ (BOOL)shouldLog:(TLLogLevel)level;
+ (void)logZipPath:(void (^ __nullable)(NSString *zipPath))completion;
+ (void)uploadLog:(UIViewController *)rootVC completion:(void (^ __nullable)(NSString *zipPath))completion;
@end


@interface HJTraceLoggerManager (Logging)

+ (void)logMessage:(NSString*)message
           withTag:(nullable NSString*)tag
             level:(TLLogLevel)level
           logFile:(BOOL)logFile
        logConsole:(BOOL)logConsole
          fileName:(NSString *)fileName
          funcName:(NSString *)funcName
        lineNumber:(NSInteger)lineNumber;

+ (void)logMessage:(NSString*)message
           withTag:(nullable NSString*)tag
             level:(TLLogLevel)level
           logFile:(BOOL)logFile
        logConsole:(BOOL)logConsole
          fileName:(NSString *)fileName
          funcName:(NSString *)funcName
        lineNumber:(NSInteger)lineNumber
          metadata:(nullable NSDictionary<NSString*, id>*)metadata;

+ (void)logMessageWithTag:(nullable NSString*)tag
                    level:(TLLogLevel)level
                  logFile:(BOOL)logFile
               logConsole:(BOOL)logConsole
                 fileName:(NSString *)fileName
                 funcName:(NSString *)funcName
               lineNumber:(NSInteger)lineNumber
                   format:(NSString*)format, ... NS_FORMAT_FUNCTION(8, 9);

+ (void)logMessageWithTag:(nullable NSString*)tag
                    level:(TLLogLevel)level
                  logFile:(BOOL)logFile
               logConsole:(BOOL)logConsole
                 fileName:(NSString *)fileName
                 funcName:(NSString *)funcName
               lineNumber:(NSInteger)lineNumber
                 metadata:(nullable NSDictionary<NSString*, id>*)metadata
                   format:(NSString*)format, ... NS_FORMAT_FUNCTION(9, 10);

+ (void)logException:(NSException*)exception
             withTag:(nullable NSString*)tag
             logFile:(BOOL)logFile
          logConsole:(BOOL)logConsole
            fileName:(NSString *)fileName
            funcName:(NSString *)funcName
          lineNumber:(NSInteger)lineNumber;

+ (void)logException:(NSException*)exception
             withTag:(nullable NSString*)tag
             logFile:(BOOL)logFile
          logConsole:(BOOL)logConsole
            fileName:(NSString *)fileName
            funcName:(NSString *)funcName
          lineNumber:(NSInteger)lineNumber
            metadata:(nullable NSDictionary<NSString*, id>*)metadata;

@end


NS_ASSUME_NONNULL_END
