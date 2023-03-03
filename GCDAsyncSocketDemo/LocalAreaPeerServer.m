//
//  LocalAreaPeerServer.m
//  GCDAsyncSocketDemo
//
//  Created by tryao on 2022/6/15.
//

#import "LocalAreaPeerServer.h"
#import "GCDAsyncSocket.h"

@interface LocalAreaPeerServer()<GCDAsyncSocketDelegate>
@property (nonatomic, strong) GCDAsyncSocket *serverSocket;
@property (nonatomic, strong) NSMutableDictionary *heartDict;
@property (nonatomic, strong) NSMutableData *dataBuffer;
@property (nonatomic, strong) NSThread *checkThread;
@property (nonatomic, weak) id<LocalAreaPeerServerDelegate> delegate;
@end

@implementation LocalAreaPeerServer

+ (instancetype)shareInstance {
    static LocalAreaPeerServer *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [self new];
    });
    return instance;
}

- (BOOL)listenOnPort:(uint16_t)port delegate:(id<LocalAreaPeerServerDelegate>)delegate {
    self.delegate = delegate;

    NSError *error;
    BOOL result = [self.serverSocket acceptOnPort:port error:&error];
    if (result && !error) {
        return YES;
    }else {
        return NO;
    }
}

- (void)disconnect
{
    [self.serverSocket disconnect];
    for (GCDAsyncSocket *socket in self.clientDict.allValues) {
        [socket disconnect];
    }
    [self.clientDict removeAllObjects];
}

- (void)sendData:(NSData *)contentData
{
    if (self.clientDict.allValues.count == 0) return;
    GCDAsyncSocket *client = self.clientDict.allValues[0];
    [self sendData:contentData to:client.connectedHost];
}

- (void)sendData:(NSData *)contentData to:(NSString *)client {
    [self sendData:contentData to:client tag:0];
}

- (void)sendData:(NSData *)contentData to:(NSString *)client tag:(NSInteger)tag
{
    GCDAsyncSocket *socket = self.clientDict[client];
    if (!socket) {
        return;
    }
    [socket writeData:contentData withTimeout:-1 tag:tag];
}


- (void)disconnect:(NSString *)client {
    GCDAsyncSocket *socket = self.clientDict[client];
    if (socket) {
        [socket disconnect];
        self.clientDict[client] = nil;
    }
}

- (void)readDataFromClient:(NSString*)client
{
    GCDAsyncSocket *socket = self.clientDict[client];
    if (!socket) {
        return;
    }
    [socket readDataWithTimeout:-1 tag:0];
}

- (void)checkClientOnline{
    
    @autoreleasepool {
        [NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(checkClient) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] run];
    }
}

- (void)checkClient{
    NSArray *allValues = [self.clientDict allValues];
    if (allValues.count == 0) {
        return;
    }
    NSDate *date = [NSDate date];
    NSDictionary *tempDic = [self.clientDict copy];
    [tempDic enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, GCDAsyncSocket *obj, BOOL * _Nonnull stop) {
        if ([date timeIntervalSinceDate:self.heartDict[obj.connectedHost]] > 10) {
            self.clientDict[key] = nil;
        }
    }];
}

- (void)stopCheckThread {
    [self.checkThread cancel];
    self.checkThread = nil;
}

#pragma mark - GCDAsyncSocketDelegate
- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket {
    NSLog(@"收到链接:%@: %d", newSocket.localAddress, newSocket.localPort);
    self.clientDict[newSocket.connectedHost] = newSocket;
    [self startCheckThread];
    if ([self.delegate respondsToSelector:@selector(socket:connectToClient:status:)]) {
        [self.delegate socket:self connectToClient:newSocket.connectedHost status:ConnectStatusConnected];
    }
    [newSocket readDataWithTimeout:-1 tag:0];
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    NSLog(@"server read:%lu",(unsigned long)data.length);
    [sock readDataWithTimeout:-1 tag:0];
    if ([self.delegate respondsToSelector:@selector(socket:receiveData:fromClient:)]) {
        [self.delegate socket:self receiveData:data fromClient:sock.connectedHost];
    }
}

- (void)socket:(GCDAsyncSocket *)sock didWritePartialDataOfLength:(NSUInteger)partialLength tag:(long)tag {
    NSLog(@"server write:%lu",(unsigned long)partialLength);
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag{
    if ([self.delegate respondsToSelector:@selector(socket:didWriteDataWithTag:)]) {
        [self.delegate socket:self didWriteDataWithTag:tag];
    }
}


- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(nullable NSError *)err {
    NSLog(@"断开链接: %@; error: %@", sock.connectedHost, err);
    //搜索socket
    __block NSString *connectedHost = @"";
    [self.clientDict enumerateKeysAndObjectsUsingBlock:^(NSString* key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if (obj == sock) {
            connectedHost = key;
        }
    }];
    if ([self.delegate respondsToSelector:@selector(socket:connectToClient:status:)]) {
        [self.delegate socket:self connectToClient:connectedHost status:(ConnectStatusDisconnected)];
    }
}

#pragma mark - Property

- (GCDAsyncSocket *)serverSocket {
    if (!_serverSocket) {
        _serverSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    }
    return _serverSocket;
}

- (NSMutableDictionary *)clientDict {
    if (!_clientDict) {
        _clientDict = [NSMutableDictionary dictionary];
    }
    return _clientDict;
}

- (NSMutableDictionary *)heartDict {
    if (!_heartDict) {
        _heartDict = [NSMutableDictionary dictionary];
    }
    return _heartDict;
}


- (void)startCheckThread {
    if (!_checkThread) {
        _checkThread = [[NSThread alloc] initWithTarget:self selector:@selector(checkClientOnline) object:nil];
        [_checkThread start];
    }
}

- (NSMutableData *)dataBuffer {
    if (!_dataBuffer) {
        _dataBuffer = [NSMutableData data];
    }
    return _dataBuffer;
}
@end
