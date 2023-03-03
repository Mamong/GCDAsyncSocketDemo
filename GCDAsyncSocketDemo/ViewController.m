//
//  ViewController.m
//  GCDAsyncSocketDemo
//
//  Created by tryao on 2022/6/15.
//

#import "ViewController.h"
#import "ServerViewController.h"
#import "ClientViewController.h"
#import "RSAEncryptor.h"

#define RSA_PUBLIC_KEY  @"-----BEGIN PUBLIC KEY-----\nMIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQC2IUXzxYudB9+AeVZRoGaRaCkUEpIGAi7pMfDv98/akGoDZXt8LOeGQDLQrXxn78YLPlrC2lBUKuDAOtdkacGZidQwzOeS8IgdU2caN0dq9IFGlZb9Ud+ryIXgyj+mfQB5Df0vsm/DGA7j6vFxqbNfv/To0Dhd0375lb5aj7yr/QIDAQAB\n-----END PUBLIC KEY-----"
#define RSA_PRIVATE_KEY  @"MIICdwIBADANBgkqhkiG9w0BAQEFAASCAmEwggJdAgEAAoGBALYhRfPFi50H34B5VlGgZpFoKRQSkgYCLukx8O/3z9qQagNle3ws54ZAMtCtfGfvxgs+WsLaUFQq4MA612RpwZmJ1DDM55LwiB1TZxo3R2r0gUaVlv1R36vIheDKP6Z9AHkN/S+yb8MYDuPq8XGps1+/9OjQOF3TfvmVvlqPvKv9AgMBAAECgYAScoBRVprzhs6ehqu1jNeWtsQiYlckAKibuhE7XRBShPoX6fl99FZnBK2g8VF+fYzDqscqoU4tmEI3dj5Gz2dqaALz1d1m0H9z8MJyP+/oSDTDlwAq4KHhZYj38Gy0xjGxlpRRoDdWNm4hG3Ysvpx5rmINpB8HJqjbSedn5OSXiQJBAOCKf1BiE0oOGY1H7wzo3vxEEYuH5uxclOxew4nE22CrxAK8RqxywxvFp10GHzxsUO+xSx0i6da6Bgs6HMQH6KsCQQDPpaPhNS2pyHDUdA05P+rCl50FmDt3TN1XoGKxm1+1a1CvZLEBUsD6WDfJuVUsXN/2JWEk+0Gh6G8ToUAs3433AkEAg1zjUN6f1FJdZocv9kiCs+kKrqvKUHt1cLecBAyUH4E9wi/t1NOrC6Nd35FGUu43h5Mck6YqUcIw6P6Nd6380wJAByHOVi7oaZt73KA70AqU+qgQeZ+38yoNtDPLEAShLe8Ir22K8tuvyyl6iRA3j7WE78Rq6MVEhNYh8o+oT6JCEwJBALkEV98syyoQLVfSdxBY5P0dAXy7lQNgJ1enYMlxThD7HxHLN4z7wqfGUvb7V/wHYTc1jxpxKz2WzCJ10TnHBUk="

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
//    BOOL a = [@"0" boolValue];
//    BOOL b = [@"1" boolValue];
    NSLog(@"=====");
    
    RSA_Encryptor *rsa = [RSA_Encryptor sharedRSA_Encryptor];
    NSString *encryptedString = [rsa encryptorString:@"这是需要RSA加密字符串" PublicKeyStr:RSA_PUBLIC_KEY];
    NSLog(@"加密==：%@",encryptedString);
    NSString *decryptedString = [rsa decryptString:encryptedString PrivateKeyStr:RSA_PRIVATE_KEY];
    NSLog(@"解密==：%@",decryptedString);
}

-(IBAction)onPressServer:(id)sender
{
    ServerViewController *vc = [[ServerViewController alloc] init];
    vc.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:vc animated:YES completion:nil];
}

-(IBAction)onPressClient:(id)sender
{
    ClientViewController *vc = [[ClientViewController alloc] init];
    vc.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:vc animated:YES completion:nil];
}
@end
