#import <UIKit/UIKit.h>
#import <objc/runtime.h>

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
- (id)initWithHomeButtonType:(long long)arg1 {
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

 %hook MediaControlsRoutingButtonPackageView
 - (id)init {
 return NULL;
 }
 %end

%hook SBDeckSwitcherPersonality
- (CGFloat)_cardCornerRadiusInAppSwitcher {
    CGFloat orig = 10;
    return orig;
}
%end

@interface SBAppSwitcherPageView : UIView
@property(nonatomic, assign) double cornerRadius;
@property(nonatomic) _Bool blocksTouches;
@property(nonatomic) double shadowAlpha;
- (void)_updateCornerRadius;
@end

@interface _UIRootWindow : UIView
@property (setter=_setContinuousCornerRadius:, nonatomic) double _continuousCornerRadius;
- (double)_continuousCornerRadius;
- (void)_setContinuousCornerRadius:(double)arg1;
@end

%hook _UIRootWindow
- (void)layoutSubviews {
    %orig;
    self._continuousCornerRadius = 5;
    self.clipsToBounds = YES;
    return;
}
%end

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

@interface UIView (SpringBoardAdditions)
- (void)sb_removeAllSubviews;
@end

@interface SBDashBoardQuickActionsView : UIView
@end

%hook SBDashBoardQuickActionsView
- (void)_layoutQuickActionButtons {
    %orig;
    for (UIView *subview in self.subviews) {
        if (subview.frame.size.width < 50) {
            if (subview.frame.origin.x < 50) {
                CGRect _frame = subview.frame;
                _frame = CGRectMake(46, _frame.origin.y - 100, 50, 50);
                subview.frame = _frame;
                [subview sb_removeAllSubviews];
                [subview init];
            }
            if (subview.frame.origin.x > 100) {
                CGFloat _screenWidth = subview.frame.origin.x + subview.frame.size.width / 2;
                CGRect _frame = subview.frame;
                _frame = CGRectMake(_screenWidth - 96, _frame.origin.y - 100, 50, 50);
                subview.frame = _frame;
                [subview sb_removeAllSubviews];
                [subview init];
            }
        }
    }
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
