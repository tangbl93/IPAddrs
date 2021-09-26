//
//  IPAddrs.h
//  IPAddrs
//
//  Created by tangbl93 on 2021/9/15.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface IPAddrs : NSObject

+ (instancetype)shared;

/// 获取本地全部IP地址
@property(nonatomic, copy, readonly) NSDictionary *allIPAddrs;

/// 重新加载数据
- (void)reloadData;

/// 替换为本地IP形式展示(不存在替换为0.0.0.0)
+ (NSString *)stringValue:(NSString *)localIPAddress;

#pragma mark - WIFI/IPv4

// WIFI IP
@property(nonatomic, copy, readonly) NSString *WIFI_address;
// WIFI 广播地址
@property(nonatomic, copy, readonly) NSString *WIFI_broadcast;
// WIFI 子网掩码
@property(nonatomic, copy, readonly) NSString *WIFI_netmask;
// WIFI 网关(路由器IP) *真实
// 有热点连接时，获取的地址为空
@property(nonatomic, copy, readonly) NSString *WIFI_gateway;
// WIFI 网关(路由器IP)(与上一个获取方式不同)
// 手动设置时可读取到，自动设置时读取的是蜂窝网络地址(pdp_ip0/ipv4)。
// 飞行模式下为空。蜂窝网络未打开时，默认就是设置中的网关地址
@property(nonatomic, copy, readonly) NSString *WIFI_defaultgateway;
// WIFI 网关是否手动设置过
@property(nonatomic, assign, readonly) BOOL WIFI_gatewayManual;
// WIFI 局域网中扫描到的客户端
@property(nonatomic, copy, readonly) NSArray<NSString *> *WIFI_clients;

#pragma mark - HOTSPOT/IPv4

/// 是否打开热点
@property(nonatomic, assign, readonly) BOOL HOTSPOT_isEnabled;
/// 本机热点地址
@property(nonatomic, copy, readonly) NSString *HOTSPOT_address;
/// 本机热点连接中的地址
@property(nonatomic, copy, readonly) NSArray<NSString *> *HOTSPOT_clients;

#pragma mark - CELLULAR/IPv4

/// 蜂窝移动网络地址
@property(nonatomic, copy, readonly) NSString *CELLULAR_address;

@end

NS_ASSUME_NONNULL_END
