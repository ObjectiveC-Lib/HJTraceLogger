#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "HJTraceLogger.h"
#import "HJHTTPServerLogger.h"
#import "HJTraceLogger.h"
#import "HJTraceLoggerManager.h"

FOUNDATION_EXPORT double HJTraceLoggerVersionNumber;
FOUNDATION_EXPORT const unsigned char HJTraceLoggerVersionString[];

