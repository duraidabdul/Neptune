#import <UIKit/UIKit.h>
#import <objc/runtime.h>

long _homeButtonType = 1;

// MARK: - Enable fluid behavior

// Enable fluid app switcher support.
%hook BSPlatform
- (NSInteger)homeButtonType {
    return 2;
}
%end

// Enable PIP support.
%hook SBPIPController
+ (BOOL)isPictureInPictureSupported {
    return YES;
}
+ (BOOL)isAutoPictureInPictureSupported {
    return YES;
}
%end

// MARK: - Modern status bar implementation

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

// MARK: - Screenshot remap
/*
int applicationDidFinishLaunching;

%hook SpringBoard
-(void)applicationDidFinishLaunching:(id)application {
    applicationDidFinishLaunching = 2;
    %orig;
}
%end

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

// MARK: - Siri remap

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
*/
/* Implement iOS 12.2 media control button animation.
 %hook MediaControlsRoutingButtonPackageView
 - (id)init {
 return NULL;
 }
 %end
 */

// MARK: - Lock screen quick action toggle implementation

// Define custom springboard method to remove all subviews.
@interface UIView (SpringBoardAdditions)
- (void)sb_removeAllSubviews;
@end

@interface SBDashBoardQuickActionsView : UIView
@end

// Reinitialize quick action toggles
%hook SBDashBoardQuickActionsView
- (void)_layoutQuickActionButtons {
    %orig;
    for (UIView *subview in self.subviews) {
        if (subview.frame.size.width < 50) {
            if (subview.frame.origin.x < 50) {
                CGRect _frame = subview.frame;
                _frame = CGRectMake(46, _frame.origin.y - 90, 50, 50);
                subview.frame = _frame;
                [subview sb_removeAllSubviews];
                [subview init];
            }
            if (subview.frame.origin.x > 100) {
                CGFloat _screenWidth = subview.frame.origin.x + subview.frame.size.width / 2;
                CGRect _frame = subview.frame;
                _frame = CGRectMake(_screenWidth - 96, _frame.origin.y - 90, 50, 50);
                subview.frame = _frame;
                [subview sb_removeAllSubviews];
                [subview init];
            }
        }
    }
}
%end

// MARK: - Cover sheet control centre grabber initialization

@interface SBDashBoardTeachableMomentsContainerView : UIView
@property(retain, nonatomic) UIView *controlCenterGrabberView;
@property(retain, nonatomic) UIView *controlCenterGrabberEffectContainerView;
@end

%hook SBDashBoardTeachableMomentsContainerView
- (void)layoutSubviews {
    %orig;

    self.controlCenterGrabberEffectContainerView.frame = CGRectMake(self.frame.size.width - 73,36,46,2.5);
    self.controlCenterGrabberView.frame = CGRectMake(0,0,46,2.5);
}
%end

// MARK: - Corner radius implementation

@interface _UIRootWindow : UIView
@property (setter=_setContinuousCornerRadius:, nonatomic) double _continuousCornerRadius;
- (double)_continuousCornerRadius;
- (void)_setContinuousCornerRadius:(double)arg1;
@end

// Implement system wide continuousCorners.
%hook _UIRootWindow
- (void)layoutSubviews {
    %orig;
    self._continuousCornerRadius = 5;
    self.clipsToBounds = YES;
    return;
}
%end

// Implement corner radius adjustment for when in the app switcher scroll view.
%hook SBDeckSwitcherPersonality
- (CGFloat)_cardCornerRadiusInAppSwitcher {
    CGFloat orig = 10;
    return orig;
}
%end

// Implement round screenshot preview edge insets.
%hook UITraitCollection
+ (id)traitCollectionWithDisplayCornerRadius:(CGFloat)arg1 {
    return %orig(20);
}
%end

@interface SBAppSwitcherPageView : UIView
@property(nonatomic, assign) double cornerRadius;
@end

// Override rendered corner radius in app switcher page, (for anytime the fluid switcher gestures are running).
%hook SBAppSwitcherPageView
- (void)_updateCornerRadius {
    if (self.cornerRadius == 20) {
        self.cornerRadius = 5;
    }
    %orig;
    return;
}
%end

// Override Reachability corner radius.
%hook SBReachabilityBackgroundView
- (double)_displayCornerRadius {
    return 5;
}
%end

// MARK: - App icon selection override

@interface SBIconView : UIView
- (void)setHighlighted:(bool)arg1;
@end

%hook SBIconView
- (void)setHighlighted:(bool)arg1 {

    if (arg1 == YES) {
        [UIView animateWithDuration:0
                              delay:0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{%orig;}
                         completion:^(BOOL finished){ }];
    } else {
        [UIView animateWithDuration:0.15
                              delay:0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{%orig;}
                         completion:^(BOOL finished){ }];
    }
    return;
}
%end
