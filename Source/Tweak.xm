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
    return NSClassFromString(@"_UIStatusBarVisualProvider_Split58");
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

// Disable Gestures (SpringBoard applicationDidFinishLaunching also used in Screenshot Remap!)
int applicationDidFinishLaunching;

%hook SpringBoard
-(void)applicationDidFinishLaunching:(id)application {
    applicationDidFinishLaunching = 2;
    %orig;
}
%end

// Screenshot Remap
%hook SBPressGestureRecognizer
- (void)setAllowedPressTypes:(NSArray *)arg1 {
    NSArray * lockHome = @[@104, @101];
    NSArray * lockVol = @[@104, @102, @103];
    if ([arg1 isEqual:lockVol] && applicationDidFinishLaunching == 2) {
        %orig(lockHome);
        applicationDidFinishLaunching--;
        return;
    }
    %orig;
}
%end
%hook SBClickGestureRecognizer
- (void)addShortcutWithPressTypes:(id)arg1 {
    if (applicationDidFinishLaunching == 1) {
        applicationDidFinishLaunching--;
        return;
    }
    %orig;
}
%end
%hook SBHomeHardwareButton
- (id)initWithScreenshotGestureRecognizer:(id)arg1 homeButtonType:(long long)arg2 buttonActions:(id)arg3 gestureRecognizerConfiguration:(id)arg4 {
    return %orig(arg1, _homeButtonType, arg3, arg4);
}
- (id)initWithScreenshotGestureRecognizer:(id)arg1 homeButtonType:(long long)arg2 {
    return %orig(arg1, _homeButtonType);
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

@interface SBAppSwitcherPageView : UIView
@property(nonatomic, assign) double cornerRadius;
@property(nonatomic) _Bool blocksTouches;
@property(nonatomic) double shadowAlpha;
- (void)_updateCornerRadius;
@end

// Round Screenshot Preview
%hook UITraitCollection
+ (id)traitCollectionWithDisplayCornerRadius:(CGFloat)arg1 {
    return %orig(22);
}

// Round Dock, Switcher Transition View, and Reachability
- (CGFloat)displayCornerRadius {
    return 5;
}
%end

%hook SBAppSwitcherPageView
- (void)_updateCornerRadius {
    self.cornerRadius = 5;
    [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        %orig;
    } completion:NULL];
    return;
}

- (void)viewDismissing:(id)arg1 forTransitionRequest:(id)arg2 {
    %orig;
    //self.cornerRadius = 0;
    [self _updateCornerRadius];
    return;
}
- (void)viewPresenting:(id)arg1 forTransitionRequest:(id)arg2 {
    %orig;
    //self.cornerRadius = 22;
    [self _updateCornerRadius];
    return;
}

- (void)_updateShadow {
    %orig;
    [self _updateCornerRadius];
    return;
}
- (void)setActive:(_Bool)arg1 {
    %orig;
    [self _updateCornerRadius];
    return;
}
- (void)layoutSubviews {
    %orig;
    [self _updateCornerRadius];
    return;
}
- (void)setVisible:(_Bool)arg1 {
    %orig;
    [self _updateCornerRadius];
    return;
}
%end

// Hide HomeBar
@interface MTLumaDodgePillView : UIView
@end

%hook MTLumaDodgePillView
- (id)initWithFrame:(struct CGRect)arg1 {
	return NULL;
}
%end
