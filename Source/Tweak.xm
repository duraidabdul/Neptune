#import <UIKit/UIKit.h>
#import <objc/runtime.h>

long _homeButtonType = 1;


@interface CALayer (CornerAddition)
-(bool)continuousCorners;
@property (assign) bool continuousCorners;
-(void)setContinuousCorners:(bool)arg1;
@end



// MARK: - Button remap

%group ButtonRemap

// Press Home Button for Siri
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

%hook SBHomeHardwareButton
- (id)initWithScreenshotGestureRecognizer:(id)arg1 homeButtonType:(long long)arg2 buttonActions:(id)arg3 gestureRecognizerConfiguration:(id)arg4 {
	return %orig(arg1, _homeButtonType, arg3, arg4);
}
- (id)initWithScreenshotGestureRecognizer:(id)arg1 homeButtonType:(long long)arg2 {
  return %orig(arg1, _homeButtonType);
}
%end

%end

// MARK: - Group: Springboard modifications
%group SpringBoardModifications

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
static CALayer* platterLayer;

%hook MediaControlsRoutingButtonView
- (void)_updateGlyph {

    if (self.currentMode == currentCachedMode) { return; }

    currentCachedMode = self.currentMode;


    if (self.layer.sublayers.count >= 1) {
        if (self.layer.sublayers[0].sublayers.count >= 1) {
            if (self.layer.sublayers[0].sublayers[0].sublayers.count == 2) {

                playbackIcon = self.layer.sublayers[0].sublayers[0].sublayers[1].sublayers[0];
                AirPlayIcon = self.layer.sublayers[0].sublayers[0].sublayers[1].sublayers[1];
								platterLayer = self.layer.sublayers[0].sublayers[0].sublayers[1];

                if (self.currentMode == 2) { // Play/Pause Mode

                    // Play/Pause Icon
                    playbackIcon.speed = 0.5;

                    UIViewPropertyAnimator *animator = [[UIViewPropertyAnimator alloc] initWithDuration:1 dampingRatio:1 animations:^{
                        playbackIcon.transform = CATransform3DMakeScale(-1, -1, 1);
                        playbackIcon.opacity = 0.75;
                    }];
                    [animator startAnimation];

                    // AirPlay Icon
                    AirPlayIcon.speed = 0.75;

                    UIViewPropertyAnimator *animator2 = [[UIViewPropertyAnimator alloc] initWithDuration:1 dampingRatio:1 animations:^{
                        AirPlayIcon.transform = CATransform3DMakeScale(0.85, 0.85, 1);
                        AirPlayIcon.opacity = -0.75;
                    }];
                    [animator2 startAnimation];

										platterLayer.backgroundColor = [[UIColor colorWithRed:0 green:0.478 blue:1.0 alpha:0.0] CGColor];

                } else if (self.currentMode == 0 || self.currentMode == 1) { // AirPlay Mode

                    // Play/Pause Icon
                    playbackIcon.speed = 0.75;

                    UIViewPropertyAnimator *animator = [[UIViewPropertyAnimator alloc] initWithDuration:1 dampingRatio:1 animations:^{
                        playbackIcon.transform = CATransform3DMakeScale(-0.85, -0.85, 1);
                        playbackIcon.opacity = -0.75;
                    }];
                    [animator startAnimation];

                    // AirPlay Icon
                    AirPlayIcon.speed = 0.5;

                    UIViewPropertyAnimator *animator2 = [[UIViewPropertyAnimator alloc] initWithDuration:1 dampingRatio:1 animations:^{
                        AirPlayIcon.transform = CATransform3DMakeScale(1, 1, 1);
												if (self.currentMode == 0) {
													AirPlayIcon.opacity = 0.75;
													platterLayer.backgroundColor = [[UIColor colorWithRed:0 green:0.478 blue:1.0 alpha:0.0] CGColor];
												} else if (self.currentMode == 1) {
													AirPlayIcon.opacity = 1;
													platterLayer.backgroundColor = [[UIColor colorWithRed:0 green:0.478 blue:1.0 alpha:1.0] CGColor];
													platterLayer.cornerRadius = 18;
												}
                    }];
                    [animator2 startAnimation];
                }
            }
        }
    }
}
%end


// MARK: Lock screen quick action toggle implementation

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
            } else if (subview.frame.origin.x > 100) {
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

// MARK: Cover sheet control centre grabber initialization

typedef enum {
    Tall=0,
    Regular=1
} NEPStatusBarHeightStyle;

NEPStatusBarHeightStyle _statusBarHeightStyle = Tall;

@interface SBDashBoardTeachableMomentsContainerView : UIView
@property(retain, nonatomic) UIView *controlCenterGrabberView;
@property(retain, nonatomic) UIView *controlCenterGrabberEffectContainerView;
@end

%hook SBDashBoardTeachableMomentsContainerView
- (void)layoutSubviews {
    %orig;

    if (_statusBarHeightStyle == Tall) {
      self.controlCenterGrabberEffectContainerView.frame = CGRectMake(self.frame.size.width - 73,36,46,2.5);
      self.controlCenterGrabberView.frame = CGRectMake(0,0,46,2.5);
    } else if (@available(iOS 12.1, *)) {
			// Rounded status bar visual provider
			self.controlCenterGrabberEffectContainerView.frame = CGRectMake(self.frame.size.width - 85.5,26,60.5,2.5);
	    self.controlCenterGrabberView.frame = CGRectMake(0,0,60.5,2.5);
    } else {
			// Non-rounded status bar visual provider
			self.controlCenterGrabberEffectContainerView.frame = CGRectMake(self.frame.size.width - 75.5,24,60.5,2.5);
      self.controlCenterGrabberView.frame = CGRectMake(0,0,60.5,2.5);
		}
}
%end

// MARK: Corner radius implementation

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
		UIView* _overlayClippingView = MSHookIvar<UIView*>(self, "_overlayClippingView");
		if (!_overlayClippingView.layer.allowsEdgeAntialiasing) {
			_overlayClippingView.layer.allowsEdgeAntialiasing = true;
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

// MARK: App icon selection override

long _iconHighlightInitiationSkipper = 0;

@interface SBIconView : UIView
- (void)setHighlighted:(bool)arg1;
@property(nonatomic, getter=isHighlighted) _Bool highlighted;
@end

%hook SBIconView
- (void)setHighlighted:(bool)arg1 {

    if (_iconHighlightInitiationSkipper) {
      %orig;
      return;
    }

    if (arg1 == YES) {

        if (!self.highlighted) {
          _iconHighlightInitiationSkipper = 1;
          %orig;
          %orig(NO);
          _iconHighlightInitiationSkipper = 0;
        }

        UIViewPropertyAnimator *animator = [[UIViewPropertyAnimator alloc] initWithDuration:0.125 dampingRatio:1 animations:^{
            %orig;
        }];
        [animator startAnimation];
    } else {
        UIViewPropertyAnimator *animator = [[UIViewPropertyAnimator alloc] initWithDuration:0.25 dampingRatio:1 animations:^{
            %orig;
        }];
        [animator startAnimation];
    }
    return;
}
%end


@interface NCToggleControl : UIView
- (void)setHighlighted:(bool)arg1;
@end

%hook NCToggleControl
- (void)setHighlighted:(bool)arg1 {
    if (arg1 == YES) {

        UIViewPropertyAnimator *animator = [[UIViewPropertyAnimator alloc] initWithDuration:0.125 curve:UIViewAnimationCurveEaseOut animations:^{
            %orig;
        }];
        [animator startAnimation];
    } else {
        UIViewPropertyAnimator *animator = [[UIViewPropertyAnimator alloc] initWithDuration:0.5 dampingRatio:1 animations:^{
            %orig;
        }];
        [animator startAnimation];
    }
    return;
}
%end


@interface SBEditingDoneButton : UIView
- (void)setHighlighted:(bool)arg1;
@end

%hook SBEditingDoneButton
-(void)layoutSubviews {
    %orig;

    if (!self.layer.masksToBounds) {
        self.layer.continuousCorners = YES;
        self.layer.masksToBounds = YES;
        self.layer.cornerRadius = 13;
    }

    /*
     CGRect _frame = self.frame;

     if (_frame.origin.y != 16) {
     _frame.origin.y = 16;
     self.frame = _frame;
     }*/
}
- (void)setHighlighted:(bool)arg1 {
    if (arg1 == YES) {

        UIViewPropertyAnimator *animator = [[UIViewPropertyAnimator alloc] initWithDuration:0.1 curve:UIViewAnimationCurveEaseOut animations:^{
            %orig;
        }];
        [animator startAnimation];
    } else {
        UIViewPropertyAnimator *animator = [[UIViewPropertyAnimator alloc] initWithDuration:0.5 dampingRatio:1 animations:^{
            %orig;
        }];
        [animator startAnimation];
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

/*
 @interface SBUIProudLockIconView : UIView
 @end


 @interface SBDashBoardView : UIView {
 UIView *_proudLockContainerView;
 }
 @end

 static SBUIProudLockIconView* proudLockIconView;

 %hook SBDashBoardView
 - (void)layoutSubviews {
 %orig;

 [proudLockIconView initWithFrame:CGRectMake(0, 0, 250, 250)];
 proudLockIconView.frame = CGRectMake(0, 0, 250, 250);
 proudLockIconView.backgroundColor=[UIColor blueColor];
 [self addSubview: proudLockIconView];

 //[[[self subviews] lastObject] addSubview:proudLockIconView];

 }
 %end
 */

/*
 @interface SBFLockScreenDateView : UIView
 @end

 %hook SBFLockScreenDateView
 - (void)layoutSubviews {
 %orig;

 UIView* np_timeLabel = MSHookIvar<UIView*>(self, "_timeLabel");
 CGRect temporaryCGRect = np_timeLabel.frame;
 temporaryCGRect.origin.y = temporaryCGRect.origin.y + 16;
 [np_timeLabel setFrame:temporaryCGRect];

 UIView* np_dateSubtitleView = MSHookIvar<UIView*>(self, "_dateSubtitleView");
 temporaryCGRect = np_dateSubtitleView.frame;
 temporaryCGRect.origin.y = temporaryCGRect.origin.y + 16;
 [np_dateSubtitleView setFrame:temporaryCGRect];

 UIView* np_customSubtitleView = MSHookIvar<UIView*>(self, "_customSubtitleView");
 temporaryCGRect = np_customSubtitleView.frame;
 temporaryCGRect.origin.y = temporaryCGRect.origin.y + 16;
 [np_customSubtitleView setFrame:temporaryCGRect];
 }
 %end

 %hook NCNotificationListCollectionView
 - (void)setFrame:(CGRect)arg1 {

 arg1.origin.y = arg1.origin.y + 16;
 %orig(arg1);
 }

 - (CGRect)frame {
 CGRect temporaryCGRect = %orig;
 temporaryCGRect.origin.y = temporaryCGRect.origin.y + 16;
 return temporaryCGRect;
 }
 %end
 */

@interface SBFolderIconBackgroundView : UIView
@end

%hook SBFolderIconBackgroundView
- (void)layoutSubviews {
    %orig;
    self.layer.continuousCorners = YES;
}
%end
/*
 @interface SBFolderIconImageView : UIView
 @end

 %hook SBFolderIconImageView
 - (void)layoutSubviews {
 if (!self.layer.masksToBounds) {
 self.layer.continuousCorners = YES;
 self.layer.masksToBounds = YES;
 self.layer.cornerRadius = 13.5;
 }
 return %orig;
 }
 %end
 */




// MARK: Widgets screen button highlight
@interface WGShortLookStyleButton : UIView
- (void)setHighlighted:(bool)arg1;
@end

%hook WGShortLookStyleButton
- (void)setHighlighted:(bool)arg1 {
    if (arg1 == YES) {

        UIViewPropertyAnimator *animator = [[UIViewPropertyAnimator alloc] initWithDuration:0.25 dampingRatio:1 animations:^{
            self.alpha = 0.6;
        }];
        [animator startAnimation];
    } else {
        UIViewPropertyAnimator *animator = [[UIViewPropertyAnimator alloc] initWithDuration:0.6 dampingRatio:1 animations:^{
            self.alpha = 1;
        }];
        [animator startAnimation];
    }
    return;
}
%end


// MARK: Reachability settings override
%hook SBReachabilitySettings
- (void)setSystemWideSwipeDownHeight:(double) systemWideSwipeDownHeight {
    return %orig(100);
}
%end


%end




%group KeyboardDock

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
    if (bounds.origin.y == 0) {
        bounds.origin.y -=13;
    }
    return bounds;
}

- (void)layoutSubviews {
    %orig;
}

%end


%hook UIInputWindowController
- (UIEdgeInsets)_viewSafeAreaInsetsFromScene {
    return UIEdgeInsetsMake(0,0,44,0);
}
%end

%end

// MARK: - Modern status bar implementation
%group ModernStatusBarView

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

%hook _UIStatusBarData
- (void)setBackNavigationEntry:(id)arg1 {
	return;
}
%end

%end

int _controlCenterStatusBarInset = -10;

// MARK: - Group: Springboard modifications (Control Center Status Bar inset)
%group ControlCenterModificationsStatusBar

@interface CCUIHeaderPocketView : UIView
@end

%hook CCUIHeaderPocketView
- (void)layoutSubviews {
    %orig;

    CGRect _frame = self.frame;
    _frame.origin.y = _controlCenterStatusBarInset;
    self.frame = _frame;
}
%end

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
        return %orig - 10;
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
    if (@available(iOS 12.1, *)) {
      return NSClassFromString(@"_UIStatusBarVisualProvider_RoundedPad_ForcedCellular");
    }
    return NSClassFromString(@"_UIStatusBarVisualProvider_Pad_ForcedCellular");
}
%end

%end


%group TabBarSizing

// MARK: - Inset behavior modifications

/*
 %hook UIWindow
 - (UIEdgeInsets)safeAreaInsets {
 UIEdgeInsets orig = %orig;
 orig.bottom = 21;
 return orig;
 }
 - (UIEdgeInsets)_inferredLayoutMargins {
 UIEdgeInsets orig = %orig;
 orig.bottom = 21;
 return orig;
 }
 %end
 */

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
 @interface UIToolbar (modification)
 @property (setter=_setBackgroundView:, nonatomic, retain) UIView *_backgroundView;
 @end

 %hook UIToolbar

 - (void)layoutSubviews {
 %orig;
 CGRect _frame = self.frame;
 if (_frame.size.height == 44) {
 _frame.origin.y = [[UIScreen mainScreen] bounds].size.height - 54;
 }
 self.frame = _frame;

 _frame = self._backgroundView.frame;
 _frame.size.height = 54;
 self._backgroundView.frame = _frame;
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

// MARK: - Twitter
%group Twitter

@interface TFNCustomTabBar : UIView
@end

%hook TFNCustomTabBar

- (void)layoutSubviews {
    %orig;
    CGRect _frame = self.frame;
    if (_frame.origin.y != [[UIScreen mainScreen] bounds].size.height - _frame.size.height) {
        _frame.origin.y = _frame.origin.y - 3.5;
    }
    self.frame = _frame;
}

%end

%end

// MARK: - Calendar
%group Calendar

@interface CompactMonthDividedListSwitchButton : UIView
@end

%hook CompactMonthDividedListSwitchButton
- (void)layoutSubviews {
    %orig;

    self.layer.cornerRadius = 3;
    self.layer.continuousCorners = YES;
    self.clipsToBounds = YES;
}
%end;

%end

// MARK: - Picture in Picture
%group PIPOverride

// Override MobileGestalt to always return true for PIP key - Acknowledgements: Andrew Wiik (LittleX)
extern "C" Boolean MGGetBoolAnswer(CFStringRef);
%hookf(Boolean, MGGetBoolAnswer, CFStringRef key) {
#define k(key_) CFEqual(key, CFSTR(key_))
    if (k("nVh/gwNpy7Jv1NOk00CMrw"))
        return YES;
    return %orig;
}

%end

@interface _UITableViewCellSeparatorView : UIView
- (id)_viewControllerForAncestor;
@end

@interface UITableViewHeaderFooterView (WalletAdditions)
- (id)_viewControllerForAncestor;
@end

@interface UITableViewCell (WalletAdditions)
- (id)_viewControllerForAncestor;
@end

@interface UISegmentedControl (WalletAdditions)
@property (nonatomic, retain) UIColor *tintColor;
- (id)_viewControllerForAncestor;
@end


// MARK: - Wallet
%group Wallet122UI

%hook _UITableViewCellSeparatorView
- (void)layoutSubviews {
    if ([[NSString stringWithFormat:@"%@", self._viewControllerForAncestor] containsString:@"PassDetailViewController"]) {
        if (self.frame.origin.x == 0) {
            self.backgroundColor = [UIColor clearColor];
        }
    }
}
%end

%hook UISegmentedControl
- (void)layoutSubviews {
    %orig;
    if ([[NSString stringWithFormat:@"%@", self._viewControllerForAncestor] containsString:@"PassDetailViewController"]) {
        self.tintColor = [UIColor blackColor];
    }
}
%end

%hook UITableViewCell
- (void)layoutSubviews {
    %orig;
    if ([[NSString stringWithFormat:@"%@", self._viewControllerForAncestor] containsString:@"PassDetailViewController"]) {
        CGRect _frame = self.frame;
        if (_frame.origin.x == 0) {

            self.layer.cornerRadius = 10;
            self.clipsToBounds = YES;

            _frame.size.width = _frame.size.width - 32;
            _frame.origin.x = 16;
            self.frame = _frame;

            typedef enum {
                Lone=0,
                Bottom=1,
                Top=2,
                Middle=3
            } NEPCellPosition;

            NEPCellPosition _cellPosition = Middle;

            for (UIView *subview in self.subviews) {
                if ([[NSString stringWithFormat:@"%@", subview] containsString:@"_UITableViewCellSeparatorView"] && subview.frame.origin.x == 0 && subview.frame.origin.y == 0 && subview.frame.size.height == 0.5) {
                    _cellPosition = Top;
                    [subview removeFromSuperview];
                }
            }

            for (UIView *subview in self.subviews) {
                if ([[NSString stringWithFormat:@"%@", subview] containsString:@"_UITableViewCellSeparatorView"] && subview.frame.origin.x == 0 && subview.frame.origin.y > 0 && subview.frame.size.height == 0.5) {
                    if (_cellPosition == Top) {
                        _cellPosition = Lone;
                    } else {
                        _cellPosition = Bottom;
                    }
                }
            }

            #pragma clang diagnostic push
            #pragma clang diagnostic ignored "-Wunguarded-availability"
            if (_cellPosition == Top) {
                self.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;
            } else if (_cellPosition == Bottom) {
                self.layer.maskedCorners = kCALayerMinXMaxYCorner | kCALayerMaxXMaxYCorner;
            } else if (_cellPosition == Middle) {
                self.layer.cornerRadius = 0;
                self.clipsToBounds = NO;
            }
            #pragma clang diagnostic pop
        }
    }
}
%end

%hook UITableViewHeaderFooterView
- (void)layoutSubviews {
    if ([[NSString stringWithFormat:@"%@", self._viewControllerForAncestor] containsString:@"PassDetailViewController"]) {
        if (self.frame.origin.x == 0) {
            CGRect _frame = self.frame;
            //if (_frame.size.width > 200) {
            _frame.size.width = _frame.size.width - 10;
            //}
            _frame.origin.x = _frame.origin.x + 5;
            self.frame = _frame;
        }
    }
    %orig;
}
%end

%end

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
    BOOL isHomeIndicatorEnabled = [[currentSettings objectForKey:@"isHomeIndicatorEnabled"] boolValue];
    BOOL isButtonCombinationOverrideDisabled = [[currentSettings objectForKey:@"isButtonCombinationOverrideDisabled"] boolValue];
    BOOL isTallKeyboardEnabled = [[currentSettings objectForKey:@"isTallKeyboardEnabled"] boolValue];
    BOOL isPIPEnabled = [[currentSettings objectForKey:@"isPIPEnabled"] boolValue];
    int  statusBarStyle = [[currentSettings objectForKey:@"statusBarStyle"] intValue];

    // Conditional status bar initialization
    NSArray *acceptedStatusBarIdentifiers = @[@"com.apple",
                                              @"com.culturedcode.ThingsiPhone",
                                              @"com.christianselig.Apollo",
                                              @"com.facebook.Messenger"
                                              ];

    BOOL isStatusBarEnabled = false;

    for (NSString *identifier in acceptedStatusBarIdentifiers) {
        if ([bundleIdentifier containsString:identifier]) {
          isStatusBarEnabled = true;
        }
    }

    if (isStatusBarEnabled && statusBarStyle == 0) {
        %init(StatusBar_Split58);
    } else {
        %init(StatusBar_Pad_ForcedCellular);
    }

    if (statusBarStyle != 2) {
      %init(ModernStatusBarView);
    }

    // Conditional inset adjustment initialization
    NSArray *acceptedInsetAdjustmentIdentifiers = @[@"com.apple",
                                              @"com.culturedcode.ThingsiPhone",
                                              @"com.christianselig.Apollo"
                                              ];

    BOOL isInsetAdjustmentEnabled = false;

    for (NSString *identifier in acceptedInsetAdjustmentIdentifiers) {
        if ([bundleIdentifier containsString:identifier] && ![bundleIdentifier containsString:@"mobilesafari"]) {
            isInsetAdjustmentEnabled = true;
        }
    }

    if (isInsetAdjustmentEnabled && isHomeIndicatorEnabled) {
        %init(TabBarSizing);
        %init(ToolbarSizing);
    }

    // SpringBoard
    if ([bundleIdentifier isEqualToString:@"com.apple.springboard"]) {
        if (statusBarStyle != 0) {
          _statusBarHeightStyle = Regular;
          if (@available(iOS 12.1, *)) {
            _controlCenterStatusBarInset = -20;
          } else {
            _controlCenterStatusBarInset = -24;
          }
        }
        %init(SpringBoardModifications);
        %init(ControlCenterModificationsStatusBar);
    }

    // Wallet
    if ([bundleIdentifier containsString:@"Passbook"]) {
        %init(Wallet122UI);
    }

    // Shortcuts
    if ([bundleIdentifier containsString:@"workflow"]) {
        %init(Shortcuts);
    }

    // Calendar
    if ([bundleIdentifier containsString:@"com.apple.mobilecal"]) {
        %init(Calendar);
    }

    // Twitter
    if ([bundleIdentifier containsString:@"com.atebits.Tweetie2"]) {
        %init(Twitter);
    }

    // Button combination override
    if (!isButtonCombinationOverrideDisabled) {
        %init(ButtonRemap)
    }

    // Picture in picture
    if (isPIPEnabled) {
        %init(PIPOverride);
    }

    // Keyboard height adjustment
    if (isTallKeyboardEnabled) {
        %init(KeyboardDock);
    }

    // Any ungrouped hooks
    %init(_ungrouped);

    // Respring notification observer
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                    NULL,
                                    &respring,
                                    CFSTR("respring"),
                                    NULL, 0);
}
