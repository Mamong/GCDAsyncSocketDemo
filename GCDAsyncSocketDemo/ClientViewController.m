//
//  ClientViewController.m
//  GCDAsyncSocketDemo
//
//  Created by tryao on 2022/6/15.
//

#import "ClientViewController.h"
#import "LocalAreaPeerClient.h"
#import "ServerSocketItem.h"
#import <MJExtension/MJExtension.h>
#import <AVKit/AVPlayerViewController.h>
#import "MOAInspectUtility.h"
#import "AFNetworkReachabilityManager.h"
#import "NSData+AES.h"
#import "FileChecksumUtil.h"

#define REQ_AUTH @"REQ_AUTH"
#define RSP_AUTH @"RSP_AUTH"
#define REQ_FILE_INFO_LIST @"REQ_FILE_INFO_LIST"
#define RSP_FILE_INFO_LIST @"RSP_FILE_INFO_LIST"
#define REQ_FILE @"REQ_FILE"

#define APP_PUBLIC_PASSWORD @"A1B@C#F4G5H6~*71"

@interface ClientViewController ()<LocalAreaPeerClientDelegate>
@property(nonatomic, strong)LocalAreaPeerClient *client;
@property(nonatomic, strong)NSString *ip;
@property(nonatomic, assign)uint16_t port;


@property(nonatomic, strong) NSArray *files;
//@property(nonatomic, assign) BOOL isWaitingAuth;
//@property(nonatomic, assign) BOOL isWaitingFileListInfo;
//@property(nonatomic, assign) BOOL isWaitingFile;
@property(nonatomic, assign) BOOL isWaitingMsg;
@property (nonatomic, strong) NSMutableData *dataBuffer;

@property(nonatomic, assign) NSInteger fileIndex;
@property(nonatomic, strong) ServerSocketItem *acceptItem;
@property(nonatomic, strong) NSArray *fileItems;

@property(nonatomic, strong) NSOutputStream *outputStream;

@property(nonatomic, strong) NSDate *lastTestSpeedDate;
@property(nonatomic, assign) NSInteger lastTestTotalSize;
@property(nonatomic, assign) NSInteger totalSize;
@property(nonatomic, assign) NSInteger speed;

@property(nonatomic, assign) NSInteger chunkTotal;


//0未知 1成功 2失败
@property(nonatomic, assign) NSInteger firstConnectResult;
@end

@implementation ClientViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES);
    NSString *basePath = paths.firstObject;
    
    NSString *fullPath = [basePath stringByAppendingPathComponent:@"files"];
    
    BOOL isExist = [[NSFileManager defaultManager] fileExistsAtPath:fullPath];
    if (!isExist) {
        //创建环境文件夹
        [[NSFileManager defaultManager] createDirectoryAtPath:fullPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    self.dataSavePath = fullPath;
        
    self.client = [[LocalAreaPeerClient alloc] init];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didScanQRCode:) name:@"didScanQRCode" object:nil];
    
//    self.ip = @"192.168.5.159";
//    self.ip = @"192.168.2.150";
    self.ip = @"127.0.0.1";
    self.port = 5000;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self startMonitoring];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self stopMonitoring];
}

-(void)startMonitoring
{
    [[AFNetworkReachabilityManager sharedManager] setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        switch (status) {
            case AFNetworkReachabilityStatusReachableViaWiFi:
            {
                self.statusLabel.text = @"请将两台设备接入同一Wi-Fi或相同热点";
                break;
            }
            case AFNetworkReachabilityStatusUnknown:
            case AFNetworkReachabilityStatusNotReachable:
            case AFNetworkReachabilityStatusReachableViaWWAN:
            {
                self.statusLabel.text = @"需通过Wi-Fi迁移聊天记录，请开启并连接Wi-Fi";
                break;
            }
            default:
                break;
        }
        
    }];
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
}

- (void)stopMonitoring
{
    [[AFNetworkReachabilityManager sharedManager] stopMonitoring];
}


- (void)didScanQRCode:(NSNotification*)noti
{
    NSString *value = noti.object;
    NSArray *components = [value componentsSeparatedByString:@";"];
    NSString *ip = components[0];
    uint16_t port = [components[1] integerValue];
    
    BOOL hotpot = [MOAInspectUtility flagWithOpenHotSpot];
    
    //微信旧版逻辑：判断ssid,判断网关
    NSString *myIp = [MOAInspectUtility localIpAddressForCurrentDevice];
    NSString *netmask = [MOAInspectUtility netmask];
    BOOL isSameNet = [MOAInspectUtility isSameLANCompareTheIP:myIp otherIP:ip withSubnetMask:netmask];
    
    //开启了热点
    if (!isSameNet && hotpot) {
        myIp = [MOAInspectUtility hotspotIpAddressForCurrentDevice];
        netmask = [MOAInspectUtility hotspotNetmask];
        isSameNet = [MOAInspectUtility isSameLANCompareTheIP:myIp otherIP:ip withSubnetMask:netmask];
    }
    //NSString *gateway = [MOAInspectUtility getGatewayIpForCurrentWiFi];
    //NSLog(@"gateway:%@",gateway);
    if (isSameNet) {
        self.ip = ip;
        self.port = port;
        [self connectServer];
    }else{
        self.statusLabel.text = @"不在同一个网络！";
//        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" message:@"不在同一个网络！" preferredStyle:UIAlertControllerStyleAlert];
//
//        [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
//
//            }]];
//
//        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (void)connectServer
{
    BOOL succ = [self.client connectToHost:self.ip onPort:self.port delegate:self];
    if (succ) {
        //不一定成功，可能会超时
        self.firstConnectResult = 1;
    }else{
        //失败
        self.firstConnectResult = 2;
    }
    NSLog(@"result:%@",succ?@"succ":@"fail");
}

- (IBAction)reconnect:(id)sender
{
    [self connectServer];
}

- (IBAction)disconnect:(id)sender
{
    [self.client disconnect];
}

- (IBAction)reset:(id)sender
{
//    self.isWaitingAuth = YES;
//    self.isWaitingFileListInfo = NO;
//    self.isWaitingFile = NO;
    self.fileIndex = 0;
    self.files = @[];
    self.fileItems = @[];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.filesTableView reloadData];
    });
    [self.outputStream close];
    self.outputStream = nil;
    self.acceptItem = nil;
    self.dataBuffer = [NSMutableData data];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES);
    NSString *basePath = paths.firstObject;
    
    NSString *fullPath = [basePath stringByAppendingPathComponent:@"files"];
    
    BOOL isExist = [[NSFileManager defaultManager] fileExistsAtPath:fullPath];
    if (isExist) {
        //创建环境文件夹
        [[NSFileManager defaultManager] removeItemAtPath:fullPath error:nil];
        [[NSFileManager defaultManager] createDirectoryAtPath:fullPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
}

- (void)requestFile
{
    if (self.fileIndex >= self.files.count) {
        self.acceptItem = nil;
        return;
    }
    
    ServerSocketItem *fileItem = self.fileItems[self.fileIndex];
    //self.isWaitingFile = YES;
    self.lastTestSpeedDate = [NSDate date];
    self.lastTestTotalSize = fileItem.acceptSize;
    self.totalSize = fileItem.acceptSize;
    
    NSDictionary *file = @{
        @"fileName":fileItem.fileName,
        @"fileType":fileItem.fileType,
        @"fileSize":@(fileItem.fileSize),
        @"id":fileItem.id,
        @"acceptSize":@(fileItem.acceptSize)
    };
    NSDictionary *dict = @{
        @"cmd":REQ_FILE,
        @"file":file
    };

    self.acceptItem = self.fileItems[self.fileIndex];
    self.acceptItem.isWaitAcceptFile = YES;
    [self sendRequest:dict];
    self.isWaitingMsg = NO;
}

- (void)requestFileListInfo
{
    NSDictionary *dict = @{
        @"cmd":REQ_FILE_INFO_LIST,
    };
    [self sendRequest:dict];
}

- (void)requestAuthInfo
{
    NSDictionary *dict = @{
        @"cmd":REQ_AUTH,
        @"userid": @"13665679224"
    };
    [self sendRequest:dict];
}

- (void)socket:(LocalAreaPeerClient *)client connectToServer:(NSString *)host status:(ConnectStatus)status
{
    if (status == ConnectStatusConnected) {
        self.dataBuffer = [NSMutableData data];
        self.statusLabel.text = @"已连接";
        //NSLog(@"isWaitingAuth:%d,isWaitingFileListInfo:%d,isWaitingFile:%d",self.isWaitingAuth,self.isWaitingFileListInfo,self.isWaitingFile);
        [self requestAuthInfo];
        
    }else if(status == ConnectStatusConnectFail){
        self.statusLabel.text = @"连接失败";
    }else if(status == ConnectStatusDisconnected){
        //self.isWaitingAuth = YES;
        if (self.firstConnectResult == 1) {
            self.statusLabel.text = @"连接失败";
        }else {
            self.statusLabel.text = @"连接已断开";
        }
    }
    self.firstConnectResult = 0;
}

- (void)socket:(LocalAreaPeerClient *)tool receiveData:(NSData *)contentData
{
    NSLog(@"receiveData:%d",contentData.length);
    [self recvMsgData:contentData];

//    if (self.isWaitingMsg) {
//        [self recvMsgData:contentData];
//
//    }else{
//    }
}

- (void)handleRecvData:(NSData*)contentData
{
    NSDictionary *dict = [self decodeResponseData:contentData];
    NSLog(@"handleRecvData:%@",dict);
    NSString *cmd = dict[@"cmd"];
    if ([cmd isEqualToString:RSP_AUTH]) {
        BOOL isSameAccount = [dict[@"result"] integerValue] == 1;
        if (isSameAccount) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.statusLabel.text = @"同一个账户";
            });

            if (self.fileItems.count == 0) {
                [self requestFileListInfo];
            }else{
                [self requestFile];
            }

        }else{
            dispatch_async(dispatch_get_main_queue(), ^{
                self.statusLabel.text = @"不是同一个账户";
            });
        }
    }else if ([cmd isEqualToString:RSP_FILE_INFO_LIST]) {
        //self.isWaitingFileListInfo = NO;
        self.files = dict[@"files"];
        self.fileItems = [ServerSocketItem mj_objectArrayWithKeyValuesArray:dict[@"files"]];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.filesTableView reloadData];
        });
        
        self.fileIndex = 0;
        [self requestFile];
    }
}

- (NSMutableData *)dataBuffer {
    if (!_dataBuffer) {
        _dataBuffer = [NSMutableData data];
    }
    return _dataBuffer;
}

#pragma mark -
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.files.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger index = indexPath.row;
    ServerSocketItem *file = self.fileItems[index];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell-id" forIndexPath:indexPath];
    cell.textLabel.text = file.fileName;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%.1fMB,%ld%%",1.0*file.fileSize/1024/1024,file.percent];

    if (index == self.fileIndex) {
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%.1fMB,%ld%%,%.1f MB/s",1.0*file.fileSize/1024/1024,file.percent,1.0*self.speed/1024/1024];
    }
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 45;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger index = indexPath.row;
    ServerSocketItem *file = self.fileItems[index];
    if ([file.fileName hasSuffix:@"mp4"]) {
        NSURL *webVideoUrl = [NSURL fileURLWithPath:file.acceptFilePath];
        AVPlayer *avPlayer = [[AVPlayer alloc] initWithURL:webVideoUrl];
        AVPlayerViewController *avPlayerVC =[[AVPlayerViewController alloc] init];
        avPlayerVC.player = avPlayer;
        [self presentViewController:avPlayerVC animated:YES completion:nil];
    }
}

#pragma mark -private
- (void)sendRequest:(NSDictionary*)params
{
    self.isWaitingMsg = YES;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:params
                                                                        options:NSJSONWritingPrettyPrinted
                                                                        error:nil];
    NSData *aesData = [jsonData BOGAES256EncryptWithKey:APP_PUBLIC_PASSWORD];
    [self sendData:aesData dataType:-1];
}

- (NSDictionary*)decodeResponseData:(NSData*)data
{
    NSData *aesData = [data BOGAES256DecryptWithKey:APP_PUBLIC_PASSWORD];
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:aesData options:NSJSONReadingAllowFragments error:nil];
    return dict;
}

- (void)sendData:(NSData *)data dataType:(int)dataType{
    NSMutableData *mData = [NSMutableData data];
    // 1.计算数据总长度 data
    uint32_t dataLength = OSSwapHostToBigInt32(data.length);
    NSData *lengthData = [NSData dataWithBytes:&dataLength length:4];
    // mData 拼接长度data
    [mData appendData:lengthData];
    
    // 数据类型 data
    // 2.拼接指令类型(4~7:指令)
    int type = OSSwapHostToBigInt32(dataType);
    NSData *typeData = [NSData dataWithBytes:&type length:4];
    // mData 拼接数据类型data
    [mData appendData:typeData];
    
    // 3.最后拼接真正的数据data
    [mData appendData:data];
    NSLog(@"发送数据的总字节大小:%ld",mData.length);
    
    // 发数据
    [self.client sendData:mData];
}


- (void)recvMsgData:(NSData *)data{
    // 整段数据长度(不包含长度跟类型)
    unsigned int headerLength = 8;
    
    BOOL append = NO;
    if (self.dataBuffer.length <headerLength) {
        append = YES;
        [self.dataBuffer appendData:data];
        if (self.dataBuffer.length < headerLength) {
            return;
        }
    }
    
    NSData *totalSizeData = [self.dataBuffer subdataWithRange:NSMakeRange(0, 4)];
    uint32_t totalSize = 0;
    [totalSizeData getBytes:&totalSize length:4];
    totalSize = OSSwapBigToHostInt32(totalSize);
    
    NSData *typeData = [self.dataBuffer subdataWithRange:NSMakeRange(4, 4)];
    int32_t type = 0;
    [typeData getBytes:&type length:4];
    type = OSSwapBigToHostInt32(type);
    
    if (totalSize > 0) {
        
        //包含长度跟类型的数据长度
        unsigned int completeSize = totalSize  + headerLength;
        
        if(!append){
            [self.dataBuffer appendData:data];
        }
        
        if (self.dataBuffer.length < completeSize) {
            //如果缓存的长度 还不如 我们传过来的数据长度，就让socket继续接收数据
            NSLog(@"分包了....completeSize:%d,totalSize:%d",completeSize,totalSize);
            //[self.client readData];
            return;
        }
        //取出数据
        NSData *resultData = [self.dataBuffer subdataWithRange:NSMakeRange(headerLength, totalSize)];
        //处理数据
        if (type == -1) {
            [self handleRecvData:resultData];
        }else{
            [self recvChunkData:resultData];
        }
        //清空刚刚缓存的data
        [self.dataBuffer replaceBytesInRange:NSMakeRange(0, completeSize) withBytes:nil length:0];
        //如果缓存的数据长度还是大于8，再执行一次方法
        if (self.dataBuffer.length > headerLength) {
            [self recvMsgData:nil];
        }
    }else if (totalSize == 0){
        [self.dataBuffer replaceBytesInRange:NSMakeRange(0, headerLength) withBytes:nil length:0];
    }else{
        //异常
    }
}

- (void)recvChunkData:(NSData *)contentData{
    self.chunkTotal+= contentData.length;
    self.totalSize += contentData.length;
    NSDate *now = [NSDate date];
    if ([now timeIntervalSinceDate:self.lastTestSpeedDate] >=1) {
        self.speed = (self.totalSize - self.lastTestTotalSize)/[now timeIntervalSinceDate:self.lastTestSpeedDate];
        self.lastTestTotalSize = self.totalSize;
        self.lastTestSpeedDate = now;
    }
    
    self.acceptItem.finishAccept = NO;
    self.acceptItem.acceptSize += contentData.length;
    //self.acceptItem.beginAccept = YES;
    self.acceptItem.percent = 100*self.acceptItem.acceptSize/self.acceptItem.fileSize;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.filesTableView reloadData];
    });
    
    if (!self.outputStream) {
        self.acceptItem.acceptFilePath = [self.dataSavePath stringByAppendingPathComponent:[self.acceptItem.fileName lastPathComponent]];
        self.outputStream = [[NSOutputStream alloc] initToFileAtPath:self.acceptItem.acceptFilePath append:YES];
        [self.outputStream open];
    }
    // 输出流 写数据
    NSInteger byt = [self.outputStream write:contentData.bytes maxLength:contentData.length];
    NSLog(@"acceptSize = %zd totalSize = %zd",self.acceptItem.acceptSize,self.acceptItem.fileSize);
    if (self.acceptItem.acceptSize == self.acceptItem.fileSize) {
        NSString *checkSum = [[FileChecksumUtil new] fileMD5Hash:self.acceptItem.acceptFilePath];
        if (!self.acceptItem.checkSum || [checkSum isEqualToString:self.acceptItem.checkSum]) {
            self.acceptItem.finishAccept = YES;
            [self.outputStream close];
            self.outputStream = nil;
            self.chunkTotal = 0;
            
            self.fileIndex++;
            NSLog(@"接收下一个%ld",(long)self.fileIndex);
            if (self.fileIndex < self.fileItems.count) {
                [self requestFile];
            }else{
                //[self importFiles];
            }
        }
    }
}
@end
