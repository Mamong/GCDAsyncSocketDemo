//
//  FileChecksumUtil.h
//  GCDAsyncSocketDemo
//
//  Created by tryao on 2022/6/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface FileChecksumUtil : NSObject

- (NSString *)fileMD5Hash:(NSString*)filePath;

- (NSString *)fileSHA1Hash:(NSString*)filePath;

- (NSString *)fileSHA256Hash:(NSString*)filePath;

- (NSString *)fileSHA512Hash:(NSString*)filePath;

@end

NS_ASSUME_NONNULL_END
