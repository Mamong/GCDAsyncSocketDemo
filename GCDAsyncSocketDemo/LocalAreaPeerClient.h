//
//  LocalAreaPeerClient.h
//  GCDAsyncSocketDemo
//
//  Created by tryao on 2022/6/15.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class LocalAreaPeerClient;

typedef NS_ENUM(NSInteger, ConnectStatus) {
    ConnectStatusConnected    = 0,//链接成功
    ConnectStatusConnectFail  = 1,//链接失败
    ConnectStatusDisconnected = 2//断开
};

@protocol LocalAreaPeerClientDelegate <NSObject>

- (void)socket:(LocalAreaPeerClient *)tool receiveData:(NSData *)contentData;

- (void)socket:(LocalAreaPeerClient *)tool connectToServer:(NSString *)host status:(ConnectStatus)status;

@end


@interface LocalAreaPeerClient : NSObject

@property (nonatomic, assign) BOOL needHeart;
@property (nonatomic, assign) float heartInterval;

+ (instancetype)shareInstance;

- (BOOL)connectToHost:(NSString*)host onPort:(uint16_t)port delegate:(id<LocalAreaPeerClientDelegate>)delegate;

- (void)sendData:(NSData *)contentData;

- (void)readData;

- (void)disconnect;

@end

NS_ASSUME_NONNULL_END
