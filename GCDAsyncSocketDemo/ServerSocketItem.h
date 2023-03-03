//
//  ServerSocketItem.h
//  GCDAsyncSocketDemo
//
//  Created by tryao on 2022/6/17.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ServerSocketItem : NSObject

@property (nonatomic, copy) NSString *fileName;
@property (nonatomic, copy) NSString *fileType;
@property (nonatomic, assign) NSInteger fileSize;
@property (nonatomic, copy) NSString *filePath;
@property (nonatomic, copy) NSString *checkSum;

@property (nonatomic, strong) NSString *id;

@property (nonatomic, assign) NSInteger acceptSize;
@property (nonatomic, assign) NSInteger upSize;

@property (nonatomic, assign) BOOL beginAccept;
@property (nonatomic, assign) BOOL isWaitAcceptFile;
@property (nonatomic, assign) BOOL isCancel;
@property (nonatomic, assign) BOOL isSending;
@property (nonatomic, assign) NSInteger ID;



@property (nonatomic, assign) BOOL finishAccept;
@property (nonatomic, copy) NSString *acceptFilePath;

@property (nonatomic, assign) NSInteger percent;

@end

NS_ASSUME_NONNULL_END
