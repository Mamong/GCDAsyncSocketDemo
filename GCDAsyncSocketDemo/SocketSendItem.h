//
//  SocketSendItem.h
//  GCDAsyncSocketDemo
//
//  Created by tryao on 2022/6/15.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, SENDFILE_TYPE)
{
    SENDFILE_TYPE_FILEINFOLIST = 0,// 列表
    SENDFILE_TYPE_IMAGE = 1,   // 图片
    SENDFILE_TYPE_VIDEO,       // 视频
    SENDFILE_TYPE_AUDIO,       // 音频
    SENDFILE_TYPE_TEXT         // 文字
};

@interface SocketSendItem : NSObject
/// 文件名称
@property (nonatomic, copy) NSString *fileName;
/// 文件类型
@property (nonatomic, assign) SENDFILE_TYPE type;
/// 文件总大小
@property (nonatomic, assign) NSInteger fileSize;
/// 文件类型
@property (nonatomic, copy) NSString *typeStr;


/// 文件已上传大小
@property (nonatomic, assign) NSInteger upSize;

/// 资源路径
@property (nonatomic, copy) NSURL *filePath;
/// id 序列号
@property (nonatomic, assign) NSInteger index;
/// 是否正在上传中
@property (nonatomic, assign) BOOL isSending;
/// 当前文件是否已经全部传输完毕
@property (nonatomic, assign) BOOL isSendFinish;

/// 资源文件
@property (nonatomic, strong) id asset;
/// 缩略图路径
@property (nonatomic, copy) NSString *thumImgPath;
/// 是否需要取消传输(isSending = NO && isSendFinish = NO)时有效
@property (nonatomic, assign) BOOL isCancleSend;
@end

NS_ASSUME_NONNULL_END
