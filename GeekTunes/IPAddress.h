/*
 *  IPAddress.h
 *  ModBox
 *
 *  Created by Rainer Sinsch on 14.12.09.
 *  Copyright 2009 __MyCompanyName__. All rights reserved.
 *
 */

#define MAXADDRS	32

extern char *if_names[MAXADDRS];
extern char *ip_names[MAXADDRS];
extern char *hw_addrs[MAXADDRS];
extern unsigned long ip_addrs[MAXADDRS];
extern int   g_IPAddresses;

// Function prototypes

void InitAddresses();
void FreeAddresses();
void GetIPAddresses();
char *GetIPAddress( void ); 
/*void GetHWAddresses();*/