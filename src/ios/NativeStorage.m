#import "NativeStorage.h"
#import <Cordova/CDVPlugin.h>
#import "Vault12-Swift.h"

@interface NativeStorage()
@property NSUserDefaults *appGroupUserDefaults;
@property NSString* suiteName;
@end

@implementation NativeStorage

- (void) initWithSuiteName: (CDVInvokedUrlCommand*) command
{
    [self.commandDelegate runInBackground:^{
        CDVPluginResult* pluginResult = nil;
        NSString* aSuiteName = [command.arguments objectAtIndex:0];
        
        if(aSuiteName!=nil)
        {
            _suiteName = aSuiteName;
            _appGroupUserDefaults = [[NSUserDefaults alloc] initWithSuiteName:_suiteName];
	    pluginResult = [CDVPluginResult resultWithStatus: CDVCommandStatus_OK];
        }
        else
        {
            pluginResult = [CDVPluginResult resultWithStatus: CDVCommandStatus_ERROR messageAsString:@"Reference or SuiteName was null"];
        }
        [self.commandDelegate sendPluginResult:pluginResult callbackId: command.callbackId];
    }];
}

- (NSUserDefaults*) getUserDefault {
	if (_suiteName != nil)
	{
        return _appGroupUserDefaults;
	}
	return [NSUserDefaults standardUserDefaults];
}

- (void) remove: (CDVInvokedUrlCommand*) command
{
	[self.commandDelegate runInBackground:^{
		CDVPluginResult* pluginResult = nil;
		NSString* reference = [command.arguments objectAtIndex:0];

		if(reference!=nil)
		{
			NSUserDefaults *defaults = [self getUserDefault];
			[defaults removeObjectForKey: reference];
			BOOL success = [defaults synchronize];
			if(success) pluginResult = [CDVPluginResult resultWithStatus: CDVCommandStatus_OK];
			else pluginResult = [CDVPluginResult resultWithStatus: CDVCommandStatus_ERROR messageAsString:@"Remove has failed"];
		}
		else
		{
			pluginResult = [CDVPluginResult resultWithStatus: CDVCommandStatus_ERROR messageAsString:@"Reference was null"];
		}
		[self.commandDelegate sendPluginResult:pluginResult callbackId: command.callbackId];
	}];
}

- (void) clear: (CDVInvokedUrlCommand*) command
{
	[self.commandDelegate runInBackground:^{
		CDVPluginResult* pluginResult = nil;
		[[self getUserDefault] removePersistentDomainForName:[[NSBundle mainBundle] bundleIdentifier]];
		BOOL success = [[self getUserDefault] synchronize];
		if(success) pluginResult = [CDVPluginResult resultWithStatus: CDVCommandStatus_OK];
		else pluginResult = [CDVPluginResult resultWithStatus: CDVCommandStatus_ERROR messageAsString:@"Clear has failed"];
		[self.commandDelegate sendPluginResult:pluginResult callbackId: command.callbackId];
	}];
}

- (void) putBoolean: (CDVInvokedUrlCommand*) command
{
	[self.commandDelegate runInBackground:^{
		CDVPluginResult* pluginResult = nil;
		NSString* reference = [command.arguments objectAtIndex:0];
		BOOL aBoolean = [command.arguments objectAtIndex:1];

		if(reference!=nil)
		{
			NSUserDefaults *defaults = [self getUserDefault];
            NSData *encryptedData = [CryptoUtils encryptWithClearText:[@(aBoolean) stringValue]];
            [defaults setObject:encryptedData forKey:reference];
			BOOL success = [defaults synchronize];
			if(success) pluginResult = [CDVPluginResult resultWithStatus: CDVCommandStatus_OK messageAsBool:aBoolean];
			else pluginResult = [CDVPluginResult resultWithStatus: CDVCommandStatus_ERROR messageAsString:@"Write has failed"];
		}
		else
		{
			pluginResult = [CDVPluginResult resultWithStatus: CDVCommandStatus_ERROR messageAsString:@"Reference was null"];
		}
		[self.commandDelegate sendPluginResult:pluginResult callbackId: command.callbackId];
	}];
}
- (void) getBoolean: (CDVInvokedUrlCommand*) command
{
	[self.commandDelegate runInBackground:^{
		NSString* reference = [command.arguments objectAtIndex:0];

		if(reference!=nil)
		{
			NSData *encryptedData = [[self getUserDefault] dataForKey:reference];
            if (encryptedData == nil) {
                CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus: CDVCommandStatus_ERROR messageAsInt:2]; //Ref not found
                [self.commandDelegate sendPluginResult:pluginResult callbackId: command.callbackId];
            } else {
                [CryptoUtils decryptWithCipherTextData:encryptedData completion:^(NSString * _Nullable decryptedString) {
                    BOOL aBoolean = [decryptedString boolValue];
                    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus: CDVCommandStatus_OK messageAsBool:aBoolean];
                    [self.commandDelegate sendPluginResult:pluginResult callbackId: command.callbackId];
                }];
            }
		}
		else
		{
            CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus: CDVCommandStatus_ERROR messageAsString:@"Reference was null"];
            [self.commandDelegate sendPluginResult:pluginResult callbackId: command.callbackId];

		}
	}];
}

- (void) putInt: (CDVInvokedUrlCommand*) command
{
	[self.commandDelegate runInBackground:^{
		CDVPluginResult* pluginResult = nil;
		NSString* reference = [command.arguments objectAtIndex:0];
		NSInteger anInt = [[command.arguments objectAtIndex:1] integerValue];

		if(reference!=nil)
		{
			NSUserDefaults *defaults = [self getUserDefault];
            NSData *encryptedData = [CryptoUtils encryptWithClearText:[@(anInt) stringValue]];
            [defaults setObject:encryptedData forKey:reference];
			BOOL success = [defaults synchronize];
			if(success) pluginResult = [CDVPluginResult resultWithStatus: CDVCommandStatus_OK messageAsNSInteger:anInt];
			else pluginResult = [CDVPluginResult resultWithStatus: CDVCommandStatus_ERROR messageAsString:@"Write has failed"];
		}
		else
		{
			pluginResult = [CDVPluginResult resultWithStatus: CDVCommandStatus_ERROR messageAsString:@"Reference was null"];
		}
		[self.commandDelegate sendPluginResult:pluginResult callbackId: command.callbackId];
	}];
}
- (void) getInt: (CDVInvokedUrlCommand*) command
{
	[self.commandDelegate runInBackground:^{
		NSString* reference = [command.arguments objectAtIndex:0];
		if(reference!=nil)
		{
            NSData *encryptedData = [[self getUserDefault] dataForKey:reference];
            if (encryptedData == nil) {
                CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus: CDVCommandStatus_ERROR messageAsInt:2]; //Ref not found
                [self.commandDelegate sendPluginResult:pluginResult callbackId: command.callbackId];
            } else {
                [CryptoUtils decryptWithCipherTextData:encryptedData completion:^(NSString * _Nullable decryptedString) {
                    NSInteger anInt = [decryptedString integerValue];
                    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus: CDVCommandStatus_OK messageAsNSInteger:anInt];
                    [self.commandDelegate sendPluginResult:pluginResult callbackId: command.callbackId];
                }];
            }
		}
		else
		{
            CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus: CDVCommandStatus_ERROR messageAsString:@"Reference was null"];
            [self.commandDelegate sendPluginResult:pluginResult callbackId: command.callbackId];
		}
	}];
}


- (void) putDouble: (CDVInvokedUrlCommand*) command
{
	[self.commandDelegate runInBackground:^{
		CDVPluginResult* pluginResult = nil;
		NSString* reference = [command.arguments objectAtIndex:0];
		double aDouble = [[command.arguments objectAtIndex:1] doubleValue];

		if(reference!=nil)
		{
			NSUserDefaults *defaults = [self getUserDefault];
            NSData *encryptedData = [CryptoUtils encryptWithClearText:[@(aDouble) stringValue]];
            [defaults setObject:encryptedData forKey:reference];
			BOOL success = [defaults synchronize];
			if(success) pluginResult = [CDVPluginResult resultWithStatus: CDVCommandStatus_OK messageAsDouble:aDouble];
			else pluginResult = [CDVPluginResult resultWithStatus: CDVCommandStatus_ERROR messageAsString:@"Write has failed"];
		}
		else
		{
			pluginResult = [CDVPluginResult resultWithStatus: CDVCommandStatus_ERROR messageAsString:@"Reference was null"];
		}
		[self.commandDelegate sendPluginResult:pluginResult callbackId: command.callbackId];
	}];
}
- (void) getDouble: (CDVInvokedUrlCommand*) command
{
	[self.commandDelegate runInBackground:^{
		NSString* reference = [command.arguments objectAtIndex:0];

		if(reference!=nil)
		{
            NSData *encryptedData = [[self getUserDefault] dataForKey:reference];
            if (encryptedData == nil) {
                CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus: CDVCommandStatus_ERROR messageAsInt:2]; //Ref not found
                [self.commandDelegate sendPluginResult:pluginResult callbackId: command.callbackId];
            } else {
                [CryptoUtils decryptWithCipherTextData:encryptedData completion:^(NSString * _Nullable decryptedString) {
                    double aDouble = [decryptedString doubleValue];
                    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus: CDVCommandStatus_OK messageAsDouble:aDouble];
                    [self.commandDelegate sendPluginResult:pluginResult callbackId: command.callbackId];
                }];
            }
		}
		else
		{
            CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus: CDVCommandStatus_ERROR messageAsString:@"Reference was null"];
            [self.commandDelegate sendPluginResult:pluginResult callbackId: command.callbackId];
		}
	}];
}

- (void) putString: (CDVInvokedUrlCommand*) command
{
	[self.commandDelegate runInBackground:^{
		CDVPluginResult* pluginResult = nil;
		NSString* reference = [command.arguments objectAtIndex:0];
		NSString* aString = [command.arguments objectAtIndex:1];

		if(reference!=nil)
		{
			NSUserDefaults *defaults = [self getUserDefault];
            NSData *encryptedData = [CryptoUtils encryptWithClearText:aString];
			[defaults setObject: encryptedData forKey:reference];
			BOOL success = [defaults synchronize];
			if(success) pluginResult = [CDVPluginResult resultWithStatus: CDVCommandStatus_OK messageAsString:aString];
			else pluginResult = [CDVPluginResult resultWithStatus: CDVCommandStatus_ERROR messageAsString:@"Write has failed"];

		}
		else
		{
			pluginResult = [CDVPluginResult resultWithStatus: CDVCommandStatus_ERROR messageAsString:@"Reference was null"];
		}
		[self.commandDelegate sendPluginResult:pluginResult callbackId: command.callbackId];
	}];
}
- (void) getString: (CDVInvokedUrlCommand*) command
{
	[self.commandDelegate runInBackground:^{
		NSString* reference = [command.arguments objectAtIndex:0];

		if(reference!=nil)
		{
            NSData *encryptedData = [[self getUserDefault] dataForKey:reference];
            if (encryptedData == nil) {
                CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus: CDVCommandStatus_ERROR messageAsInt:2]; //Ref not found
                [self.commandDelegate sendPluginResult:pluginResult callbackId: command.callbackId];
            } else {
                [CryptoUtils decryptWithCipherTextData:encryptedData completion:^(NSString * _Nullable aString) {
                    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus: CDVCommandStatus_OK messageAsString:aString];
                    [self.commandDelegate sendPluginResult:pluginResult callbackId: command.callbackId];
                }];
            }
		}
		else
		{
            CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus: CDVCommandStatus_ERROR messageAsString:@"Reference was null"];
            [self.commandDelegate sendPluginResult:pluginResult callbackId: command.callbackId];

		}
	}];
}


- (void) setItem: (CDVInvokedUrlCommand*) command
{
	[self.commandDelegate runInBackground:^{
		CDVPluginResult* pluginResult = nil;
		NSString* reference = [command.arguments objectAtIndex:0];
		NSString* aString = [command.arguments objectAtIndex:1];

		if(reference==nil || [aString class] == [NSNull class])
		{
			pluginResult = [CDVPluginResult resultWithStatus: CDVCommandStatus_ERROR messageAsInt:3];
		}
		else
		{
			NSUserDefaults *defaults = [self getUserDefault];
            NSData *encryptedData = [CryptoUtils encryptWithClearText:aString];
			[defaults setObject: encryptedData forKey:reference];
			BOOL success = [defaults synchronize];
			if(success) pluginResult = [CDVPluginResult resultWithStatus: CDVCommandStatus_OK messageAsString:aString];
			else pluginResult = [CDVPluginResult resultWithStatus: CDVCommandStatus_ERROR messageAsInt:1]; //Write has failed
		}

		[self.commandDelegate sendPluginResult:pluginResult callbackId: command.callbackId];
	}];
}

- (void) getItem: (CDVInvokedUrlCommand*) command
{
	[self.commandDelegate runInBackground:^{
		NSString* reference = [command.arguments objectAtIndex:0];

		if(reference!=nil)
		{
            NSData *encryptedData = [[self getUserDefault] dataForKey:reference];
            if (encryptedData == nil) {
                CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus: CDVCommandStatus_ERROR messageAsInt:2]; //Ref not found
                [self.commandDelegate sendPluginResult:pluginResult callbackId: command.callbackId];
            } else {
                [CryptoUtils decryptWithCipherTextData:encryptedData completion:^(NSString * _Nullable decryptedString) {
                    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus: CDVCommandStatus_OK messageAsString:decryptedString];
                    [self.commandDelegate sendPluginResult:pluginResult callbackId: command.callbackId];
                }];
            }
		}
		else
		{
            CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus: CDVCommandStatus_ERROR messageAsInt:3]; //Reference was null
            [self.commandDelegate sendPluginResult:pluginResult callbackId: command.callbackId];
		}
	}];
}

- (void) keys: (CDVInvokedUrlCommand*) command
{
	[self.commandDelegate runInBackground:^{
		CDVPluginResult* pluginResult = nil;
		NSArray *keys = [[[self getUserDefault] dictionaryRepresentation] allKeys];
		pluginResult = [CDVPluginResult resultWithStatus: CDVCommandStatus_OK messageAsArray:keys];

		[self.commandDelegate sendPluginResult:pluginResult callbackId: command.callbackId];
	}];
}


@end
