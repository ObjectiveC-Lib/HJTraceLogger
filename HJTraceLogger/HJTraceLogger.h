//
//  HJTraceLogger.h
//  HJTraceLogger
//
//  Created by navy on 2021/8/16.
//  Copyright © 2021 navy. All rights reserved.
//


#ifndef HJTraceLogger_h
#define HJTraceLogger_h

//! Project version number for HJTraceLogger.
FOUNDATION_EXPORT double HJTraceLoggerVersionNumber;

//! Project version string for HJTraceLogger.
FOUNDATION_EXPORT const unsigned char HJTraceLoggerVersionString[];

#if __has_include(<HJTraceLogger/HJTraceLogger.h>)

#import <HJTraceLogger/HJHTTPServerLogger.h>
#import <HJTraceLogger/HJTraceLoggerManager.h>

#else /* __has_include */

#import "HJHTTPServerLogger.h"
#import "HJTraceLoggerManager.h"

#endif /* __has_include */


#endif /* HJTraceLogger_h */
