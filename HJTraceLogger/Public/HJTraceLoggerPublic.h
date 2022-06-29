//
//  HJTraceLoggerPublic.h
//  HJTraceLogger
//
//  Created by navy on 2022/7/13.
//

#ifndef HJTraceLoggerPublic_h
#define HJTraceLoggerPublic_h

typedef NS_ENUM(int, TLLogLevel) {
    TLLogLevel_Debug = 0,
    TLLogLevel_Verbose,
    TLLogLevel_Info,
    TLLogLevel_Warning,
    TLLogLevel_Error,
    TLLogLevel_Exception,
    TLLogLevel_Abort,
    TLMinLogLevel = TLLogLevel_Debug,
    TLMaxLogLevel = TLLogLevel_Abort,
    TLMuteLogLevel = INT_MAX
};

#endif /* HJTraceLoggerPublic_h */
