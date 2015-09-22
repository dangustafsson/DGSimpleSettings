//
//  ViewController.m
//  SettingsSampleApp
//
//  Created by Dan Gustafsson on 22/09/2015.
//  Copyright © 2015 Curious Alpaca. All rights reserved.
//

#import "ViewController.h"
#import "MySettings.h"

@interface ViewController ()
@property (nonatomic, strong) NSArray *countries;
@end

@implementation ViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	[self updateLabels];
}

- (void) updateLabels {
	
	_dateLabel.text = _Settings.date.description;
	_stringLabel.text = _Settings.string;
	_countLabel.text = [NSString stringWithFormat:@"%li", _Settings.count];
	
	NSLog(@"%@", _Settings.dict);
}

- (IBAction)buttonPressed:(id)sender {
	
	_Settings.count++;
	_Settings.string = [self randomCountry];
	_Settings.date = [NSDate date];
	_Settings.dict = @{@"countryOne": [self randomCountry],
					   @"countryTwo": [self randomCountry],
					   @"countryThree": [self randomCountry],
					   @"time": [NSDate date],
					   @"index": @(_Settings.count)};
	
	[self updateLabels];
}

- (NSString *) randomCountry {
	
	if (!_countries) {
		NSArray *countryCodes = [NSLocale ISOCountryCodes];
		NSMutableArray *countryNames = [[NSMutableArray alloc] initWithCapacity:countryCodes.count];
		for (NSString *countryCode in countryCodes) {
			NSString *country = [[NSLocale currentLocale] displayNameForKey:NSLocaleCountryCode value:countryCode];
			[countryNames addObject:country];
		}
		_countries = countryNames;
	}
	
	return _countries[arc4random_uniform((int)_countries.count)];
}

@end
