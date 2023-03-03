//
//  SocketManager.m
//  GCDAsyncSocketDemo
//
//  Created by tryao on 2022/6/15.
//

#import "SocketManager.h"
#import "GCDAsyncSocket.h"
#import <MJExtension/MJExtension.h>

@interface SocketManager()<GCDAsyncSocketDelegate>
@property(nonatomic, strong) GCDAsyncSocket *serverSocket;
@property(nonatomic, strong) GCDAsyncSocket *tcpSocketManager;
@property(nonatomic, strong) NSMutableArray *clientSocketArray;
@property(nonatomic, strong) NSMutableArray *socketItemArray;
@property(nonatomic, strong) ServerSocketItem *currentSendItem;
@property(nonatomic, strong) NSMutableArray *waitingSendItems;
@property(nonatomic, strong) NSOutputStream *outputStream;
@end

@implementation SocketManager

#define LISTTAG -1
#define SENDFILEINFOLIST   @"SENDFILEINFOLIST"
#define FILE_LIST_SEND_END @"FILE_LIST_SEND_END"
#define SENDFILEHEADINFO   @"SENDFILEHEADINFO"
#define FILE_HEAD_SEND_END @"FILE_HEAD_SEND_END"

static SocketManager *_instance;

+ (instancetype)shareServerSocketManager
{
    static dispatch_once_t onceToken;
       dispatch_once(&onceToken, ^{
       if(_instance == nil)
           _instance = [[SocketManager alloc] init];
      });
       return _instance;
}

// 服务端监听端口
- (BOOL)startListenPort:(uint16_t)port
{
  if (port <= 0) {
      NSAssert(port > 0, @"prot must be more zero");
  }
  if (!self.serverSocket) {
      self.serverSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
  }
  [self.serverSocket disconnect];
  NSError *error = nil;
  BOOL result = [self.serverSocket acceptOnPort:port error:&error];
  if (result && !error) {
      return YES;
  }else{
      return NO;
  }
}

//客户端连接服务端
- (BOOL)connentHost:(NSString *)host port:(uint16_t)port
{
    if (host==nil || host.length <= 0) {
        NSAssert(host != nil, @"host must be not nil");
    }

    [self.tcpSocketManager disconnect];
    if (self.tcpSocketManager == nil) {
        self.tcpSocketManager = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    }
    NSError *connectError = nil;
    [self.tcpSocketManager connectToHost:host onPort:port error:&connectError];
    
    if (connectError) {
        return NO;
    }
    // 可读取服务端数据
    [self.tcpSocketManager readDataWithTimeout:-1 tag:0];
    return YES;
}

- (void)sendItems:(NSMutableArray *)items{
    _waitingSendItems = items;
    
    if (items.count <= 0) {
        return;
    }
   
    // 固定头部
    SocketSendItem *headItem = [[SocketSendItem alloc] init];
    headItem.index = LISTTAG;
    headItem.fileName = @"列表";
    NSData *headData = [self createHeadString:headItem];

    // 列表数据
    NSInteger count = items.count;
    NSMutableArray *itemDicArray = [NSMutableArray arrayWithCapacity:count];
    for (NSInteger i = 0; i < count; i++) {
        SocketSendItem *item = items[i];
        item.index = i;
        NSMutableDictionary *dic = [NSMutableDictionary dictionary];
        dic[@"fileName"] = item.fileName;
        dic[@"fileType"] = [NSNumber numberWithInteger:item.type];
        dic[@"fileSize"] = [NSNumber numberWithInteger:item.fileSize];
        dic[@"id"] = [NSNumber numberWithInteger:item.index];
        [itemDicArray addObject:dic];
    }
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:itemDicArray
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:nil];

    // 尾部拼接
    NSString *s = @"\nend\n";
    NSData *endData = [s dataUsingEncoding:NSUTF8StringEncoding];

    NSMutableData *listHeadData = [NSMutableData dataWithData:headData];
    [listHeadData appendData:jsonData];
    [listHeadData appendData:endData];
    [self.tcpSocketManager writeData:listHeadData withTimeout:-1 tag:LISTTAG];
    NSLog(@"listHeadData = %@",[[NSString alloc] initWithData:listHeadData encoding:NSUTF8StringEncoding]);
    
}

//大文件读写
- (void)writeDataWithItem:(SocketSendItem *)sendItem{
    NSData *sendData = [NSData dataWithContentsOfURL:sendItem.filePath options:NSDataReadingMappedIfSafe error:nil];
    NSLog(@"sendData = %zd",sendData.length);
    [self.tcpSocketManager writeData:sendData withTimeout:-1 tag:sendItem.index];
}

#pragma mark - private
- (NSData*)createHeadString:(SocketSendItem*)item
{
    NSString *s = [NSString stringWithFormat:@"%@\nbegin\n",SENDFILEINFOLIST];
    return [s dataUsingEncoding:NSUTF8StringEncoding];
}

- (NSString*)listOrHeadString:(NSString*)content OfString:(NSString*)string
{
    return content;
}

#pragma mark - GCDSocketDelegate

- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket{
    if (!self.clientSocketArray) {
        self.clientSocketArray = [NSMutableArray array];
    }
    [self.clientSocketArray addObject:newSocket];
    [newSocket readDataWithTimeout:- 1 tag:0];
    if ([self.delegate respondsToSelector:@selector(serverSocketManager:connect:connectIp:)]) {
        [self.delegate serverSocketManager:self connect:YES connectIp:newSocket.connectedHost];
    }
}

/// 接收到消息
- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag{
    NSString *readStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    //服务端接收到文件列表信息，告诉客户端已收到
    if ([readStr containsString:SENDFILEINFOLIST]) { // 接受到列表
        // 解析列表头部
        NSString *jsonStr = [self listOrHeadString:readStr OfString:SENDFILEINFOLIST];
        NSData *jsonData = [jsonStr dataUsingEncoding:NSUTF8StringEncoding];
        NSArray *array = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingAllowFragments error:nil];
        _socketItemArray = [ServerSocketItem mj_objectArrayWithKeyValuesArray:array];
        if ([self.delegate respondsToSelector:@selector(serverSocketManager:fileListAccept:)]) {
            [self.delegate serverSocketManager:self fileListAccept:_socketItemArray];
        }
        NSLog(@"listjsonStr = %@",jsonStr);
        
        for (GCDAsyncSocket *clientSock in self.clientSocketArray) {
            [clientSock writeData:[FILE_LIST_SEND_END dataUsingEncoding:NSUTF8StringEncoding] withTimeout:-1 tag:0];
        }
        //服务端接收到文件信息，告诉客户端已收到
    }else if ([readStr containsString:SENDFILEHEADINFO]){ // 接受到头部
        // 解析头部信息
        NSString *jsonStr = [self listOrHeadString:readStr OfString:SENDFILEHEADINFO];
        NSLog(@"headjsonStr = %@",jsonStr);
        NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:[jsonStr dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingAllowFragments error:nil];
        ServerSocketItem *item = [ServerSocketItem mj_objectWithKeyValues:dic];
        self.currentSendItem = item;
        if (item.ID < self.socketItemArray.count) {
            [self.socketItemArray replaceObjectAtIndex:item.ID withObject:item];
            if ([self.delegate respondsToSelector:@selector(serverSocketManager:fileHeadAccept:)]) {
                [self.delegate serverSocketManager:self fileHeadAccept:item];
            }
        }
        // 通知客户端已经接受完成
        for (GCDAsyncSocket *clientSock in self.clientSocketArray) {
            NSString *str = [NSString stringWithFormat:@"%@%zd\n",FILE_HEAD_SEND_END,item.ID];
            [clientSock writeData:[str dataUsingEncoding:NSUTF8StringEncoding] withTimeout:-1 tag:0];
        }
    }else{
        //服务端接收到文件
        if (_currentSendItem && _currentSendItem.isCancel == 0) {
            _currentSendItem.acceptSize += data.length;
            _currentSendItem.beginAccept = YES;
            NSLog(@"acceptSize = %zd",_currentSendItem.acceptSize);
            if (!self.outputStream) {
                _currentSendItem.filePath = [self.dataSavePath stringByAppendingPathComponent:[_currentSendItem.fileName lastPathComponent]];
                self.outputStream = [[NSOutputStream alloc] initToFileAtPath:_currentSendItem.filePath append:YES];
                [self.outputStream open];
            }
            // 输出流 写数据
            NSInteger byt = [self.outputStream write:data.bytes maxLength:data.length];
            NSLog(@"byt = %zd",byt);
            
            if (_currentSendItem.acceptSize >= _currentSendItem.fileSize) {
                _currentSendItem.finishAccept = YES;
                [self.outputStream close];
                self.outputStream = nil;
            }
            
            if ([self.delegate respondsToSelector:@selector(serverSocketManager:fileAccepting:)]) {
                [self.delegate serverSocketManager:self fileAccepting:_currentSendItem];
            }
        }
        
    }
    
    [sock readDataWithTimeout:-1 tag:0];
}

// 分段传输完成后的 回调
- (void)socket:(GCDAsyncSocket *)sock didWritePartialDataOfLength:(NSUInteger)partialLength tag:(long)tag {
    self.currentSendItem.upSize += partialLength;
    if ([self.delegate respondsToSelector:@selector(socketManager:itemUpingRefresh:)] && (tag<self.waitingSendItems.count)) {
        SocketSendItem *item = self.waitingSendItems[tag];
        item.isSending = YES;
        [self.delegate socketManager:self itemUpingRefresh:item];
    }
    NSLog(@"%f--tag = %zd",((self.currentSendItem.upSize * 1.0) / self.currentSendItem.fileSize),tag);
}
@end
