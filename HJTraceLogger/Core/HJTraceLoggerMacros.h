//
//  HJTraceLoggerMacros.h
//  HJTraceLogger
//
//  Created by navy on 2022/7/13.
//  Copyright © 2022 navy. All rights reserved.
//

#ifndef HJTraceLoggerMacros_h
#define HJTraceLoggerMacros_h

#import "HJTraceLoggerManager.h"

#define __FILENAME__ (strrchr(__FILE__,'/')+1)

#ifndef TLLOG_TAG
#define TLLOG_STRINGIFY(x) #x
#define TLLOG_STRINGIFY_(x) TLLOG_STRINGIFY(x)
#define TLLOG_LINE TLLOG_STRINGIFY_(__LINE__)
//#define TLLOG_TAG nil
//#define TLLOG_TAG (@__FILE__ ":" TLLOG_LINE)
#define TLLOG_TAG ([NSString stringWithFormat:@"%s:%d, %s", __FILENAME__, __LINE__, __FUNCTION__])
#endif

#define TLLOG_TO_FILE (YES)
#define TLLOG_NO_TO_FILE (NO)

#define TLLOG_INTERNAL(tag, logLevel, toFile, format, ...) \
do { \
    NSString *message = [NSString stringWithFormat:@"%@", [NSString stringWithFormat:format, ##__VA_ARGS__, nil]]; \
    if ([HJTraceLoggerManager shouldLog:logLevel]) { \
        [HJTraceLoggerManager logMessage:message \
                                 withTag:tag \
                                   level:logLevel \
                                 logFile:toFile \
                                fileName:[NSString stringWithFormat:@"%s", __FILENAME__]  \
                                funcName:[NSString stringWithFormat:@"%s", __FUNCTION__]  \
                              lineNumber:__LINE__]; \
    } \
} while (0)

#define TLLOG_INTERNAL_EXCEPTION(tag, toFile, __EXCEPTION__) \
do { \
    if ([HJTraceLoggerManager shouldLog:TLLogLevel_Exception]) { \
        [HJTraceLoggerManager logException:__EXCEPTION__ \
                                   withTag:tag \
                                   logFile:toFile \
                                  fileName:[NSString stringWithFormat:@"%s", __FILENAME__] \
                                  funcName:[NSString stringWithFormat:@"%s", __FUNCTION__] \
                                lineNumber:__LINE__]; \
    } \
} while (0)

#if DEBUG
#define TLLOG_DEBUG(tag, toFile, format, ...) TLLOG_INTERNAL(tag, TLLogLevel_Debug, toFile, format, ##__VA_ARGS__)
#else
#define TLLOG_DEBUG(...)
#endif
#define TLLOG_VERBOSE(tag, toFile, format, ...) TLLOG_INTERNAL(tag, TLLogLevel_Verbose, toFile, format, ##__VA_ARGS__)
#define TLLOG_INFO(tag, toFile, format, ...) TLLOG_INTERNAL(tag, TLLogLevel_Info, toFile, format, ##__VA_ARGS__)
#define TLLOG_WARNING(tag, toFile, format, ...) TLLOG_INTERNAL(tag, TLLogLevel_Warning, toFile, format, ##__VA_ARGS__)
#define TLLOG_ERROR(tag, toFile, format, ...) TLLOG_INTERNAL(tag, TLLogLevel_Error, toFile, format, ##__VA_ARGS__)
#define TLLOG_EXCEPTION(tag, toFile, __EXCEPTION__) TLLOG_INTERNAL_EXCEPTION(tag, toFile, __EXCEPTION__)
#define TLLOG_ABORT(tag, toFile, format, ...) TLLOG_INTERNAL(tag, TLLogLevel_Abort, toFile, format, ##__VA_ARGS__)

#define TLog_DEBUG(format, ...) TLLOG_DEBUG(TLLOG_TAG, TLLOG_NO_TO_FILE, (@"\n⚡️⚡️⚡️⚡️⚡️⚡️\n" format "\n⚡️⚡️⚡️⚡️⚡️⚡️\n"), ##__VA_ARGS__)
#define TLog(format, ...) TLLOG_INFO(TLLOG_TAG, TLLOG_NO_TO_FILE, (@"\n🔻🔻🔻🔻🔻🔻\n" format "\n🔺🔺🔺🔺🔺🔺\n"), ##__VA_ARGS__)
#define TLog_WARNING(format, ...) TLLOG_WARNING(TLLOG_TAG, TLLOG_NO_TO_FILE, (@"\n⚠️⚠️⚠️⚠️⚠️⚠️\n" format "\n⚠️⚠️⚠️⚠️⚠️⚠️\n"), ##__VA_ARGS__)
#define TLog_ERROR(format, ...) TLLOG_ERROR(TLLOG_TAG, TLLOG_NO_TO_FILE, (@"\n💔💔💔💔💔💔\n" format "\n💔💔💔💔💔💔\n"), ##__VA_ARGS__)
#define TLog_EXCEPTION(__EXCEPTION__) TLLOG_EXCEPTION(TLLOG_TAG, TLLOG_NO_TO_FILE, __EXCEPTION__)
#define TLog_ABORT(format, ...) TLLOG_ABORT(TLLOG_TAG, TLLOG_NO_TO_FILE, (@"\n💔💔💔💔💔💔\n" format "\n💔💔💔💔💔💔\n"), ##__VA_ARGS__)

#define TLogFile_DEBUG(format, ...) TLLOG_DEBUG(TLLOG_TAG, TLLOG_TO_FILE, (@"\n⚡️⚡️⚡️⚡️⚡️⚡️\n" format "\n⚡️⚡️⚡️⚡️⚡️⚡️\n"), ##__VA_ARGS__)
#define TLogFile(format, ...) TLLOG_INFO(TLLOG_TAG, TLLOG_TO_FILE, (@"\n🔻🔻🔻🔻🔻🔻\n" format "\n🔺🔺🔺🔺🔺🔺\n"), ##__VA_ARGS__)
#define TLogFile_WARNING(format, ...) TLLOG_WARNING(TLLOG_TAG, TLLOG_TO_FILE, (@"\n⚠️⚠️⚠️⚠️⚠️⚠️\n" format "\n⚠️⚠️⚠️⚠️⚠️⚠️\n"), ##__VA_ARGS__)
#define TLogFile_ERROR(format, ...) TLLOG_ERROR(TLLOG_TAG, TLLOG_TO_FILE, (@"\n💔💔💔💔💔💔\n" format "\n💔💔💔💔💔💔\n"), ##__VA_ARGS__)
#define TLogFile_EXCEPTION(__EXCEPTION__) TLLOG_EXCEPTION(TLLOG_TAG, TLLOG_TO_FILE, __EXCEPTION__)
#define TLogFile_ABORT(format, ...) TLLOG_ABORT(TLLOG_TAG, TLLOG_TO_FILE, (@"\n💔💔💔💔💔💔\n" format "\n💔💔💔💔💔💔\n"), ##__VA_ARGS__)

/**
 *  These other macros let you easily check conditions inside your code and
 *  log messages with XLFacility on failure.
 *  You can use them instead of assert() or NSAssert().
 */
#define TLLOG_CHECK(__CONDITION__)                              \
  do {                                                          \
    if (!(__CONDITION__)) {                                     \
      TLLOG_ABORT(@"Condition failed: \"%s\"", #__CONDITION__); \
    }                                                           \
  } while (0)

#define TLLOG_UNREACHABLE()                                                                          \
  do {                                                                                               \
    TLLOG_ABORT(@"Unreachable code executed in '%s': %s:%i", __FUNCTION__, __FILE__, (int)__LINE__); \
  } while (0)

#if DEBUG
#define TLLOG_DEBUG_CHECK(__CONDITION__) TLLOG_CHECK(__CONDITION__)
#define TLLOG_DEBUG_UNREACHABLE() TLLOG_UNREACHABLE()
#else
#define TLLOG_DEBUG_CHECK(__CONDITION__)
#define TLLOG_DEBUG_UNREACHABLE()
#endif

#endif /* HJTraceLoggerMacros_h */
