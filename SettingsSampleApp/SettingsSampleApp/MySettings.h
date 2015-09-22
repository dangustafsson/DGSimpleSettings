//
//  MySettings.h
//  SettingsSampleApp
//
//  Created by Dan Gustafsson on 22/09/2015.
//  Copyright © 2015 Curious Alpaca. All rights reserved.
//

#import "DGSimpleSettings.h"

#define _Settings		[MySettings sharedInstance]

@interface MySettings : DGSimpleSettings

// Just add your properties to the header file and start using them!

@property (nonatomic, strong) NSString *string;
@property (nonatomic, strong) NSDate *date;
@property (nonatomic, strong) NSDictionary *dict;
@property (nonatomic) NSInteger count;

@end
