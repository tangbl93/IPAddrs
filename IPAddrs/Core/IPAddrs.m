//
//  IPAddrs.m
//  IPAddrs
//
//  Created by tangbl93 on 2021/9/15.
//

#import "IPAddrs.h"

#pragma mark - gateway
#include <ifaddrs.h>
#include <arpa/inet.h>
#include <net/if.h>
#include "getgateway.h"

#pragma mark - hotspot
#include "route.h"
#include "if_types.h"
#include "if_ether.h"
#include <net/if_dl.h>
#include <sys/sysctl.h>

#define IOS_CELLULAR    @"pdp_ip0"
#define IOS_WIFI        @"en0"
#define IOS_VPN         @"utun0"
#define IOS_HOTSPOT     @"bridge100"
#define IP_ADDR_IPv4    @"ipv4"
#define IP_ADDR_IPv6    @"ipv6"

@interface IPAddrs ()

@property(nonatomic, copy, readwrite) NSDictionary *allIPAddrs;

#pragma mark - WIFI

// WIFI IP
@property(nonatomic, copy, readwrite) NSString *WIFI_address;
// WIFI 广播地址
@property(nonatomic, copy, readwrite) NSString *WIFI_broadcast;
// WIFI 子网掩码
@property(nonatomic, copy, readwrite) NSString *WIFI_netmask;
// WIFI 网关(路由器IP) * 真实
@property(nonatomic, copy, readwrite) NSString *WIFI_gateway;
// WIFI 网关(路由器IP)
@property(nonatomic, copy, readwrite) NSString *WIFI_defaultgateway;
// WIFI 局域网中扫描到的客户端
@property(nonatomic, copy, readwrite) NSArray<NSString *> *WIFI_clients;


#pragma mark - HOTSPOT/IPv4

/// 本机热点连接中的地址
@property(nonatomic, copy, readwrite) NSArray<NSString *> *HOTSPOT_clients;

@end

@implementation IPAddrs

+ (instancetype)shared {
    static IPAddrs *_shared;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _shared = [[IPAddrs alloc] init];
    });
    return _shared;
}

#pragma mark -

- (void)reloadData {
    [self reloadIPData];
    [self reloadWIFIData];
    [self reloadHOTSPOTData];
}

//{
//    "bridge100/ipv4" = "172.20.10.1";
//    "bridge100/ipv6" = "2409:8950:487:db29:c474:dbe4:84fe:40e4";
//    "en0/ipv4" = "192.168.0.189";
//    "en0/ipv6" = "fe80::4b4:4a6a:3364:e9ad";
//    "ipsec0/ipv6" = "2409:8150:41f:6ca5:1085:66c3:5df6:a6e3";
//    "ipsec1/ipv6" = "2409:8150:41f:6ca5:1085:66c3:5df6:a6e3";
//    "llw0/ipv6" = "fe80::40a6:fdff:fe0e:a72d";
//    "lo0/ipv4" = "127.0.0.1";
//    "lo0/ipv6" = "fe80::1";
//    "pdp_ip0/ipv4" = "10.179.86.194";
//    "pdp_ip0/ipv6" = "2409:8950:487:db29:8909:d833:e888:930e";
//    "pdp_ip1/ipv6" = "2409:8150:41f:6ca5:e593:3c54:408d:6e11";
//    "utun0/ipv6" = "fe80::6ac3:ba09:d56d:ea6f";
//    "utun1/ipv6" = "fe80::3dd2:c36a:cf8b:a16";
//}
- (void)reloadIPData {
    NSMutableDictionary *addresses = [NSMutableDictionary dictionary];

    // retrieve the current interfaces - returns 0 on success
    struct ifaddrs *interfaces;
    int success = getifaddrs(&interfaces);
    if (success == 0) {
        // Loop through linked list of interfaces
        for (struct ifaddrs *temp_addr = interfaces; temp_addr; temp_addr = temp_addr->ifa_next) {
            if(!(temp_addr->ifa_flags & IFF_UP) /* || (temp_addr->ifa_flags & IFF_LOOPBACK) */ ) {
                continue; // deeply nested code harder to read
            }
            const struct sockaddr_in *addr = (const struct sockaddr_in*)temp_addr->ifa_addr;
            char addrBuf[ MAX(INET_ADDRSTRLEN, INET6_ADDRSTRLEN) ];
            if(addr && (addr->sin_family==AF_INET || addr->sin_family==AF_INET6)) {
                NSString *name = [NSString stringWithUTF8String:temp_addr->ifa_name];
                NSString *type;
                if(addr->sin_family == AF_INET) {
                    if(inet_ntop(AF_INET, &addr->sin_addr, addrBuf, INET_ADDRSTRLEN)) {
                        type = IP_ADDR_IPv4;
                    }
                } else {
                    const struct sockaddr_in6 *addr6 = (const struct sockaddr_in6*)temp_addr->ifa_addr;
                    if(inet_ntop(AF_INET6, &addr6->sin6_addr, addrBuf, INET6_ADDRSTRLEN)) {
                        type = IP_ADDR_IPv6;
                    }
                }
                if(type) {
                    NSString *key = [NSString stringWithFormat:@"%@/%@", name, type];
                    addresses[key] = [NSString stringWithUTF8String:addrBuf];
                }
            }
        }
        
        // Free memory
        freeifaddrs(interfaces);
    }
    
    self.allIPAddrs = [addresses copy];
}

- (void)reloadWIFIData {
    
    // WIFI_gateway
    int r;
    struct in_addr gatewayaddr;
    r = getgateway(&(gatewayaddr.s_addr));
    if (r >= 0) {
        self.WIFI_gateway = [NSString stringWithFormat: @"%s",inet_ntoa(gatewayaddr)];
    } else {
        self.WIFI_gateway = nil;
    }
    // WIFI_defaultgateway
    r = getdefaultgateway(&(gatewayaddr.s_addr));
    if (r >= 0) {
        self.WIFI_defaultgateway = [NSString stringWithFormat: @"%s",inet_ntoa(gatewayaddr)];
    } else {
        self.WIFI_defaultgateway = nil;
    }
    
    // WIFI_address + WIFI_broadcast + WIFI_netmask
    struct ifaddrs *interfaces;
    int success = getifaddrs(&interfaces);
    if (success == 0) {
        // Loop through linked list of interfaces
        for (struct ifaddrs *temp_addr = interfaces; temp_addr; temp_addr = temp_addr->ifa_next) {
            if(!(temp_addr->ifa_flags & IFF_UP) /* || (temp_addr->ifa_flags & IFF_LOOPBACK) */ ) {
                continue; // deeply nested code harder to read
            }
            NSString *name = [NSString stringWithUTF8String:temp_addr->ifa_name];
            const struct sockaddr_in *addr = (const struct sockaddr_in*)temp_addr->ifa_addr;
            if(addr && (addr->sin_family==AF_INET) && [name isEqualToString:IOS_WIFI]) {
                self.WIFI_address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                self.WIFI_broadcast = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_dstaddr)->sin_addr)];
                self.WIFI_netmask = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_netmask)->sin_addr)];
            }
        }
        // Free memory
        freeifaddrs(interfaces);
        
        // WIFI_clients
        NSString *wifiRegex = @"192.168.";
        self.WIFI_clients = [self searchARPClients:wifiRegex];
    } else {
        self.WIFI_address = nil;
        self.WIFI_broadcast = nil;
        self.WIFI_netmask = nil;
        self.WIFI_clients = nil;
    }
}

- (void)reloadHOTSPOTData {
    // HOTSPOT_clients
    NSString *hotspotRegex = @"172.20.10.";
    self.HOTSPOT_clients = [self searchARPClients:hotspotRegex];
}

# pragma mark - Utilities

- (NSString *)searchIPAddress:(NSArray<NSString *> *)regex {
    NSDictionary *addresses = self.allIPAddrs.copy;

    __block NSString *address;
    [regex enumerateObjectsUsingBlock:^(NSString *key, NSUInteger idx, BOOL *stop) {
        address = addresses[key];
        if(address) *stop = YES;
    }];
    return address;
}

- (NSString *)queryIPAddress:(NSString *)regex {
    NSDictionary *addresses = self.allIPAddrs.copy;
    return [addresses valueForKey:regex];
}

- (NSArray<NSString *> *)searchARPClients:(NSString *)prefix {
    
    int mib[6] = {CTL_NET, PF_ROUTE, 0, AF_INET, NET_RT_FLAGS, RTF_LLINFO};
    size_t len;
    sysctl(mib, 6, NULL, &len, NULL, 0);
    char *buf = malloc(len);
    if (buf == NULL) {
        return @[];
    }
    sysctl(mib, 6, buf, &len, NULL, 0);

    char *next = buf;
    char *max  = buf + len;
    
    NSMutableArray *clients = [NSMutableArray array];

    while (next < max) {
        struct rt_msghdr *rtm = (struct rt_msghdr *)next;
        struct sockaddr_inarp *sin = (struct sockaddr_inarp *)(rtm + 1);
        struct sockaddr_dl *sdl = (struct sockaddr_dl *)(sin + 1);
        
        if (sdl->sdl_alen) {
            
            // MAC
            // unsigned char *lladdr = (unsigned char *)LLADDR(sdl);
            // NSString *MAC = [NSString stringWithFormat:@"%x:%x:%x:%x:%x:%x",inet_ntoa(sin->sin_addr),lladdr[0], lladdr[1], lladdr[2], lladdr[3], lladdr[4], lladdr[5]];
            
            // IPv4(在没有热点连接时，会读取局域网地址192.168.*.*, 热点则是172.20.10.*)
            NSString *addr = [NSString stringWithFormat:@"%s",inet_ntoa(sin->sin_addr)];
            if ([addr containsString:@"."] && [addr hasPrefix:prefix]) {
                [clients addObject:addr];
            }
        }
        next += rtm->rtm_msglen;
    }
    free(buf);
    
    return [clients copy];
}

+ (NSString *)stringValue:(NSString *)localIPAddress {
    return localIPAddress ? localIPAddress : @"0.0.0.0";
}

#pragma mark -

- (NSString *)localIPV4Address {
    NSArray<NSString *> *regex = @[
        IOS_WIFI @"/" IP_ADDR_IPv4,
        IOS_WIFI @"/" IP_ADDR_IPv6,
        IOS_CELLULAR @"/" IP_ADDR_IPv4,
        IOS_CELLULAR @"/" IP_ADDR_IPv6
    ];
    return [self searchIPAddress:regex];
}

- (NSString *)localIPV6Address {
    NSArray<NSString *> *regex = @[
        IOS_WIFI @"/" IP_ADDR_IPv6,
        IOS_WIFI @"/" IP_ADDR_IPv4,
        IOS_CELLULAR @"/" IP_ADDR_IPv6,
        IOS_CELLULAR @"/" IP_ADDR_IPv4
    ];
    return [self searchIPAddress:regex];
}

#pragma mark - WIFI

- (BOOL)WIFI_gatewayManual {
    NSString *WIFI_gateway = self.WIFI_gateway;

    // 处于飞行模式时为空
    if (WIFI_gateway == nil) {
        return NO;
    }

//    NSString *CELLULAR_address = self.CELLULAR_address;
//    // 未打开蜂窝网络时等于已设置
//    if (CELLULAR_address == nil) {
//        return YES;
//    }
//
//    // 当网关地址不等于蜂窝移动网络地址时，判断为手动设置过网关地址
//    if (![WIFI_gateway isEqualToString:CELLULAR_address]) {
//        return YES;
//    }
//
//    return NO;
    
    // 判断 getgateway 与 getdefaultgateway 获取的网关地址是否一样
    NSString *WIFI_defaultgateway = self.WIFI_defaultgateway;
    if (WIFI_defaultgateway && [WIFI_gateway isEqualToString:WIFI_defaultgateway]) {
        return YES;
    }
    return NO;
}

#pragma mark - HOTSPOT

- (BOOL)HOTSPOT_isEnabled {
    return self.HOTSPOT_address != nil && self.HOTSPOT_clients.count > 0;
}

- (NSString *)HOTSPOT_address {
    NSString *regex = IOS_HOTSPOT @"/" IP_ADDR_IPv4;
    return [self queryIPAddress:regex];
}

#pragma mark - CELLULAR

- (NSString *)CELLULAR_address {
    NSString *regex = IOS_CELLULAR @"/" IP_ADDR_IPv4;
    return [self queryIPAddress:regex];
}

@end
