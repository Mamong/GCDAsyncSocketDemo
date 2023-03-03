//
//  LocalAreaPeerClient.m
//  GCDAsyncSocketDemo
//
//  Created by tryao on 2022/6/15.
//

#import "LocalAreaPeerClient.h"
#import "GCDAsyncSocket.h"

@interface LocalAreaPeerClient ()<GCDAsyncSocketDelegate>
@property (nonatomic, strong) GCDAsyncSocket *clientSocket;
@property (nonatomic, strong) NSTimer *heartTimer;
@property (nonatomic, weak) id<LocalAreaPeerClientDelegate> delegate;
@property (nonatomic, assign) BOOL connected;
@property (nonatomic, strong) dispatch_queue_t sockeQueue;
@property (nonatomic, strong) NSMutableData *dataBuffer;
@end

@implementation LocalAreaPeerClient

+ (instancetype)shareInstance {
    static LocalAreaPeerClient *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [self new];
        instance.needHeart = NO;
        instance.heartInterval = 5;
    });
    return instance;
}

- (BOOL)connectToHost:(NSString*)host onPort:(uint16_t)port delegate:(id<LocalAreaPeerClientDelegate>)delegate {
    self.delegate = delegate;
    NSError *error = nil;
    //不在同一个局域网也显示能连接成功，实际不能
    BOOL result = [self.clientSocket connectToHost:host onPort:port error:&error];
    if (result && !error) {
        //存在连接超时的问题
        return YES;
    }else {
        if ([self.delegate respondsToSelector:@selector(socket:connectToServer:status:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate socket:self connectToServer:host status:ConnectStatusConnectFail];
            });
        }
        return NO;
    }
}

- (void)startHeartTimer {
    [self stopHeartTimer];
    //主线程初始化 Timer
    dispatch_async(dispatch_get_main_queue(), ^{
        self.heartTimer = [NSTimer scheduledTimerWithTimeInterval:self.heartInterval target:self selector:@selector(sendHeartData) userInfo:nil repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:self.heartTimer forMode:NSRunLoopCommonModes];
    });
}

- (void)stopHeartTimer {
    if (self.heartTimer) {
        [self.heartTimer invalidate];
        self.heartTimer = nil;
    }
}

- (void)sendHeartData {
    char hearBeat[4] = {0xab,0xcd,0x00,0x00};
    NSData *heartData = [NSData dataWithBytes:&hearBeat length:sizeof(hearBeat)];
    [self sendData:heartData];
    NSLog(@"发送心跳");
}

- (void)sendData:(NSData *)contentData {
    [self.clientSocket writeData:contentData withTimeout:-1 tag:0];
}

- (void)disconnect {
    if (self.connected) {
        [self.clientSocket disconnect];
    }
}

- (void)readData
{
    [self.clientSocket readDataWithTimeout:-1 tag:0];
}

#pragma mark - GCDAsyncSocketDelegate

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port {
    self.connected = YES;
    if ([self.delegate respondsToSelector:@selector(socket:connectToServer:status:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate socket:self connectToServer:host status:(ConnectStatusConnected)];
        });
    }
    NSLog(@"server:%@", host);
    self.dataBuffer = [NSMutableData data];
    [sock readDataWithTimeout:-1 tag:0];
    if (self.needHeart) {
        //开始发送心跳
        [self startHeartTimer];
    }
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    [sock readDataWithTimeout:-1 tag:0];
    if ([self.delegate respondsToSelector:@selector(socket:receiveData:)]) {
        [self.delegate socket:self receiveData:data];
    }
}

- (void)socket:(GCDAsyncSocket *)sock didReadPartialDataOfLength:(NSUInteger)partialLength tag:(long)tag {
    NSLog(@"client read %lu",(unsigned long)partialLength);
}


- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(nullable NSError *)err {
    NSLog(@"断开链接: %@; error: %@", sock.connectedHost, err);
    self.connected = FALSE;
    if ([self.delegate respondsToSelector:@selector(socket:connectToServer:status:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate socket:self connectToServer:sock.connectedHost status:(ConnectStatusDisconnected)];
        });
    }
    NSLog(@"%@", [NSThread currentThread]);
    [self stopHeartTimer];
}

#pragma mark - Property

- (GCDAsyncSocket *)clientSocket {
    if (!_clientSocket) {
        _clientSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:self.sockeQueue];
    }
    return _clientSocket;
}

//串行队列进行socket数据读写
- (dispatch_queue_t)sockeQueue {
    if (!_sockeQueue) {
        _sockeQueue = dispatch_queue_create("sockeQueue", DISPATCH_QUEUE_SERIAL);
    }
    return _sockeQueue;
}

- (NSMutableData *)dataBuffer {
    if (!_dataBuffer) {
        _dataBuffer = [NSMutableData data];
    }
    return _dataBuffer;
}
@end
