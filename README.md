# HJTraceLogger

## 安装
```
pod 'HJTraceLogger', '~> 1.0.0'
```

## 使用

```obj-c

#import <HJTraceLogger/HJTraceLogger.h>

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	// Override point for customization after application launch.
    [HJTraceLoggerManager start];

    XLOG_INFO(@"INFO 测试:  您正在使用 iOS 远程日志查看服务！");
    XLOG_WARNING(@"WARNING 测试:  您正在使用 iOS 远程日志查看服务！");
    XLOG_ERROR(@"ERROR 测试:  您正在使用 iOS 远程日志查看服务！");

    return YES;
}
```

## 查看

```
1, 手机和电脑在同一个局域网内
2, 查看手机网络的ip
3, 在 PC 浏览器中打开 http://手机ip:8080 浏览日志
```

## 配置

```
1, AppDelegate.m 改为 AppDelegate.mm
2, Build Settings -> Enable Bitcode = NO
```
