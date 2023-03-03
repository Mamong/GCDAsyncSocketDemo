//
//  ScanViewController.m
//  GCDAsyncSocketDemo
//
//  Created by tryao on 2022/6/15.
//

#import "ScanViewController.h"
#import <AVFoundation/AVFoundation.h>

@interface ScanViewController ()<AVCaptureMetadataOutputObjectsDelegate>
//捕获会话
@property (nonatomic,strong) AVCaptureSession *session;

//预览图层，可以通过输出设备展示被捕获的数据流。
@property (nonatomic,strong) AVCaptureVideoPreviewLayer *previewLayer;
@end

@implementation ScanViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self startScan];
}

- (void)startScan {
    //1.实例化拍摄设备
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo]; //媒体类型

    //2.设置输入设备
    NSError *error = nil;
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
    if (error) {
        //防止模拟器崩溃
        NSLog(@"没有摄像头设备");
        return;
    }

    //3.设置元数据输出
    //实例化拍摄元数据输出
    AVCaptureMetadataOutput *output=[[AVCaptureMetadataOutput alloc]init];
    //设置输出数据代理
    [output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];

    //4.添加拍摄会话
    //实例化拍摄会话
    AVCaptureSession *session =[[AVCaptureSession alloc]init];
    [session setSessionPreset:AVCaptureSessionPresetHigh];//预设输出质量
    //添加会话输入
    [session addInput:input];
    //添加会话输出
    [session addOutput:output];
    //添加会话输出条码类型
    [output setMetadataObjectTypes:@[AVMetadataObjectTypeQRCode]];
    self.session = session;

    //5.视频预览图层
    //实例化预览图层
    AVCaptureVideoPreviewLayer *preview = [AVCaptureVideoPreviewLayer layerWithSession:_session];
    preview.videoGravity = AVLayerVideoGravityResizeAspectFill;
    preview.frame = self.view.bounds;
    //将图层插入当前视图
    [self.view.layer insertSublayer:preview atIndex:100];
    self.previewLayer = preview;

    //6.启动会话
    [_session startRunning];
}

//获得的数据在此方法中
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection{
    // 会频繁的扫描，调用代理方法
    // 1. 如果扫描完成，停止会话
    [self.session stopRunning];
    // 2. 删除预览图层
    [self.previewLayer removeFromSuperlayer];
    // 3. 设置界面显示扫描结果
    //判断是否有数据
    if (metadataObjects.count > 0) {
        AVMetadataMachineReadableCodeObject *obj = metadataObjects[0];
        //如果需要对url或者名片等信息进行扫描，可以在此进行扩展
        [[NSNotificationCenter defaultCenter] postNotificationName:@"didScanQRCode" object:obj.stringValue userInfo:nil];
    }
    //结束扫描
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}
@end
