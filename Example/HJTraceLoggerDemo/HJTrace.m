//
//  HJTrace.m
//  HJTraceLogger
//
//  Created by navy on 2023/10/25.
//

#import "HJTrace.h"
#import "HJTraceLoggerMacros.h"
//#import <HJTraceLogger/HJTraceLogger.h>

void TTLog(NSString *formate, ...) {
    va_list args;
    
    va_start(args, formate);
    
    NSString *msg = [[NSString alloc] initWithFormat:formate arguments:args];
    
    TLog(@"%@", msg);
    
    va_end(args);
}
