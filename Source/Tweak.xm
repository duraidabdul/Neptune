long _homeButtonType = 1;

// Enable Fluid App Switcher.
%hook BSPlatform
- (NSInteger)homeButtonType {
    return 2;
}
%end

// Restore button to invoke Siri.
%hook SBLockHardwareButtonActions
- (id)initWithHomeButtonType:(long long)arg1 proximitySensorManager:(id)arg2 {
    return %orig(_homeButtonType, arg2);
}
%end

%hook SBHomeHardwareButtonActions
- (id)initWitHomeButtonType:(long long)arg1 {
    return %orig(_homeButtonType);
}
%end

%hook _UIStatusBarVisualProvider_iOS
+ (Class)class {
    return NSClassFromString(@"_UIStatusBarVisualProvider_Split61");
}
%end

@interface _UIStatusBar
+ (void)setVisualProviderClass:(Class)classOb;
@end

%hook UIStatusBarWindow
+ (void)setStatusBar:(Class)arg1 {
    %orig(NSClassFromString(@"UIStatusBar_Modern"));
}
%end

%hook UIStatusBar_Base
+ (Class)_implementationClass {
    return NSClassFromString(@"UIStatusBar_Modern");
}
+ (void)_setImplementationClass:(Class)arg1 {
    %orig(NSClassFromString(@"UIStatusBar_Modern"));
}
%end

@interface SBDashBoardQuickActionsButton : UIView
@end

%hook SBDashBoardQuickActionsButton
- (id)init {
    return NULL;
}
- (id)initWithType:(long long)arg1 {
    return NULL;
}
- (id)_imageWithName:(id)arg1 {
    return NULL;
}
%end