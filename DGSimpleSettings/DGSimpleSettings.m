//
//  Created by Dan Gustafsson on 20/09/2015.
//  Copyright © 2015 Curious Alpaca. All rights reserved.
//
//	The MIT License (MIT)
//
//	Permission is hereby granted, free of charge, to any person obtaining a copy
//	of this software and associated documentation files (the "Software"), to deal
//	in the Software without restriction, including without limitation the rights
//	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//	copies of the Software, and to permit persons to whom the Software is
//	furnished to do so, subject to the following conditions:
//
//	The above copyright notice and this permission notice shall be included in all
//	copies or substantial portions of the Software.
//
//	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//	SOFTWARE.

#import "DGSimpleSettings.h"
#import <CoreData/CoreData.h>
#import <objc/message.h>
#import <objc/runtime.h>

#define kSettingEntity		@"DGSimpleSetting"

// Core Data helper class
@interface DGSimpleSettingsCoreDataHelper : NSObject
@property (nonatomic, strong, readonly) NSManagedObjectContext *managedObjectContext;
- (void) saveContext;
+ (instancetype) sharedInstance;
@end

// Settings class to manage each setting object
@interface DGSimpleSetting : NSManagedObject
@property (nonatomic, retain) NSString * key;
@property (nonatomic, retain) id value;
- (SEL) setter;
@end


// Settings main implementation
//
@implementation DGSimpleSettings

#pragma mark - Load Settings

- (void) loadSettings {
	
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:kSettingEntity inManagedObjectContext:[DGSimpleSettingsCoreDataHelper sharedInstance].managedObjectContext];
	[fetchRequest setEntity:entity];
	
	NSError *error = nil;
	NSArray *fetchedObjects = [[DGSimpleSettingsCoreDataHelper sharedInstance].managedObjectContext executeFetchRequest:fetchRequest error:&error];
	if (fetchedObjects == nil) {
		abort();
	}
	
	for (DGSimpleSetting *setting in fetchedObjects) {
		if ([self respondsToSelector:setting.setter]) {
			[self setValue:setting.value forKey:setting.key];
		}
	}
}

- (void) registerKVO {
	
	NSArray *properties = [self properties];
	for (NSString *property in properties) {
		
		[self addObserver:self forKeyPath:property options:NSKeyValueObservingOptionNew context:nil];
	}
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {

	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:kSettingEntity inManagedObjectContext:[DGSimpleSettingsCoreDataHelper sharedInstance].managedObjectContext];
	[fetchRequest setEntity:entity];
	
	fetchRequest.predicate = [NSPredicate predicateWithFormat:@"key = %@", keyPath];
	
	NSError *error = nil;
	NSArray *fetchedObjects = [[DGSimpleSettingsCoreDataHelper sharedInstance].managedObjectContext executeFetchRequest:fetchRequest error:&error];
	if (fetchedObjects == nil) {
		abort();
	}
	
	DGSimpleSetting *setting = [fetchedObjects lastObject];
	if (!setting) {
		setting = [NSEntityDescription insertNewObjectForEntityForName:kSettingEntity inManagedObjectContext:[DGSimpleSettingsCoreDataHelper sharedInstance].managedObjectContext];
		setting.key = keyPath;
	}
	setting.value = [self valueForKey:keyPath];
	
	[[DGSimpleSettingsCoreDataHelper sharedInstance] saveContext];
}

- (NSArray *) properties {
	
	NSMutableArray *propertyArray = [[NSMutableArray alloc] init];
	
	unsigned int count;
	objc_property_t *properties = class_copyPropertyList([self class], &count);
	
	for (size_t i = 0; i < count; i++) {
		NSString *property = [NSString stringWithCString:property_getName(properties[i]) encoding:NSUTF8StringEncoding];
		[propertyArray addObject:property];
	}
	
	free(properties);
	
	return propertyArray;
}

#pragma mark - Singleton

+ (instancetype) sharedInstance {
	static DGSimpleSettings *sharedInstance = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedInstance = [[self alloc] init];
	});
	return sharedInstance;
}

- (id)init {
	
	if (self = [super init]) {
		
		[self loadSettings];
		[self registerKVO];
	}
	return self;
}

@end

//	Setting class implementation
//
@implementation DGSimpleSetting

@dynamic key;
@dynamic value;

- (SEL) setter {
	
	NSString *capitalizedKey = [NSString stringWithFormat:@"%@%@",[[self.key substringToIndex:1] uppercaseString], [self.key substringFromIndex:1]];
	NSString *setterString = [NSString stringWithFormat:@"set%@:", capitalizedKey];
	SEL setter = NSSelectorFromString(setterString);
	
	return setter;
}

@end

// Core data implementation helper class
//
@implementation DGSimpleSettingsCoreDataHelper

@synthesize managedObjectContext = _managedObjectContext;

- (void)saveContext {
	
	NSError *error = nil;
	if ([self.managedObjectContext hasChanges] && ![self.managedObjectContext save:&error]) {
		NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
	}
}

- (NSManagedObjectContext *) managedObjectContext {
	
	if (!_managedObjectContext) {
		NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
		if (coordinator) {
			_managedObjectContext = [[NSManagedObjectContext alloc] init];
			[_managedObjectContext setPersistentStoreCoordinator:coordinator];
		}
	}
	
	return _managedObjectContext;
}

- (NSManagedObjectModel *)managedObjectModel {
	
	NSAttributeDescription *keyAttribute = [[NSAttributeDescription alloc] init];
	keyAttribute.name = @"key";
	keyAttribute.attributeType = NSStringAttributeType;
	keyAttribute.optional = YES;
	keyAttribute.indexed = YES;
	
	NSAttributeDescription *valueAttribute = [[NSAttributeDescription alloc] init];
	valueAttribute.name = @"value";
	valueAttribute.attributeType = NSTransformableAttributeType;
	valueAttribute.optional = YES;
	
	NSEntityDescription *entity = [[NSEntityDescription alloc] init];
	entity.name = kSettingEntity;
	entity.managedObjectClassName = kSettingEntity;
	entity.properties = @[keyAttribute, valueAttribute];
	
	NSManagedObjectModel *model = [[NSManagedObjectModel alloc] init];
	model.entities = @[entity];
	
	return model;
}

- (NSPersistentStoreCoordinator *) persistentStoreCoordinator {
	
	NSString *docFolder = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask,YES) firstObject];
	NSString *dataFolder = [docFolder stringByAppendingString:@"./DGSimpleSettings/"];
	if (![[NSFileManager defaultManager] fileExistsAtPath:dataFolder]) {
		NSError *err;
		if (![[NSFileManager defaultManager] createDirectoryAtPath:dataFolder withIntermediateDirectories:YES attributes:nil error:&err]) {
			NSLog(@"Failed to create folder %@ %@", dataFolder, err);
		}
	}

	NSString *dbFile = @"DGSimpleSettingsDB.sqlite";
	NSURL *storeURL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@%@", dataFolder, dbFile]];
	
	NSError *error;
	NSPersistentStoreCoordinator *persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
	if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
												  configuration:nil URL:storeURL
														options:@{NSMigratePersistentStoresAutomaticallyOption:@YES,
																  NSInferMappingModelAutomaticallyOption:@YES} error:&error]) {
		NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
		if ([[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]) {
			if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
														  configuration:nil URL:storeURL
																options:nil error:&error]) {
				
				NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
				abort();
			}
		}
	}
	
	return persistentStoreCoordinator;
}

#pragma mark - Singleton

+ (instancetype) sharedInstance {
	static DGSimpleSettingsCoreDataHelper *sharedInstance = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedInstance = [[self alloc] init];
	});
	return sharedInstance;
}

@end
