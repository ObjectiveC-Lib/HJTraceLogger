//
//  HJMarsLogger.h
//  HJTraceLogger
//
//  Created by navy on 2022/7/11.
//  Copyright © 2022 navy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HJTraceLoggerPublic.h"

NS_ASSUME_NONNULL_BEGIN

@interface HJMarsLogger : NSObject

+ (void)setupLog:(BOOL)consoleLog
         logName:(nullable NSString *)logName
         logPath:(NSString *)logPath
          pubKey:(nullable NSString *)pubKey;

+ (void)closeLog;
+ (void)flushLog;

+ (void)logWrite:(NSString *)tag
           level:(TLLogLevel)level
        fileName:(NSString *)fileName
        funcName:(NSString *)funcName
      lineNumber:(NSInteger)lineNumber
         message:(NSString *)message;

@end

NS_ASSUME_NONNULL_END
