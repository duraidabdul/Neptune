#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#define kSettingsPath [NSHomeDirectory() stringByAppendingPathComponent:@"/Library/Preferences/com.duraidabdul.neptune.plist"]

long _homeButtonType = 1;


// MARK: - Button remap

%group ButtonRemap

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

%end

// MARK: - Group: Springboard modifications
%group SpringBoardModifications

@interface CCUIHeaderPocketView : UIView
@end

%hook CCUIHeaderPocketView
- (void)layoutSubviews {
    %orig;

    CGRect _frame = self.frame;
    _frame.origin.y = -9;
    self.frame = _frame;
}
%end

// MARK: Enable fluid switcher
%hook BSPlatform
- (NSInteger)homeButtonType {
    return 2;
}
%end

// MARK: Control Center media controls transition (from iOS 12.2 beta)

@interface MediaControlsRoutingButtonView : UIView
- (long long)currentMode;
@end

long currentCachedMode = 99;

static CALayer* playbackIcon;
static CALayer* AirPlayIcon;

%hook MediaControlsRoutingButtonView
- (void)_updateGlyph {

    if (self.currentMode == currentCachedMode) { return; }

    currentCachedMode = self.currentMode;


    if (self.layer.sublayers.count >= 1) {
        if (self.layer.sublayers[0].sublayers.count >= 1) {
            if (self.layer.sublayers[0].sublayers[0].sublayers.count == 2) {

                playbackIcon = self.layer.sublayers[0].sublayers[0].sublayers[1].sublayers[0];
                AirPlayIcon = self.layer.sublayers[0].sublayers[0].sublayers[1].sublayers[1];

                if (self.currentMode == 2) { // Play/Pause Mode

                    // Play/Pause Icon
                    playbackIcon.speed = 0.5;

                    [UIView animateWithDuration:1
                                          delay:0
                                        options:UIViewAnimationOptionCurveEaseInOut
                                     animations:^{

                                         playbackIcon.transform = CATransform3DMakeScale(-1, -1, 1);
                                         playbackIcon.opacity = 0.75;
                                     }
                                     completion:^(BOOL finished){}];

                    // AirPlay Icon
                    AirPlayIcon.speed = 0.75;

                    [UIView animateWithDuration:1
                                          delay:0
                                        options:UIViewAnimationOptionCurveEaseInOut
                                     animations:^{
                                         AirPlayIcon.transform = CATransform3DMakeScale(0.85, 0.85, 1);
                                         AirPlayIcon.opacity = -0.75;
                                     }
                                     completion:^(BOOL finished){}];

                } else if (self.currentMode == 0 || self.currentMode == 1) { // AirPlay Mode

                    // Play/Pause Icon
                    playbackIcon.speed = 0.75;

                    [UIView animateWithDuration:1
                                          delay:0
                                        options:UIViewAnimationOptionCurveEaseInOut
                                     animations:^{

                                         playbackIcon.transform = CATransform3DMakeScale(-0.85, -0.85, 1);
                                         playbackIcon.opacity = -0.75;
                                     }
                                     completion:^(BOOL finished){}];

                    // AirPlay Icon
                    AirPlayIcon.speed = 0.5;

                    [UIView animateWithDuration:1
                                          delay:0
                                        options:UIViewAnimationOptionCurveEaseInOut
                                     animations:^{
                                         AirPlayIcon.transform = CATransform3DMakeScale(1, 1, 1);
                                         AirPlayIcon.opacity = 0.75;
                                     }
                                     completion:^(BOOL finished){}];
                }
            }
        }
    }
}
%end


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
                #pragma clang diagnostic push
                #pragma clang diagnostic ignored "-Wunused-value"
                [subview init];
                #pragma clang diagnostic pop
            }
            if (subview.frame.origin.x > 100) {
                CGFloat _screenWidth = subview.frame.origin.x + subview.frame.size.width / 2;
                CGRect _frame = subview.frame;
                _frame = CGRectMake(_screenWidth - 96, _frame.origin.y - 90, 50, 50);
                subview.frame = _frame;
                [subview sb_removeAllSubviews];
                #pragma clang diagnostic push
                #pragma clang diagnostic ignored "-Wunused-value"
                [subview init];
                #pragma clang diagnostic pop
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


// Hide HomeBar
@interface MTLumaDodgePillView : UIView
@end

%hook MTLumaDodgePillView
- (id)initWithFrame:(struct CGRect)arg1 {

    NSString *settingsPath = @"/var/mobile/Library/Preferences/com.duraidabdul.neptune.plist";
    NSMutableDictionary *currentSettings = [[NSMutableDictionary alloc] initWithContentsOfFile:settingsPath];
    BOOL isHomeIndicatorEnabled = [[currentSettings objectForKey:@"isHomeIndicatorEnabled"] boolValue];

    if (!isHomeIndicatorEnabled) {
        return NULL;
    } else {
        return %orig;
    }
}
%end

%end






%hook UIRemoteKeyboardWindowHosted
- (UIEdgeInsets)safeAreaInsets {
    UIEdgeInsets orig = %orig;
    orig.bottom = 44;
    return orig;
}
%end

%hook UIKeyboardImpl
+(UIEdgeInsets)deviceSpecificPaddingForInterfaceOrientation:(NSInteger)orientation inputMode:(id)mode {
    UIEdgeInsets orig = %orig;
    orig.bottom = 44;
    return orig;
}

%end

@interface UIKeyboardDockView : UIView
@end

%hook UIKeyboardDockView

- (CGRect)bounds {
    CGRect bounds = %orig;
    bounds.origin.y -=7.5;
    return bounds;
}

%end

%hook UIInputWindowController
- (UIEdgeInsets)_viewSafeAreaInsetsFromScene {
    return UIEdgeInsetsMake(0,0,44,0);
}
%end

// MARK: - Modern status bar implementation

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




%group StatusBar_Split58

// MARK: - Variable modern status bar implementation

%hook _UIStatusBarVisualProvider_iOS
+ (Class)class {
    return NSClassFromString(@"_UIStatusBarVisualProvider_Split58");
}
%end

%hook _UIStatusBar
+ (double)heightForOrientation:(long long)arg1 {
    if (arg1 == 1 || arg1 == 2) {
        return %orig - 9;
    } else {
        return %orig;
    }
}
%end

%end


%group StatusBar_Pad_ForcedCellular

// MARK: - Variable alternate modern status bar implementation

%hook _UIStatusBarVisualProvider_iOS
+ (Class)class {
    return NSClassFromString(@"_UIStatusBarVisualProvider_Pad_ForcedCellular");
}
%end

%end


%group TabBarSizing

// MARK: - Inset behavior modifications

%hook UITabBar

- (void)layoutSubviews {
    %orig;
    CGRect _frame = self.frame;
    if (_frame.size.height == 49) {
        _frame.size.height = 70;
        _frame.origin.y = [[UIScreen mainScreen] bounds].size.height - 70;
    }
    self.frame = _frame;
}

%end

%hook UIApplicationSceneSettings

- (UIEdgeInsets)_inferredLayoutMargins {
    return UIEdgeInsetsMake(32,0,0,0);
}
- (UIEdgeInsets)safeAreaInsetsLandscapeLeft {
    UIEdgeInsets _insets = %orig;
    _insets.bottom = 21;
    return _insets;
}
- (UIEdgeInsets)safeAreaInsetsLandscapeRight {
    UIEdgeInsets _insets = %orig;
    _insets.bottom = 21;
    return _insets;
}
- (UIEdgeInsets)safeAreaInsetsPortrait {
    UIEdgeInsets _insets = %orig;
    _insets.bottom = 21;
    return _insets;
}
- (UIEdgeInsets)safeAreaInsetsPortraitUpsideDown {
    UIEdgeInsets _insets = %orig;
    _insets.bottom = 21;
    return _insets;
}

%end

%end

// MARK: - Toolbar resizing implementation
%group ToolbarSizing
/*
 %hook UIToolbar

 - (void)layoutSubviews {
 %orig;
 CGRect _frame = self.frame;
 if (_frame.size.height == 44) {
 _frame.size.height = 70;
 _frame.origin.y = [[UIScreen mainScreen] bounds].size.height - 70;
 }
 self.frame = _frame;
 }

 %end
 */
%end

// MARK: - Shortcuts
%group Shortcuts

@interface WFFloatingLayer : CALayer
@end

%hook WFFloatingLayer
-(BOOL)continuousCorners {
    return YES;
}
%end

%end

// Override MobileGestalt to always return true for PIP key - Acknowledgements: Andrew Wiik (LittleX)
extern "C" Boolean MGGetBoolAnswer(CFStringRef);
%hookf(Boolean, MGGetBoolAnswer, CFStringRef key) {
#define k(key_) CFEqual(key, CFSTR(key_))
    if (k("nVh/gwNpy7Jv1NOk00CMrw"))
        return YES;
    return %orig;
}

@interface FBSystemService : NSObject
+ (id)sharedInstance;
- (void)exitAndRelaunch:(BOOL)unknown;
@end

static void respring(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    [[%c(FBSystemService) sharedInstance] exitAndRelaunch:YES];
}

%ctor {
    NSString *bundleIdentifier = [NSBundle mainBundle].bundleIdentifier;

    // Gather current preference keys.
    NSString *settingsPath = @"/var/mobile/Library/Preferences/com.duraidabdul.neptune.plist";
    NSMutableDictionary *currentSettings = [[NSMutableDictionary alloc] initWithContentsOfFile:settingsPath];
    BOOL forcedSystemWideStatusBar = [[currentSettings objectForKey:@"forcedSystemWideStatusBar"] boolValue];
    BOOL isHomeIndicatorEnabled = [[currentSettings objectForKey:@"isHomeIndicatorEnabled"] boolValue];
    BOOL isButtonCombinationOverrideDisabled = [[currentSettings objectForKey:@"isButtonCombinationOverrideDisabled"] boolValue];

    if ([bundleIdentifier isEqualToString:@"com.apple.springboard"]) {
        %init(SpringBoardModifications);
    }

    // Inset adjustment initialization
    if ([bundleIdentifier containsString:@"com.apple"]) {

        if (![bundleIdentifier containsString:@"mobilesafari"]) {

            if (isHomeIndicatorEnabled) {
                %init(TabBarSizing);
                %init(ToolbarSizing);
            }
        }

    }

    // Status bar initialization
    if ([bundleIdentifier containsString:@"com.apple"] || forcedSystemWideStatusBar) {
        %init(StatusBar_Split58);
    } else {
        %init(StatusBar_Pad_ForcedCellular);
    }

    // Application specific hooks.
    if ([bundleIdentifier containsString:@"workflow"]) {
        %init(Shortcuts);
    }

    // Button combination override
    if (!isButtonCombinationOverrideDisabled) {
        %init(ButtonRemap)
    }

    %init(_ungrouped);


    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                    NULL,
                                    &respring,
                                    CFSTR("respring"),
                                    NULL, 0);

}
