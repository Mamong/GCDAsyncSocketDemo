//
//  MOAInspectUtility.h
//  GCDAsyncSocketDemo
//
//  Created by tryao on 2022/6/15.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MOAInspectUtility : NSObject

+ (NSString *)getWifiName;

+ (NSString *)localIpAddressForCurrentDevice;

+ (NSString *)netmask;

+ (NSString *)hotspotIpAddressForCurrentDevice;

+ (NSString *)hotspotNetmask;

+ (BOOL)isSameLANCompareTheIP:(NSString*)ip otherIP:(NSString*)otherIp withSubnetMask:(NSString*)subnetMask;

+ (NSString *)getGatewayIpForCurrentWiFi;

+ (BOOL)isBatteryChargeAndLevel:(float *)level;

+ (unsigned long long)getFreeDiskSizeInBytes;

+ (BOOL)flagWithOpenHotSpot;
@end

NS_ASSUME_NONNULL_END
