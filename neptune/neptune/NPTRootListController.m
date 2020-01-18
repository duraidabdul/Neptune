#include "NPTRootListController.h"
#include <spawn.h>
#import <Preferences/PSSpecifier.h>

@implementation NPTRootListController

- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"Root" target:self] retain];
	}

	return _specifiers;
}

// Version number example: 1A100a
//  1A: Version and subversion number
//  100: Build number
//  a: Build description: a: alpha
//                        b: beta
//                        c: revised beta
//                        d: developer build
- (NSString *)valueForSpecifier:(PSSpecifier *)specifier {
    return @"1.3 beta (1D100b)";
}

-(void)respring {
    pid_t pid;
    int status;
    const char* args[] = {"killall", "-9", "backboardd", NULL};
    posix_spawn(&pid, "/usr/bin/killall", NULL, NULL, (char* const*)args, NULL);
    waitpid(pid, &status, WEXITED);
}

- (void)launchTwitter:(id)arg1 {
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"twitter://"]]) [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"twitter://user?screen_name=duraidabdul"]];
    else [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://twitter.com/duraidabdul"]];
}

-(void)launchGitHub:(id)arg1 {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://github.com/duraidabdul/Neptune"]];
}

-(void)launchPayPal:(id)arg1 {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://paypal.me/duraidabdul"]];
}

- (id)readPreferenceValue:(PSSpecifier*)specifier {
    NSString *path = [NSString stringWithFormat:@"/User/Library/Preferences/%@.plist", specifier.properties[@"defaults"]];
    NSMutableDictionary *settings = [NSMutableDictionary dictionary];
    [settings addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:path]];
    return (settings[specifier.properties[@"key"]]) ?: specifier.properties[@"default"];
}

- (void)setPreferenceValue:(id)value specifier:(PSSpecifier*)specifier {
    NSString *path = [NSString stringWithFormat:@"/User/Library/Preferences/%@.plist", specifier.properties[@"defaults"]];
    NSMutableDictionary *settings = [NSMutableDictionary dictionary];
    [settings addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:path]];
    [settings setObject:value forKey:specifier.properties[@"key"]];
    [settings writeToFile:path atomically:YES];
    CFStringRef notificationName = (CFStringRef)specifier.properties[@"PostNotification"];
    if (notificationName) {
        CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), notificationName, NULL, NULL, YES);
    }
}

@end

@implementation NPTListController
@end
