//  RSAEncryptor.h
//  RAS签名
//
//  Created by user on 16/7/6.
//  Copyright © 2016年 user. All rights reserved.
//
 
#import <Foundation/Foundation.h>
 
@interface RSA_Encryptor : NSObject
 
 
#pragma mark 初始化对象
+(RSA_Encryptor *)sharedRSA_Encryptor;
 
#pragma mark - 使用 公钥加密、私钥解密
 
/**
 *  私钥 加密
 *
 *  @param string       需加密字符串
 *  @param publicKeyStr 公钥
 *
 *  @return 公钥加密 后的字符串
 */
- (NSString *)encryptorString:(NSString *)string PublicKeyStr:(NSString *)publicKeyStr;
 
 
/**
 *   私钥证书 加密
 *
 *  @param string 需加密字符串
 *  @param path   公钥证书 文件路径
 *
 *  @return 公钥证书 加密 后的字符串
 */
- (NSString *)encryptorString:(NSString *)string PublicKeyPath:(NSString *)path;
 
 
// 解密
 
/**
 *  私钥 解密
 *
 *  @param string        公钥 加密的字符串（需要加密字符串）
 *  @param privateKeyStr 私钥
 *
 *  @return 解密后字符串
 */
- (NSString *)decryptString:(NSString *)string PrivateKeyStr:(NSString *)privateKeyStr;
 
 
/**
 *  私钥证书 解密
 *
 *  @param string       公钥证书 加密的字符串（需要加密字符串）
 *  @param path         私钥证书文件路径
 *  @param p12Passwoerd 私钥证书密码
 *
 *  @return 解密后字符串
 */
- (NSString *)decryptString:(NSString *)string PrivateKeyPath:(NSString *)path PassWord:(NSString *)p12Passwoerd;
 
#pragma mark - 使用、公钥解密 （注：解密的字符串是使用私钥加密过后的）
- (NSString *)decryptString:(NSString *)string PublicKeyStr:(NSString *)publicKeyStr;
 
@end
