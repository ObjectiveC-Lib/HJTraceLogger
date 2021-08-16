//
//  HJHTTPServerLogger.m
//  HJTraceLogger
//
//  Created by navy on 2021/8/16.
//  Copyright © 2021 navy. All rights reserved.
//

#if !__has_feature(objc_arc)
#error XLFacility requires ARC
#endif

#import "HJHTTPServerLogger.h"
#import <XLFacility/XLFunctions.h>
#import <XLFacility/XLFacilityMacros.h>

#define APP_NAME ([[[NSBundle mainBundle] localizedInfoDictionary] objectForKey:@"CFBundleDisplayName"] ? [[[NSBundle mainBundle] localizedInfoDictionary] objectForKey:@"CFBundleDisplayName"]:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"])
#define APP_VERSION ([[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"])
#define APP_BUILD ([[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"])

#define kDefaultMinRefreshDelay 500     // In milliseconds
#define kMaxLongPollDuration 30         // In seconds

@interface UIImage (Category)
- (nullable UIImage *)hj_tlImageByResizeToSize:(CGSize)size;
- (nullable UIImage *)hj_tlImageByRoundCornerRadius:(CGFloat)radius;
@end

@implementation UIImage (Category)
- (UIImage *)hj_tlImageByResizeToSize:(CGSize)size {
    if (size.width <= 0 || size.height <= 0) return nil;
    UIGraphicsBeginImageContextWithOptions(size, NO, self.scale);
    [self drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (UIImage *)hj_tlImageByRoundCornerRadius:(CGFloat)radius {
    return [self hj_tlImageByRoundCornerRadius:radius borderWidth:0 borderColor:nil];
}

- (UIImage *)hj_tlImageByRoundCornerRadius:(CGFloat)radius
                             borderWidth:(CGFloat)borderWidth
                             borderColor:(UIColor *)borderColor {
    return [self hj_tlImageByRoundCornerRadius:radius corners:UIRectCornerAllCorners borderWidth:borderWidth borderColor:borderColor borderLineJoin:kCGLineJoinMiter];
}

- (UIImage *)hj_tlImageByRoundCornerRadius:(CGFloat)radius
                                 corners:(UIRectCorner)corners
                             borderWidth:(CGFloat)borderWidth
                             borderColor:(UIColor *)borderColor
                          borderLineJoin:(CGLineJoin)borderLineJoin {
    
    if (corners != UIRectCornerAllCorners){
        UIRectCorner tmp = 0;
        if (corners & UIRectCornerTopLeft) tmp |= UIRectCornerBottomLeft;
        if (corners & UIRectCornerTopRight) tmp |= UIRectCornerBottomRight;
        if (corners & UIRectCornerBottomLeft) tmp |= UIRectCornerTopLeft;
        if (corners & UIRectCornerBottomRight) tmp |= UIRectCornerTopRight;
        corners = tmp;
    }
    
    UIGraphicsBeginImageContextWithOptions(self.size, NO, self.scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGRect rect = CGRectMake(0, 0, self.size.width, self.size.height);
    CGContextScaleCTM(context, 1, -1);
    CGContextTranslateCTM(context, 0, -rect.size.height);
    
    CGFloat minSize = MIN(self.size.width, self.size.height);
    if (borderWidth < minSize / 2) {
        UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:CGRectInset(rect, borderWidth, borderWidth) byRoundingCorners:corners cornerRadii:CGSizeMake(radius, borderWidth)];
        [path closePath];
        
        CGContextSaveGState(context);
        [path addClip];
        CGContextDrawImage(context, rect, self.CGImage);
        CGContextRestoreGState(context);
    }
    
    if (borderColor && borderWidth < minSize / 2 && borderWidth > 0) {
        CGFloat strokeInset = (floor(borderWidth * self.scale) + 0.5) / self.scale;
        CGRect strokeRect = CGRectInset(rect, strokeInset, strokeInset);
        CGFloat strokeRadius = radius > self.scale / 2 ? radius - self.scale / 2 : 0;
        UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:strokeRect byRoundingCorners:corners cornerRadii:CGSizeMake(strokeRadius, borderWidth)];
        [path closePath];
        
        path.lineWidth = borderWidth;
        path.lineJoinStyle = borderLineJoin;
        [borderColor setStroke];
        [path stroke];
    }
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}
@end


@interface XLHTTPServerLogger (Private)
@property(nonatomic, readonly) NSDateFormatter *dateFormatterRFC822;
@end


@interface HJHTTPServerConnection : GCDTCPServerConnection
@property (nonatomic, assign) NSTimeInterval refreshDelay;
@end

@implementation HJHTTPServerConnection {
    dispatch_semaphore_t _pollingSemaphore;
    NSMutableData *_headerData;
}

- (void)didReceiveLogRecord {
    if (_pollingSemaphore) {
        dispatch_semaphore_signal(_pollingSemaphore);
    }
}

- (BOOL)_writeHTTPResponseWithStatusCode:(NSInteger)statusCode image:(UIImage *)image {
    BOOL success = NO;
    CFHTTPMessageRef response = CFHTTPMessageCreateResponse(kCFAllocatorDefault, statusCode, NULL, kCFHTTPVersion1_1);
    CFHTTPMessageSetHeaderFieldValue(response, CFSTR("Connection"), CFSTR("Close"));
    CFHTTPMessageSetHeaderFieldValue(response, CFSTR("Server"), (__bridge CFStringRef)NSStringFromClass([self class]));
    CFHTTPMessageSetHeaderFieldValue(response, CFSTR("Date"), (__bridge CFStringRef)[[(XLHTTPServerLogger*)self.logger dateFormatterRFC822] stringFromDate:[NSDate date]]);
    if ([image isKindOfClass:[UIImage class]]) {
        NSData* htmlData = UIImagePNGRepresentation(image);
        CFHTTPMessageSetHeaderFieldValue(response, CFSTR("Content-Type"), CFSTR("image/x-icon"));
        CFHTTPMessageSetHeaderFieldValue(response, CFSTR("Content-Length"), (__bridge CFStringRef)[NSString stringWithFormat:@"%lu", (unsigned long)htmlData.length]);
        CFHTTPMessageSetBody(response, (__bridge CFDataRef)htmlData);
    }
    NSData* data = CFBridgingRelease(CFHTTPMessageCopySerializedMessage(response));
    if (data) {
        [self writeDataAsynchronously:data completion:^(BOOL ok) {
            [self close];
        }];
        success = YES;
    } else {
        XLOG_ERROR(@"Failed serializing HTTP response");
    }
    CFRelease(response);
    
    return success;
}

- (BOOL)_writeHTTPResponseWithStatusCode:(NSInteger)statusCode htmlBody:(NSString *)htmlBody {
    BOOL success = NO;
    CFHTTPMessageRef response = CFHTTPMessageCreateResponse(kCFAllocatorDefault, statusCode, NULL, kCFHTTPVersion1_1);
    CFHTTPMessageSetHeaderFieldValue(response, CFSTR("Connection"), CFSTR("Close"));
    CFHTTPMessageSetHeaderFieldValue(response, CFSTR("Server"), (__bridge CFStringRef)NSStringFromClass([self class]));
    CFHTTPMessageSetHeaderFieldValue(response, CFSTR("Date"), (__bridge CFStringRef)[[(XLHTTPServerLogger*)self.logger dateFormatterRFC822] stringFromDate:[NSDate date]]);
    if (htmlBody) {
        NSData* htmlData = XLConvertNSStringToUTF8String(htmlBody);
        CFHTTPMessageSetHeaderFieldValue(response, CFSTR("Content-Type"), CFSTR("text/html; charset=utf-8"));
        CFHTTPMessageSetHeaderFieldValue(response, CFSTR("Content-Length"), (__bridge CFStringRef)[NSString stringWithFormat:@"%lu", (unsigned long)htmlData.length]);
        CFHTTPMessageSetBody(response, (__bridge CFDataRef)htmlData);
    }
    NSData* data = CFBridgingRelease(CFHTTPMessageCopySerializedMessage(response));
    if (data) {
        [self writeDataAsynchronously:data completion:^(BOOL ok) {
            [self close];
        }];
        success = YES;
    } else {
        XLOG_ERROR(@"Failed serializing HTTP response");
    }
    CFRelease(response);
    
    return success;
}

- (void)_appendLogRecordsToString:(NSMutableString *)string afterAbsoluteTime:(CFAbsoluteTime)time {
    XLHTTPServerLogger* logger = (XLHTTPServerLogger*)self.logger;
    __block CFAbsoluteTime maxTime = time;
    [logger.databaseLogger enumerateRecordsAfterAbsoluteTime:time
                                                    backward:NO
                                                  maxRecords:0
                                                  usingBlock:^(int appVersion, XLLogRecord* record, BOOL* stop) {
        const char* style = "color: dimgray;";
        if (record.level == kXLLogLevel_Verbose){
            style = "color: #000000;";
        }
        else if (record.level == kXLLogLevel_Debug) {
            style = "color:#46C2F2;";
        }
        else if (record.level == kXLLogLevel_Info) {
            style = "color: green;";
        } else if (record.level == kXLLogLevel_Warning) {
            style = "color: orange;";
        } else if (record.level == kXLLogLevel_Error) {
            style = "color: red;";
        } else if (record.level >= kXLLogLevel_Exception) {
            style = "color: red; font-weight: bold;";
        }
        NSString* formattedMessage = [logger formatRecord:record];
        [string appendFormat:@"<tr style=\"%s\">%@</tr>", style, formattedMessage];
        if (record.absoluteTime > maxTime) {
            maxTime = record.absoluteTime;
        }
    }];
    [string appendFormat:@"<tr id=\"maxTime\" data-value=\"%f\"></tr>", maxTime];
}

- (BOOL)_processHTTPRequest:(CFHTTPMessageRef)request {
    BOOL success = NO;
    NSString* method = CFBridgingRelease(CFHTTPMessageCopyRequestMethod(request));
    if ([method isEqualToString:@"GET"]) {
        NSURL* url = CFBridgingRelease(CFHTTPMessageCopyRequestURL(request));
        NSString* path = url.path;
        NSString* query = url.query;
        
        if ([path isEqualToString:@"/"]) {
            NSMutableString* string = [[NSMutableString alloc] init];
            
            [string appendString:@"<!DOCTYPE html><html lang=\"en\">"];
            [string appendString:@"<head><meta charset=\"utf-8\">"];
            [string appendFormat:@"<title>%@ V%@ Build%@ 日志跟踪(%s[%i])</title>", APP_NAME, APP_VERSION, APP_BUILD, getprogname(), getpid()];
            [string appendString:@"<style>\
             body {\n\
             margin: 0px;\n\
             font-family: Courier, monospace;\n\
             font-size: 0.8em;\n\
             }\n\
             table {\n\
             width: 100%;\n\
             border-collapse: collapse;\n\
             }\n\
             tr {\n\
             vertical-align: top;\n\
             }\n\
             tr:nth-child(odd) {\n\
             background-color: #eeeeee;\n\
             }\n\
             td {\n\
             padding: 2px 10px;\n\
             }\n\
             #footer {\n\
             text-align: center;\n\
             margin: 20px 0px;\n\
             color: darkgray;\n\
             }\n\
             .error {\n\
             color: red;\n\
             font-weight: bold;\n\
             }\n\
             </style>"];
            [string appendFormat:@"<script type=\"text/javascript\">\n\
             var refreshDelay = %i;\n\
             var footerElement = null;\n\
             function updateTimestamp() {\n\
             var now = new Date();\n\
             footerElement.innerHTML = \"Last updated on \" + now.toLocaleDateString() + \" \" + now.toLocaleTimeString();\n\
             }\n\
             function refresh() {\n\
             var timeElement = document.getElementById(\"maxTime\");\n\
             var maxTime = timeElement.getAttribute(\"data-value\");\n\
             timeElement.parentNode.removeChild(timeElement);\n\
             \n\
             var xmlhttp = new XMLHttpRequest();\n\
             xmlhttp.onreadystatechange = function() {\n\
             if (xmlhttp.readyState == 4) {\n\
             if (xmlhttp.status == 200) {\n\
             var contentElement = document.getElementById(\"content\");\n\
             contentElement.innerHTML = contentElement.innerHTML + xmlhttp.responseText;\n\
             updateTimestamp();\n\
             setTimeout(refresh, refreshDelay);\n\
             } else {\n\
             footerElement.innerHTML = \"<span class=\\\"error\\\">Connection failed! Reload page to try again.</span>\";\n\
             }\n\
             }\n\
             }\n\
             xmlhttp.open(\"GET\", \"/log?after=\" + maxTime, true);\n\
             xmlhttp.send();\n\
             }\n\
             window.onload = function() {\n\
             footerElement = document.getElementById(\"footer\");\n\
             updateTimestamp();\n\
             setTimeout(refresh, refreshDelay);\n\
             }\n\
             </script>",
             kDefaultMinRefreshDelay];
            [string appendString:@"</head>"];
            [string appendString:@"<body>"];
            [string appendFormat:@"<div style=\"padding-bottom: 9px;margin: 40px 0 20px;border-bottom: 1px solid #eee;text-align:center;\"><h1>%@ V%@ Build%@ 日志跟踪 (%s[%i])</h1></div>", APP_NAME, APP_VERSION, APP_BUILD, getprogname(), getpid()];
            [string appendString:@"<table><tbody id=\"content\">"];
            [self _appendLogRecordsToString:string afterAbsoluteTime:0.0];
            [string appendString:@"</tbody></table>"];
            [string appendString:@"<div id=\"footer\"></div>"];
            [string appendString:@"</body>"];
            [string appendString:@"</html>"];
            
            success = [self _writeHTTPResponseWithStatusCode:200 htmlBody:string];
        } else if([path isEqualToString:@"/favicon.ico"]) {
            UIImage *icon = [UIImage imageNamed:@"AppIcon60x60"];
            if([icon isKindOfClass:[UIImage class]]) {
                success = [self _writeHTTPResponseWithStatusCode:200 image:[[icon hj_tlImageByResizeToSize:CGSizeMake(32.0f, 32.0f)] hj_tlImageByRoundCornerRadius:4.0f]];
            } else {
                XLOG_WARNING(@"Unsupported path in HTTP request: %@", path);
                success = [self _writeHTTPResponseWithStatusCode:404 htmlBody:nil];
            }
        } else if ([path isEqualToString:@"/log"] && [query hasPrefix:@"after="]) {
            NSMutableString* string = [[NSMutableString alloc] init];
            CFAbsoluteTime time = [[query substringFromIndex:6] doubleValue];
            
            _pollingSemaphore = dispatch_semaphore_create(0);
            dispatch_semaphore_wait(_pollingSemaphore, dispatch_time(DISPATCH_TIME_NOW, kMaxLongPollDuration * NSEC_PER_SEC));
            if (self.peer) {  // Check for race-condition if the connection was closed while waiting
                [self _appendLogRecordsToString:string afterAbsoluteTime:time];
                success = [self _writeHTTPResponseWithStatusCode:200 htmlBody:string];
            }
        } else {
            XLOG_WARNING(@"Unsupported path in HTTP request: %@", path);
            success = [self _writeHTTPResponseWithStatusCode:404 htmlBody:nil];
        }
        
    } else {
        XLOG_WARNING(@"Unsupported method in HTTP request: %@", method);
        success = [self _writeHTTPResponseWithStatusCode:405 htmlBody:nil];
    }
    return success;
}

- (void)_readHeaders {
    [self readDataAsynchronously:^(NSData* data) {
        if (data) {
            [self->_headerData appendData:data];
            NSRange range = [self->_headerData rangeOfData:[NSData dataWithBytes:"\r\n\r\n" length:4] options:0 range:NSMakeRange(0, self->_headerData.length)];
            if (range.location != NSNotFound) {
                BOOL success = NO;
                CFHTTPMessageRef message = CFHTTPMessageCreateEmpty(kCFAllocatorDefault, true);
                CFHTTPMessageAppendBytes(message, data.bytes, data.length);
                if (CFHTTPMessageIsHeaderComplete(message)) {
                    success = [self _processHTTPRequest:message];
                } else {
                    XLOG_ERROR(@"Failed parsing HTTP request headers");
                }
                CFRelease(message);
                if (!success) {
                    [self close];
                }
                
            } else {
                [self _readHeaders];
            }
        } else {
            [self close];
        }
    }];
}

- (void)didOpen {
    [super didOpen];
    
    _headerData = [[NSMutableData alloc] init];
    [self _readHeaders];
}

- (void)didClose {
    [super didClose];
    
    if (_pollingSemaphore) {
        dispatch_semaphore_signal(_pollingSemaphore);
    }
}

#if !OS_OBJECT_USE_OBJC_RETAIN_RELEASE

- (void)dealloc {
    if (_pollingSemaphore) {
        dispatch_release(_pollingSemaphore);
    }
}

#endif

@end


@interface HJHTTPServerLogger() {
    dispatch_semaphore_t _pollingSemaphore;
}
@property (nonatomic, assign) NSTimeInterval refreshDelay;
@end

@implementation HJHTTPServerLogger

+ (Class)connectionClass {
    return [HJHTTPServerConnection class];
}

- (instancetype)init {
    if (self = [super init]) {
        [self initVariables];
    }
    return self;
}

- (instancetype)initWithPort:(NSUInteger)port {
    if (self = [super initWithPort:port]) {
        [self initVariables];
    }
    return self;
}

- (instancetype)initWithPort:(NSUInteger)port useDatabaseLogger:(BOOL)useDatabaseLogger {
    if (self = [super initWithPort:port useDatabaseLogger:useDatabaseLogger]) {
        [self initVariables];
    }
    return self;
}

- (void)initVariables {
    
}

@end
