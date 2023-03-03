//
//  SocketManager.h
//  GCDAsyncSocketDemo
//
//  Created by tryao on 2022/6/15.
//

#import <Foundation/Foundation.h>
#import "SocketSendItem.h"
#import "ServerSocketItem.h"

/**
 客户端发送列表信息给服务端，服务端接收完成后，发送确认消息FILE_LIST_SEND_END
 客户端收到确认消息FILE_LIST_SEND_END，发送文件信息1。服务端接收完成后，发送确认消息FILE_HEAD_SEND_END1。
 客户端接收确认消息FILE_HEAD_SEND_END1后，发送文件数据1。服务端接收完成后，发送确认消息FILE_HEAD_SEND_END1。
 客户端收到FILE_HEAD_SEND_END1后发送下一个文件信息。
 */

NS_ASSUME_NONNULL_BEGIN

@class SocketManager;

@protocol SocketManagerDelegate <NSObject>

-(void)serverSocketManager:(SocketManager*)manager connect:(BOOL)isConnect connectIp:(NSString *)ip;

-(void)socketManager:(SocketManager*)manager itemUpingRefresh:(SocketSendItem*)item;


-(void)serverSocketManager:(SocketManager*)manager fileHeadAccept:(ServerSocketItem*)item;

-(void)serverSocketManager:(SocketManager*)manager fileAccepting:(ServerSocketItem*)item;

-(void)serverSocketManager:(SocketManager*)manager fileListAccept:(NSArray*)files;
@end

@interface SocketManager : NSObject
@property(nonatomic, strong) NSString *dataSavePath;
@property(nonatomic, weak)id<SocketManagerDelegate> delegate;

+ (instancetype)shareServerSocketManager;

- (BOOL)startListenPort:(uint16_t)port;
- (BOOL)connentHost:(NSString *)host port:(uint16_t)port;

- (void)sendItems:(NSMutableArray *)items;
@end

NS_ASSUME_NONNULL_END
