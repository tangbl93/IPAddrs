/* $Id: getgateway.c,v 1.24 2014/03/31 12:41:35 nanard Exp $ */
/* libnatpmp

Copyright (c) 2007-2014, Thomas BERNARD
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice,
      this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright notice,
      this list of conditions and the following disclaimer in the documentation
      and/or other materials provided with the distribution.
    * The name of the author may not be used to endorse or promote products
	  derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.
*/
#ifdef __APPLE__
#include <stdio.h>
#include <netinet/in.h>
#include <stdlib.h>
#include <sys/sysctl.h>
#include <net/if.h>
#include <string.h>
#include <arpa/inet.h>
#include <TargetConditionals.h>

#include "route.h"
#include "getgateway.h"

#define SUCCESS (0)
#define FAILED  (-1)

#define ROUNDUP(a) \
	((a) > 0 ? (1 + (((a) - 1) | (sizeof(long) - 1))) : sizeof(long))

int getgateway(in_addr_t * addr) {
    int mib[] = {CTL_NET, PF_ROUTE, 0, AF_INET,
        NET_RT_FLAGS, RTF_GATEWAY};
    size_t l;
    char * buf, * p;
    struct rt_msghdr * rt;
    struct sockaddr * sa;
    struct sockaddr * sa_tab[RTAX_MAX];
    int i;
    int r = -1;
    if(sysctl(mib, sizeof(mib)/sizeof(int), 0, &l, 0, 0) < 0) {
        return -1;
    }
    if(l>0) {
        buf = malloc(l);
        if(sysctl(mib, sizeof(mib)/sizeof(int), buf, &l, 0, 0) < 0) {
            return -1;
        }
        for(p=buf; p<buf+l; p+=rt->rtm_msglen) {
            rt = (struct rt_msghdr *)p;
            sa = (struct sockaddr *)(rt + 1);
            for(i=0; i<RTAX_MAX; i++) {
                if(rt->rtm_addrs & (1 << i)) {
                    sa_tab[i] = sa;
                    sa = (struct sockaddr *)((char *)sa + ROUNDUP(sa->sa_len));
                } else {
                    sa_tab[i] = NULL;
                }
            }
            
            if( ((rt->rtm_addrs & (RTA_DST|RTA_GATEWAY)) == (RTA_DST|RTA_GATEWAY))
               && sa_tab[RTAX_DST]->sa_family == AF_INET
               && sa_tab[RTAX_GATEWAY]->sa_family == AF_INET) {
                
                if(((struct sockaddr_in *)sa_tab[RTAX_DST])->sin_addr.s_addr == 0) {
                    char ifname[128];
                    if_indextoname(rt->rtm_index,ifname);
                    if (strcmp("en0", ifname) == 0) {
                        *addr = ((struct sockaddr_in *)(sa_tab[RTAX_GATEWAY]))->sin_addr.s_addr;
                        r = 0;
                    }
                }
            }
        }
        free(buf);
    }
    return r;
}

int getdefaultgateway(in_addr_t * addr) {
#if 0
	/* net.route.0.inet.dump.0.0 ? */
	int mib[] = {CTL_NET, PF_ROUTE, 0, AF_INET,
	             NET_RT_DUMP, 0, 0/*tableid*/};
#endif
	/* net.route.0.inet.flags.gateway */
	int mib[] = {CTL_NET, PF_ROUTE, 0, AF_INET,
	             NET_RT_FLAGS, RTF_GATEWAY};
	size_t l;
	char * buf, * p;
	struct rt_msghdr * rt;
	struct sockaddr * sa;
	struct sockaddr * sa_tab[RTAX_MAX];
	int i;
	int r = FAILED;
	if(sysctl(mib, sizeof(mib)/sizeof(int), 0, &l, 0, 0) < 0) {
		return FAILED;
	}
	if(l>0) {
		buf = malloc(l);
		if(sysctl(mib, sizeof(mib)/sizeof(int), buf, &l, 0, 0) < 0) {
			free(buf);
			return FAILED;
		}
		for(p=buf; p<buf+l; p+=rt->rtm_msglen) {
			rt = (struct rt_msghdr *)p;
			sa = (struct sockaddr *)(rt + 1);
			for(i=0; i<RTAX_MAX; i++) {
				if(rt->rtm_addrs & (1 << i)) {
					sa_tab[i] = sa;
					sa = (struct sockaddr *)((char *)sa + ROUNDUP(sa->sa_len));
				} else {
					sa_tab[i] = NULL;
				}
			}
			if( ((rt->rtm_addrs & (RTA_DST|RTA_GATEWAY)) == (RTA_DST|RTA_GATEWAY))
              && sa_tab[RTAX_DST]->sa_family == AF_INET
              && sa_tab[RTAX_GATEWAY]->sa_family == AF_INET) {
				if(((struct sockaddr_in *)sa_tab[RTAX_DST])->sin_addr.s_addr == 0) {
					*addr = ((struct sockaddr_in *)(sa_tab[RTAX_GATEWAY]))->sin_addr.s_addr;
					r = SUCCESS;
				}
			}
		}
		free(buf);
	}
	return r;
}

#else /* fallback */

int getgateway(in_addr_t * addr) {
    (void)addr;
    return -1;
}

int getdefaultgateway(in_addr_t * addr) {
    (void)addr;
    return -1;
}

#endif
