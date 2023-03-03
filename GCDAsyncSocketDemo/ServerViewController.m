//
//  ServerViewController.m
//  GCDAsyncSocketDemo
//
//  Created by tryao on 2022/6/15.
//

#import "ServerViewController.h"
#import <CoreImage/CoreImage.h>
#import <MJExtension/MJExtension.h>
#import "AFNetworkReachabilityManager.h"

#import "LocalAreaPeerServer.h"
#import "ServerSocketItem.h"
#import "MOAInspectUtility.h"
#import "NSData+AES.h"
#import "FileChecksumUtil.h"

#define REQ_AUTH @"REQ_AUTH"
#define RSP_AUTH @"RSP_AUTH"
#define REQ_FILE_INFO_LIST @"REQ_FILE_INFO_LIST"
#define RSP_FILE_INFO_LIST @"RSP_FILE_INFO_LIST"
#define REQ_FILE @"REQ_FILE"

#define APP_PUBLIC_PASSWORD @"A1B@C#F4G5H6~*71"

@interface ServerViewController ()<LocalAreaPeerServerDelegate>
@property(nonatomic, strong)LocalAreaPeerServer *server;
@property(nonatomic, strong) NSArray *files;
@property (nonatomic, strong) NSFileHandle *fileHandle;
@property(nonatomic, strong) ServerSocketItem *uploadItem;
@property (nonatomic, strong) NSMutableData *dataBuffer;

@property(nonatomic, assign) NSInteger lastChunkLength;
@property(nonatomic, strong) NSString *client;
@end

@implementation ServerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.qrcodeImageView.userInteractionEnabled = YES;
    UITapGestureRecognizer *ges = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(generateQRCode)];
    [self.qrcodeImageView addGestureRecognizer:ges];
    
    self.server = [[LocalAreaPeerServer alloc]init];
    [self loadFiles];
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


-(IBAction)startListen:(id)sender
{
    uint16_t port = [self.portField.text intValue];
    bool success = [self.server listenOnPort:port delegate:self];
    if (success) {
        self.statusLabel.text = [NSString stringWithFormat:@"监听端口%hu成功",port];
        [self generateQRCode];
    }else{
        self.statusLabel.text = [NSString stringWithFormat:@"监听端口%hu失败",port];
    }
}

- (IBAction)disconnect:(id)sender
{
    [self.server disconnect:self.client];
}

- (IBAction)unbind:(id)sender
{
    [self.server disconnect];
}

- (void)loadFiles
{
    NSArray<NSString*> *paths = [[NSBundle mainBundle] pathsForResourcesOfType:@"" inDirectory:@"files"];
    NSMutableArray *arr = [NSMutableArray array];
    FileChecksumUtil *util = [FileChecksumUtil new];
    for (NSString *path in paths) {
        NSDictionary *atts = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil];
        
        NSString *name = [path lastPathComponent];
        NSString *type = [path pathExtension];
        long long fileSize = [atts[@"NSFileSize"] longLongValue];
        NSString *size = [NSByteCountFormatter stringFromByteCount:fileSize countStyle:NSByteCountFormatterCountStyleBinary];
        [arr addObject:@{@"fileName":name,@"fileType":@(0),@"fileSize":@(fileSize),@"filePath":path, @"checkSum":[util fileMD5Hash:path]}];
    }
    self.files = [arr copy];
    [self.filesTableView reloadData];
}

/**
 服务端发送列表信息给客户端，客户端接收完成后，发送确认消息FILE_LIST_SEND_END
 服务端收到确认消息FILE_LIST_SEND_END，发送文件1。客户端接收完成后，发送确认消息FILE_SEND_END。
 服务端收到FILE_SEND_END后发送下一个文件。
 */
- (void)sendFiles
{
    //NSString *client = [self.server.clientDict.allKeys firstObject];
    //[self sendString:SEND_FILE_INFO_LIST to:client];
    //[self sendFilesInfo];
}

- (void)sendAuthResult:(int)result
{
    NSDictionary *dict = @{
        @"cmd":RSP_AUTH,
        @"result":@(result)
    };

    [self sendRequest:dict];
}

- (void)sendFilesInfo
{
    NSDictionary *dict = @{
        @"cmd":RSP_FILE_INFO_LIST,
        @"files":self.files
    };

    [self sendRequest:dict];
}

- (void)prepareSendFile
{
    if (self.fileHandle) {
        [self.fileHandle closeFile];
        self.fileHandle = nil;
    }
    self.uploadItem.upSize = self.uploadItem.acceptSize;
    self.fileHandle = [NSFileHandle fileHandleForReadingAtPath:self.uploadItem.filePath];
    NSInteger acceptSize = self.uploadItem.acceptSize;
    [self.fileHandle seekToFileOffset:acceptSize];
}

- (void)sendFileChunk:(int)tag
{
    NSString *client = [self.server.clientDict.allKeys firstObject];
    if (!self.fileHandle) {
        return;
    }
    
    const NSInteger length = 4*1024;
    NSData *sendData = nil;
    if (@available(iOS 13.0, *)) {
        sendData = [self.fileHandle readDataUpToLength:length error:nil];
    } else {
        sendData = [self.fileHandle readDataOfLength:length];
    }
    self.lastChunkLength = sendData.length;
    [self sendData:sendData dataType:tag tag:1];

//    if (isFirst) {
//        NSInteger size = self.uploadItem.fileSize - self.uploadItem.acceptSize;
//        [self sendData:sendData dataType:1 tag:1 length:size];
//    }else{
//        [self.server sendData:sendData to:client tag:1];
//    }
}

- (void)finishSendFile
{
    [self.fileHandle closeFile];
    self.fileHandle = nil;
    self.uploadItem = nil;
}


#pragma mark -
- (void)socket:(LocalAreaPeerServer *)server connectToClient:(NSString*)host status:(ConnectStatus)status
{
    if (status == ConnectStatusConnected) {
        self.dataBuffer = [NSMutableData data];
        self.statusLabel.text = [NSString stringWithFormat:@"%@连接成功",host];
    }else if (status == ConnectStatusDisconnected){
        self.statusLabel.text = [NSString stringWithFormat:@"%@连接已断开",host];
    }
}

- (void)socket:(LocalAreaPeerServer *)server receiveData:(NSData *)contentData fromClient:(nonnull NSString *)client
{
    [self recvMsgData:contentData client:client];
}

- (void)socket:(LocalAreaPeerServer *)server didWriteDataWithTag:(long)tag
{
    if (tag == 1) {
        self.uploadItem.upSize += self.lastChunkLength;
        if (self.uploadItem.upSize < self.uploadItem.fileSize) {
            [self sendFileChunk:1];
        }else if (self.uploadItem.upSize == self.uploadItem.fileSize){
            NSLog(@"finishSendFile");
            [self finishSendFile];
        }
    }
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
    NSDictionary *file = self.files[index];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell-id" forIndexPath:indexPath];
    cell.textLabel.text = file[@"fileName"];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@",file[@"fileSize"]];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 45;
}


-(void)generateQRCode
{
    NSString *wifiName = [MOAInspectUtility getWifiName];
    NSString *ip = [MOAInspectUtility localIpAddressForCurrentDevice];
    if ([MOAInspectUtility flagWithOpenHotSpot]) {
        ip = [MOAInspectUtility hotspotIpAddressForCurrentDevice];
    }
    if (!ip) {
        self.statusLabel.text = @"请连接WiFi";
        return;
    }
    NSLog(@"ip:%@,wifi:%@",ip,wifiName);
    
    
    // 1.创建过滤器 -- 苹果没有将这个字符封装成常量
     CIFilter *filter = [CIFilter filterWithName:@"CIQRCodeGenerator"];
     
     // 2.过滤器恢复默认设置
     [filter setDefaults];
     
     // 3.给过滤器添加数据(正则表达式/帐号和密码) -- 通过KVC设置过滤器,只能设置NSData类型
    NSString *dataString = [NSString stringWithFormat:@"%@;%@",ip,self.portField.text];
     NSData *data = [dataString dataUsingEncoding:NSUTF8StringEncoding];
     [filter setValue:data forKeyPath:@"inputMessage"];
     
     // 4.获取输出的二维码
     CIImage *outputImage = [filter outputImage];
    
    self.qrcodeImageView.image = [self createNonInterpolatedUIImageFormCIImage:outputImage withSize:self.qrcodeImageView.bounds.size.width];
}

- (UIImage *)createNonInterpolatedUIImageFormCIImage:(CIImage *)image withSize:(CGFloat) size
 {
     CGRect extent = CGRectIntegral(image.extent);
     CGFloat scale = MIN(size/CGRectGetWidth(extent), size/CGRectGetHeight(extent));
     
     // 1.创建bitmap;
     size_t width = CGRectGetWidth(extent) * scale;
     size_t height = CGRectGetHeight(extent) * scale;
     CGColorSpaceRef cs = CGColorSpaceCreateDeviceGray();
     CGContextRef bitmapRef = CGBitmapContextCreate(nil, width, height, 8, 0, cs, (CGBitmapInfo)kCGImageAlphaNone);
     CIContext *context = [CIContext contextWithOptions:nil];
     CGImageRef bitmapImage = [context createCGImage:image fromRect:extent];
     CGContextSetInterpolationQuality(bitmapRef, kCGInterpolationNone);
     CGContextScaleCTM(bitmapRef, scale, scale);
     CGContextDrawImage(bitmapRef, extent, bitmapImage);
     
     // 2.保存bitmap到图片
     CGImageRef scaledImage = CGBitmapContextCreateImage(bitmapRef);
     CGContextRelease(bitmapRef);
     CGImageRelease(bitmapImage);
     return [UIImage imageWithCGImage:scaledImage];
 }

- (void)handleRecvData:(NSData*)contentData client:(NSString*)client
{
    NSDictionary *dict = [self decodeResponseData:contentData];
    NSString *cmd = dict[@"cmd"];
    
    if ([dict isKindOfClass:[NSDictionary class]]) {
        if ([cmd isEqualToString:REQ_AUTH]) {
            NSLog(@"REQ_AUTH");
            self.client = client;
            NSString *userid = dict[@"userid"];
            [self sendAuthResult:1];
        }
        else if ([cmd isEqualToString:REQ_FILE_INFO_LIST]) {
            NSLog(@"REQ_FILE_INFO_LIST");
            [self sendFilesInfo];
        }else if ([cmd isEqualToString:REQ_FILE]) {
            NSLog(@"REQ_FILE");
            NSDictionary *file = dict[@"file"];
            self.uploadItem = [ServerSocketItem mj_objectWithKeyValues:file];
            [self prepareSendFile];
            [self sendFileChunk:1];
        }
    }
}

#pragma mark -private
- (void)sendRequest:(NSDictionary*)params
{
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:params
                                                                        options:NSJSONWritingPrettyPrinted
                                                                        error:nil];
    NSData *aesData = [jsonData BOGAES256EncryptWithKey:APP_PUBLIC_PASSWORD];
    [self sendData:aesData dataType:-1 tag:0];
}

- (NSDictionary*)decodeResponseData:(NSData*)data
{
    NSData *aesData = [data BOGAES256DecryptWithKey:APP_PUBLIC_PASSWORD];
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:aesData options:NSJSONReadingAllowFragments error:nil];
    return dict;
}

- (void)sendData:(NSData *)data dataType:(int)dataType tag:(NSInteger)tag{
    NSMutableData *mData = [NSMutableData data];
    // 1.计算数据总长度 data
    uint32_t dataLength = (uint32_t)data.length;
    dataLength = OSSwapHostToBigInt32(dataLength);

    // 将长度转成data
    NSData *lengthData = [NSData dataWithBytes:&dataLength length:4];
    // mData 拼接长度data
    [mData appendData:lengthData];
    
    // 数据类型 data
    // 2.拼接指令类型(4~7:指令)
    int32_t type = OSSwapHostToBigInt32(dataType);
    NSData *typeData = [NSData dataWithBytes:&type length:4];
    // mData 拼接数据类型data
    [mData appendData:typeData];
    
    // 3.最后拼接真正的数据data
    [mData appendData:data];
    NSLog(@"发送数据的总字节大小:%ld",mData.length);
    
    // 发数据
    [self.server sendData:mData to:self.client tag:tag];
}

- (void)recvMsgData:(NSData *)data client:(NSString*)client{
    //直接就给他缓存起来
    if(data) [self.dataBuffer appendData:data];
    // 获取总的数据包大小
    // 整段数据长度(不包含长度跟类型)
    NSData *totalSizeData = [self.dataBuffer subdataWithRange:NSMakeRange(0, 4)];
    uint32_t totalSize = 0;
    unsigned int headerLength = 8;
    [totalSizeData getBytes:&totalSize length:4];
    totalSize = OSSwapBigToHostInt32(totalSize);
    //包含长度跟类型的数据长度
    unsigned int completeSize = totalSize  + headerLength;
    //必须要大于8 才会进这个循环
    while (self.dataBuffer.length>headerLength) {
        if (self.dataBuffer.length < completeSize) {
            //如果缓存的长度 还不如 我们传过来的数据长度，就让socket继续接收数据
            [self.server readDataFromClient:client];
            break;
        }
        //取出数据
        NSData *resultData = [self.dataBuffer subdataWithRange:NSMakeRange(headerLength, totalSize)];
        //处理数据
        [self handleRecvData:resultData client:client];
        //清空刚刚缓存的data
        [self.dataBuffer replaceBytesInRange:NSMakeRange(0, completeSize) withBytes:nil length:0];
        //如果缓存的数据长度还是大于8，再执行一次方法
        if (self.dataBuffer.length > headerLength) {
            [self recvMsgData:nil client:client];
        }
    }
}

- (NSMutableData *)dataBuffer {
    if (!_dataBuffer) {
        _dataBuffer = [NSMutableData data];
    }
    return _dataBuffer;
}

@end
