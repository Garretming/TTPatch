//
//  ExampleTests.m
//  ExampleTests
//
//  Created by tianyubing on 2020/4/24.
//  Copyright © 2020 TianyuBing. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "../../TTDFKit/TTDFKit.h"
#import "../../libs/TTDFKitHotRefrshTool.h"
#import "基础用法模板/TTPlaygroundController.h"
#import "TTDFKitUnitTests.h"
@interface ExampleTests : XCTestCase

@end

@implementation ExampleTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
    // 初始化SDK
    [TTDFKit initSDK];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testExample {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    /**
     * 连接本地测试服务,如加载空白,请检查
     * 1.本地服务是否已启动成功
     * 2.检查`info.plist`中IP是否获取正确
     */
    [self testSocket];
    // 拉取本地js资源
    [self updateResource:@"hotfixPatch.js" callbacl:nil];
    TTDFKitUnitTests *test = [TTDFKitUnitTests new];
    [test testExample];
    
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{

    }];
}

- (void)testSocket{
    
    NSString *socket;
#if TARGET_IPHONE_SIMULATOR  //模拟器
    socket = [NSString stringWithFormat:@"ws://%@:%@/socket.io/?EIO=4&transport=websocket",
              @"127.0.0.1",
              [TTDFKitHotRefrshTool shareInstance].getLocaServerPort];
#elif TARGET_OS_IPHONE      //真机
    socket = [NSString stringWithFormat:@"ws://%@:%@/socket.io/?EIO=4&transport=websocket",
              [TTDFKitHotRefrshTool shareInstance].getLocaServerIP,
              [TTDFKitHotRefrshTool shareInstance].getLocaServerPort];
#endif
    [[TTDFKitHotRefrshTool shareInstance] startLocalServer:socket];
    [TTDFKitHotRefrshTool shareInstance].delegate = self;
}

- (void)reviceRefresh:(id)msg{
    [self updateResource:msg callbacl:nil];
}

- (void)updateResource:(NSString *)filename callbacl:(void(^)(void))callback
{
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLRequest *req = [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://%@:%@/%@",
                                                                           [TTDFKitHotRefrshTool shareInstance].getLocaServerIP,
                                                                           [TTDFKitHotRefrshTool shareInstance].getLocaServerPort,
                                                                           filename]]];
    
    
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:req completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (data && (error == nil)) {
            NSString *result = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            if (!result || !result.length) {
                return ;
            }
            [[TTDFKit shareInstance] evaluateScript:[[TTDFKit shareInstance] formatterJS:result] withSourceURL:[NSURL URLWithString:filename]];
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:@"TTDFKit-Refresh" object:nil];
            });
            if (callback) {
                callback();
            }
        } else {
            // 本地代理未开启,加载本地bundle资源,无法实时预览
            NSString *srcPath = [[NSBundle mainBundle] pathForResource:@"hotfixPatch" ofType:@"js"];
            
               
            NSString *jsCode = [[NSString alloc] initWithData:[[NSFileManager defaultManager] contentsAtPath:srcPath] encoding:NSUTF8StringEncoding];
                   
            [[TTDFKit shareInstance] evaluateScript:[[TTDFKit shareInstance] formatterJS:jsCode] withSourceURL:[NSURL URLWithString:@"hotfixPatch.js"]];
            
        }
    }];
    [dataTask resume];
}

@end
