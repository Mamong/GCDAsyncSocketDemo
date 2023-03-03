//
//  LocalAreaPeerServer.h
//  GCDAsyncSocketDemo
//
//  Created by tryao on 2022/6/15.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class LocalAreaPeerServer;

typedef NS_ENUM(NSInteger, ConnectStatus) {
    ConnectStatusConnected    = 0,//链接成功
    ConnectStatusConnectFail  = 1,//链接失败
    ConnectStatusDisconnected = 2//断开
};

@protocol LocalAreaPeerServerDelegate <NSObject>

- (void)socket:(LocalAreaPeerServer *)server receiveData:(NSData *)contentData fromClient:(NSString*)client;

- (void)socket:(LocalAreaPeerServer *)server connectToClient:(NSString*)host status:(ConnectStatus)status;

- (void)socket:(LocalAreaPeerServer *)server didWriteDataWithTag:(long)tag;

@end

@interface LocalAreaPeerServer : NSObject

@property (nonatomic, strong) NSMutableDictionary *clientDict;

+ (instancetype)shareInstance;

- (BOOL)listenOnPort:(uint16_t)port delegate:(id<LocalAreaPeerServerDelegate>)delegate;

- (void)sendData:(NSData *)contentData;

- (void)sendData:(NSData *)contentData to:(NSString *)client;

- (void)sendData:(NSData *)contentData to:(NSString *)client tag:(NSInteger)tag;

- (void)readDataFromClient:(NSString*)client;

- (void)disconnect:(NSString *)client;

- (void)disconnect;

- (void)stopCheckThread;

@end

NS_ASSUME_NONNULL_END
