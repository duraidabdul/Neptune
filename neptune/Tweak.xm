#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "./headers/MobileGesalt.h"

#define kBundlePath @"/Library/Application Support/Neptune"

NSString *bundleIdentifier;

BOOL isFluidInterfaceEnabled;
long _homeButtonType = 1;
BOOL isHomeIndicatorEnabled;
BOOL isButtonCombinationOverrideDisabled;
BOOL isTallKeyboardEnabled;
BOOL isPIPEnabled;
int  statusBarStyle;
BOOL applicationSupportsLargeStatusBar;
BOOL isWalletEnabled;
BOOL isNewsIconEnabled;
BOOL isTVIconEnabled;
BOOL isLegacyDevice;
BOOL roundedScreenCorners;
BOOL isRoundedDockEnabled;
BOOL isLockScreenControlCentreGrabberEnabled;
BOOL areQuickActionsEnabled;

double rootCornerRadius;

UIView *rootWindow;

@interface CALayer (CornerAddition)
-(bool)continuousCorners;
@property (assign) bool continuousCorners;
-(void)setContinuousCorners:(bool)arg1;
@end

/// MARK: - Group: Button remap
%group ButtonRemap

// Siri remap
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

// Screenshot remap
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
    return %orig(arg1,_homeButtonType,arg3,arg4);
}
- (id)initWithScreenshotGestureRecognizer:(id)arg1 homeButtonType:(long long)arg2 {
    return %orig(arg1,_homeButtonType);
}
%end

%hook SBLockHardwareButton
- (id)initWithScreenshotGestureRecognizer:(id)arg1 shutdownGestureRecognizer:(id)arg2 proximitySensorManager:(id)arg3 homeHardwareButton:(id)arg4 volumeHardwareButton:(id)arg5 buttonActions:(id)arg6 homeButtonType:(long long)arg7 createGestures:(_Bool)arg8 {
    return %orig(arg1,arg2,arg3,arg4,arg5,arg6,_homeButtonType,arg8);
}
- (id)initWithScreenshotGestureRecognizer:(id)arg1 shutdownGestureRecognizer:(id)arg2 proximitySensorManager:(id)arg3 homeHardwareButton:(id)arg4 volumeHardwareButton:(id)arg5 homeButtonType:(long long)arg6 {
    return %orig(arg1,arg2,arg3,arg4,arg5,_homeButtonType);
}
%end

%hook SBVolumeHardwareButton
- (id)initWithScreenshotGestureRecognizer:(id)arg1 shutdownGestureRecognizer:(id)arg2 homeButtonType:(long long)arg3 {
    return %orig(arg1,arg2,_homeButtonType);
}
%end

%end

%group ControlCenter122UI

// MARK: Control Center media controls transition (from iOS 12.2 beta)
@interface MediaControlsRoutingButtonView : UIView
@property (nonatomic, retain) UIImageView *playbackIconImageView;
@property (nonatomic, retain) UIImageView *airplayIconImageView;
@property (nonatomic, retain) CALayer *platterLayer;
@property (nonatomic, assign) long long currentCachedMode;
- (long long)currentMode;
- (void)_updateGlyph;
@end

%hook MediaControlsRoutingButtonView
%property (nonatomic, retain) UIImageView *playbackIconImageView;
%property (nonatomic, retain) UIImageView *airplayIconImageView;
%property (nonatomic, retain) CALayer *platterLayer;
%property (nonatomic, assign) long long currentCachedMode;

-(void)layoutSubviews {
  %orig;

  if (!self.playbackIconImageView) {
    self.airplayIconImageView = [[UIImageView alloc] initWithFrame:CGRectMake(1,1,36,36)];
    self.playbackIconImageView = [[UIImageView alloc] initWithFrame:CGRectMake(1,1,36,36)];

    self.playbackIconImageView.layer.transform = CATransform3DMakeScale(0.75, 0.75, 1);
    self.playbackIconImageView.layer.opacity = -0.8;

    NSBundle *bundle = [[NSBundle alloc] initWithPath:kBundlePath];

    NSString *imagePath = [bundle pathForResource:@"playbackIcon_MP@2x" ofType:@"png"];
    UIImage *playbackIconImage = [UIImage imageWithContentsOfFile:imagePath];
    self.playbackIconImageView.image = playbackIconImage;

    NSString *imagePath2 = [bundle pathForResource:@"airplayIcon_MP@2x" ofType:@"png"];
    UIImage *airplayIconImage = [UIImage imageWithContentsOfFile:imagePath2];
    self.airplayIconImageView.image = airplayIconImage;
  }

  if (self.layer.sublayers.count >= 1) {
    if (self.layer.sublayers[0].sublayers.count >= 1) {
      if (self.layer.sublayers[0].sublayers[0].sublayers.count == 2) {

        CALayer* AirPlayIcon = self.layer.sublayers[0].sublayers[0].sublayers[1].sublayers[1];
        CALayer* playbackIcon = self.layer.sublayers[0].sublayers[0].sublayers[1].sublayers[1];

        if (AirPlayIcon.opacity != 0 || playbackIcon.opacity != 0) {
          [self addSubview:self.airplayIconImageView];
          [self addSubview:self.playbackIconImageView];

          self.platterLayer = self.layer.sublayers[0].sublayers[0].sublayers[1];
          self.platterLayer.cornerRadius = 18;

          AirPlayIcon.opacity = 0;
          playbackIcon.opacity = 0;

          [self _updateGlyph];
        }
      }
    }
  }
}

- (void)_updateGlyph {

    if (self.currentMode == self.currentCachedMode) { return; }

    self.currentCachedMode = self.currentMode;

    if (self.currentMode == 2) { // Play/Pause Mode

        UIViewPropertyAnimator *animator = [[UIViewPropertyAnimator alloc] initWithDuration:0.75 dampingRatio:1 animations:^{
            self.playbackIconImageView.layer.transform = CATransform3DMakeScale(1, 1, 1);
            self.playbackIconImageView.layer.opacity = 0.95;
        }];
        [animator startAnimation];

        UIViewPropertyAnimator *animator2 = [[UIViewPropertyAnimator alloc] initWithDuration:1 dampingRatio:1 animations:^{
            self.airplayIconImageView.layer.transform = CATransform3DMakeScale(0.85, 0.85, 1);
            self.airplayIconImageView.layer.opacity = -0.8;

            self.platterLayer.backgroundColor = [[UIColor colorWithRed:0 green:0.478 blue:1.0 alpha:0.0] CGColor];
        }];
        [animator2 startAnimation];

    } else if (self.currentMode == 0 || self.currentMode == 1) { // AirPlay Mode

        UIViewPropertyAnimator *animator = [[UIViewPropertyAnimator alloc] initWithDuration:1 dampingRatio:1 animations:^{
            self.playbackIconImageView.layer.transform = CATransform3DMakeScale(0.75, 0.75, 1);
            self.playbackIconImageView.layer.opacity = -0.8;
        }];
        [animator startAnimation];

        UIViewPropertyAnimator *animator2 = [[UIViewPropertyAnimator alloc] initWithDuration:0.75 dampingRatio:1 animations:^{
            self.airplayIconImageView.layer.transform = CATransform3DMakeScale(1, 1, 1);
            if (self.currentMode == 0) {
                self.airplayIconImageView.layer.opacity = 0.95;
                self.platterLayer.backgroundColor = [[UIColor colorWithRed:0 green:0.478 blue:1.0 alpha:0] CGColor];
            } else if (self.currentMode == 1) {
                self.airplayIconImageView.layer.opacity = 1;
                self.platterLayer.backgroundColor = [[UIColor colorWithRed:0 green:0.478 blue:1.0 alpha:1.0] CGColor];
            }
        }];
        [animator2 startAnimation];
    }
}
%end

%hook MediaControlsMasterVolumeSlider
- (void)setMaximumValueImage:(id)arg1 {
  NSBundle *bundle = [[NSBundle alloc] initWithPath:kBundlePath];
  NSString *imagePath = [bundle pathForResource:@"volume_max@2x" ofType:@"png"];
  UIImage *minImage = [UIImage imageWithContentsOfFile:imagePath];
  return %orig(minImage);
}
- (void)setMinimumValueImage:(id)arg1 {
  NSBundle *bundle = [[NSBundle alloc] initWithPath:kBundlePath];
  NSString *imagePath = [bundle pathForResource:@"volume_min@2x" ofType:@"png"];
  UIImage *maxImage = [UIImage imageWithContentsOfFile:imagePath];
  return %orig(maxImage);
}
%end

%end

%group SBButtonRefinements

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
        UIViewPropertyAnimator *animator = [[UIViewPropertyAnimator alloc] initWithDuration:0.3 dampingRatio:1 animations:^{
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

// Add continuous corners to folder icon blur view.
@interface SBFolderIconBackgroundView : UIView
@end

%hook SBFolderIconBackgroundView
- (void)layoutSubviews {
    %orig;
    self.layer.continuousCorners = YES;
}
%end

// MARK: Add button highlight animation in cover sheet.
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

%end

/// MARK: - Group: SpringBoard modifications
%group FluidInterface

// MARK: Enable fluid switcher
%hook BSPlatform
- (NSInteger)homeButtonType {
  return 2;
}
%end

// Hide Home Indicator
@interface MTLumaDodgePillView : UIView
@end

%hook MTLumaDodgePillView
- (id)initWithFrame:(struct CGRect)arg1 {
  if (!isHomeIndicatorEnabled) {
    return NULL;
  }
  return %orig;
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

    if (areQuickActionsEnabled) {
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
    } else {
      self.hidden = true;
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

    if (!isLockScreenControlCentreGrabberEnabled) {
      return;
    }

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

    rootWindow = self;

    %orig;

    if (rootCornerRadius >= 0.5) {
      self.clipsToBounds = YES;
    }

    UIViewPropertyAnimator *animator = [[UIViewPropertyAnimator alloc] initWithDuration:0.3 dampingRatio:1 animations:^{
        self._continuousCornerRadius = rootCornerRadius;
    }];
    [animator startAnimation];
}
%end

// Implement corner radius adjustment for when in the app switcher scroll view.]

// Implement round screenshot preview edge insets.
%hook UITraitCollection
+ (id)traitCollectionWithDisplayCornerRadius:(CGFloat)arg1 {
    return %orig(18);
}
%end

@interface SBAppSwitcherPageView : UIView
@property(nonatomic, assign) double cornerRadius;
@property(nonatomic) _Bool blocksTouches;
@property(nonatomic) double shadowAlpha;
- (void)_updateCornerRadius;
@end

BOOL blockerPropagatedEvent = false;
BOOL shadowPropagatedEvent = false;
double currentCachedCornerRadius = 0;

/// IMPORTANT: DO NOT MESS WITH THIS LOGIC. EVERYTHING HERE IS DONE FOR A REASON.

// Override rendered corner radius in app switcher page, (for anytime the fluid switcher gestures are running).
%hook SBAppSwitcherPageView

-(void)setShadowAlpha:(CGFloat)arg1 {
  if (arg1 == 1 && self.shadowAlpha == 0) {
    shadowPropagatedEvent = true;
    self.cornerRadius = 18;
    [self _updateCornerRadius];
    shadowPropagatedEvent = false;
  }
  %orig;
}
-(void)setBlocksTouches:(BOOL)arg1 {
    if (!arg1 && (self.cornerRadius == 18 || self.cornerRadius == rootCornerRadius || self.cornerRadius == 3.5)) {
        blockerPropagatedEvent = true;
        self.cornerRadius = rootCornerRadius;
        [self _updateCornerRadius];
        blockerPropagatedEvent = false;
    } else if (self.cornerRadius == 18 || self.cornerRadius == rootCornerRadius || self.cornerRadius == 3.5) {
        blockerPropagatedEvent = true;
        self.cornerRadius = 18;
        [self _updateCornerRadius];
        blockerPropagatedEvent = false;
    }

    %orig(arg1);
}

- (void)setCornerRadius:(CGFloat)arg1 {

    currentCachedCornerRadius = MSHookIvar<double>(self, "_cornerRadius");

    CGFloat arg1_overwrite = arg1;

    if (shadowPropagatedEvent) {
      return %orig(arg1);
    }

    if ((arg1 != 18 || arg1 != rootCornerRadius || arg1 != 0) && self.blocksTouches) {
        return %orig(arg1);
    }

    if (blockerPropagatedEvent && arg1 != 18) {
        return %orig(arg1);
    }

    if (arg1 == 0 && !self.blocksTouches) {
        %orig(0);
        return;
    }

    if (self.blocksTouches) {
        arg1_overwrite = 18;
    } else if (arg1 == 18) {
        // THIS IS THE ONLY BLOCK YOU CAN CHANGE
        arg1_overwrite = rootCornerRadius;
        // Todo: detect when, in this case, the app is being pulled up from the bottom, and activate the rounded corners.
    }

    UIView* _overlayClippingView = MSHookIvar<UIView*>(self, "_overlayClippingView");
    if (!_overlayClippingView.layer.allowsEdgeAntialiasing) {
        _overlayClippingView.layer.allowsEdgeAntialiasing = true;
    }

    %orig(arg1_overwrite);
}

- (void)_updateCornerRadius {
    /// CAREFUL HERE, WATCH OUT FOR THE ICON MORPH ANIMATION ON APPLICATION LAUNCH.
    if ((self.cornerRadius == rootCornerRadius && currentCachedCornerRadius == 18)) {
        UIViewPropertyAnimator *animator = [[UIViewPropertyAnimator alloc] initWithDuration:0.35 dampingRatio:1 animations:^{
            %orig;
        }];
        [animator startAnimation];
    } else {
        %orig;
    }
}
%end

// Override Reachability corner radius.
%hook SBReachabilityBackgroundView
- (double)_displayCornerRadius {
    return rootCornerRadius;
}
%end


// MARK: Reachability settings override
%hook SBReachabilitySettings
- (void)setSystemWideSwipeDownHeight:(double) systemWideSwipeDownHeight {
    return %orig(100);
}
%end

%end

%group DisableRoundedDock

%hook SBDockView
- (void)_updateCornerRadii {
  return;
}
- (void)PG_setHasRoundedCorners:(BOOL)arg1 animated:(BOOL)arg2 {
  return %orig;
}
- (NSUInteger)dockEdge {
  return 4;
}
- (CGFloat)dockHeight {
  return 96;
}
- (CGFloat)dockHeightPadding {
  return 4;
}
- (BOOL)isDockInset {
  return 0;
}
%end

%end

%group KeyboardDock

%hook UIKeyboardImpl
+(UIEdgeInsets)deviceSpecificPaddingForInterfaceOrientation:(NSInteger)orientation inputMode:(id)mode {
    UIEdgeInsets orig = %orig;
    orig.bottom = 48;
    return orig;
}

%end

@interface UIKeyboardDockView : UIView
@end

%hook UIKeyboardDockView

- (CGRect)bounds {
    CGRect bounds = %orig;
    if (bounds.origin.y == 0) {
        bounds.origin.y -= 12;
    }
    return bounds;
}

%end

%hook UIInputWindowController
- (UIEdgeInsets)_viewSafeAreaInsetsFromScene {
    return UIEdgeInsetsMake(0,0,44,0);
}
%end

%end

int _controlCenterStatusBarInset = -10;

// MARK: - Group: SpringBoard modifications (Control Center Status Bar inset)
%group ControlCenterModificationsStatusBar

@interface CCUIHeaderPocketView : UIView
@end

%hook CCUIHeaderPocketView
- (void)layoutSubviews {
    if (!isLegacyDevice) { return %orig; }
    %orig;

    CGRect _frame = self.frame;
    _frame.origin.y = _controlCenterStatusBarInset;
    self.frame = _frame;
}
%end

%end

%group StatusBarProvider

// MARK: - Variable modern status bar implementation

%hook _UIStatusBarVisualProvider_iOS
+ (Class)class {
    if (!isLegacyDevice) { return %orig; }
    if ((statusBarStyle == 0 && applicationSupportsLargeStatusBar) || statusBarStyle == 3) {
        return NSClassFromString(@"_UIStatusBarVisualProvider_Split58");
    } else if (@available(iOS 12.1, *)) {
      return NSClassFromString(@"_UIStatusBarVisualProvider_RoundedPad_ForcedCellular");
    }
    return NSClassFromString(@"_UIStatusBarVisualProvider_Pad_ForcedCellular");
}
%end

%hook _UIStatusBar
+ (double)heightForOrientation:(long long)arg1 {
  if (!isLegacyDevice) { return %orig; }
  if (arg1 == 1 || arg1 == 2) {
      if (statusBarStyle == 0 || statusBarStyle == 3) {
          return %orig - 10;
      } else if (statusBarStyle == 1) {
          return %orig - 4;
      }
  }
  return %orig;
}
%end

%end


%group StatusBarModern

%hook UIStatusBarWindow
+ (void)setStatusBar:(Class)arg1 {
    return %orig(NSClassFromString(@"UIStatusBar_Modern"));
}
%end

%hook UIStatusBar_Base
+ (Class)_implementationClass {
    return NSClassFromString(@"UIStatusBar_Modern");
}
+ (void)_setImplementationClass:(Class)arg1 {
    return %orig(NSClassFromString(@"UIStatusBar_Modern"));
}
%end

%hook _UIStatusBarData
- (void)setBackNavigationEntry:(id)arg1 {
    return;
}
%end

%end


float _bottomInset = 21;

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

- (UIEdgeInsets)safeAreaInsetsLandscapeLeft {
    UIEdgeInsets _insets = %orig;
    _insets.bottom = _bottomInset;
    return _insets;
}
- (UIEdgeInsets)safeAreaInsetsLandscapeRight {
    UIEdgeInsets _insets = %orig;
    _insets.bottom = _bottomInset;
    return _insets;
}
- (UIEdgeInsets)safeAreaInsetsPortrait {
    UIEdgeInsets _insets = %orig;
    _insets.bottom = _bottomInset;
    return _insets;
}
- (UIEdgeInsets)safeAreaInsetsPortraitUpsideDown {
    UIEdgeInsets _insets = %orig;
    _insets.bottom = _bottomInset;
    return _insets;
}

%end

%end


// Hide home indicator.
%group HideLuma

%hook UIViewController
- (BOOL)prefersHomeIndicatorAutoHidden {
    return YES;
}
%end

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
        _frame.origin.y -= 3.5;
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

@interface UITextView (WalletAdditions)
- (id)_viewControllerForAncestor;
@end

@interface PKContinuousButton : UIView
@end


// Theming system for app icons.
%group NEPThemeEngine

@interface SBApplicationIcon : NSObject
@end

%hook SBApplicationIcon
- (id)getCachedIconImage:(int)arg1 {

    NSString *_applicationBundleID = MSHookIvar<NSString*>(self, "_applicationBundleID");

    if (/*[_applicationBundleID isEqualToString:@"com.atebits.Tweetie2"] || */([_applicationBundleID isEqualToString:@"com.apple.news"] && isNewsIconEnabled) || ([_applicationBundleID isEqualToString:@"com.apple.tv"] && isTVIconEnabled)) {

        NSBundle *bundle = [[NSBundle alloc] initWithPath:kBundlePath];
        NSString *imagePath = [bundle pathForResource:_applicationBundleID ofType:@"png"];
        UIImage *myImage = [UIImage imageWithContentsOfFile:imagePath];

        return myImage;
    }
    return %orig;
}
- (id)getUnmaskedIconImage:(int)arg1 {

    NSString *_applicationBundleID = MSHookIvar<NSString*>(self, "_applicationBundleID");

    if (/*[_applicationBundleID isEqualToString:@"com.atebits.Tweetie2"] || */([_applicationBundleID isEqualToString:@"com.apple.news"] && isNewsIconEnabled) || ([_applicationBundleID isEqualToString:@"com.apple.tv"] && isTVIconEnabled)) {

        NSBundle *bundle = [[NSBundle alloc] initWithPath:kBundlePath];
        NSString *imagePath = [bundle pathForResource:[NSString stringWithFormat:@"%@_unmasked", _applicationBundleID] ofType:@"png"];
        UIImage *myImage = [UIImage imageWithContentsOfFile:imagePath];

        return myImage;
    }
    return %orig;
}
- (id)generateIconImage:(int)arg1 {

    NSString *_applicationBundleID = MSHookIvar<NSString*>(self, "_applicationBundleID");

    if (/*[_applicationBundleID isEqualToString:@"com.atebits.Tweetie2"] || */([_applicationBundleID isEqualToString:@"com.apple.news"] && isNewsIconEnabled) || ([_applicationBundleID isEqualToString:@"com.apple.tv"] && isTVIconEnabled)) {

        NSBundle *bundle = [[NSBundle alloc] initWithPath:kBundlePath];
        NSString *imagePath = [bundle pathForResource:_applicationBundleID ofType:@"png"];
        UIImage *myImage = [UIImage imageWithContentsOfFile:imagePath];

        return myImage;
    }
    return %orig;
}
%end

%end

// MARK: - Wallet iOS 12.2 interface.
%group Wallet122UI

%hook _UITableViewCellSeparatorView
- (void)layoutSubviews {
    if ([[NSString stringWithFormat:@"%@", self._viewControllerForAncestor] containsString:@"PassDetailViewController"] || [[NSString stringWithFormat:@"%@", self._viewControllerForAncestor] containsString:@"PKPaymentPreferencesViewController"]) {
        if (self.frame.origin.x == 0) {
            self.hidden = YES;
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

%hook UITextView
- (void)layoutSubviews {
    %orig;
    CGRect _frame = self.frame;
    if ([[NSString stringWithFormat:@"%@", self._viewControllerForAncestor] containsString:@"PKBarcodePassDetailViewController"] && _frame.origin.x == 16) {
        _frame.origin.x += 10;
        self.frame = _frame;
    }
}
%end

@interface PKPaymentTransactionTableCell : UIView
@end

%hook PKPaymentTransactionTableCell
- (void)layoutSubviews {
  %orig;

  UILabel* _primaryLabel = MSHookIvar<UILabel*>(self, "_primaryLabel");
  _primaryLabel.font = [UIFont systemFontOfSize:17.0 weight:UIFontWeightSemibold];
  CGRect transitionFrame = _primaryLabel.frame;
  transitionFrame.origin.y = 7;
  _primaryLabel.frame = transitionFrame;

  UILabel* _transactionValueLabel = MSHookIvar<UILabel*>(self, "_transactionValueLabel");
  transitionFrame = _transactionValueLabel.frame;
  transitionFrame.origin.y = 7;
  _transactionValueLabel.frame = transitionFrame;

  UILabel* _secondaryLabel = MSHookIvar<UILabel*>(self, "_secondaryLabel");
  _secondaryLabel.font = [UIFont systemFontOfSize:13.0];

  UILabel* _tertiaryLabel = MSHookIvar<UILabel*>(self, "_tertiaryLabel");
  _tertiaryLabel.font = [UIFont systemFontOfSize:13.0];

  UIView* _accessoryView = MSHookIvar<UILabel*>(self, "_accessoryView");
  transitionFrame = _accessoryView.frame;
  transitionFrame.origin.y = 10.5;
  _accessoryView.frame = transitionFrame;
}
%end

%hook UITableViewCell
- (void)layoutSubviews {
    %orig;
    if ([[NSString stringWithFormat:@"%@", self._viewControllerForAncestor] containsString:@"PassDetailViewController"] || [[NSString stringWithFormat:@"%@", self._viewControllerForAncestor] containsString:@"PKPaymentPreferencesViewController"]) {
        CGRect _frame = self.frame;
        if (_frame.origin.x == 0) {

            self.layer.cornerRadius = 10;
            self.clipsToBounds = YES;

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

            _frame.size.width -= 32;
            _frame.origin.x = 16;
            self.frame = _frame;
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
            _frame.size.width -= 10;
            //}
            _frame.origin.x += 5;
            self.frame = _frame;
        }
    }
    %orig;
}
%end

%end

%group Maps

@interface MapsProgressButton : UIView
@end

%hook MapsProgressButton
- (void)layoutSubviews {
    %orig;
    self.layer.continuousCorners = true;
}
%end

%end

%group Castro

@interface SUPTabsCardViewController : UIViewController
@end

%hook SUPTabsCardViewController
- (void)viewDidLoad {
    %orig;
    self.view.layer.mask = NULL;
    self.view.layer.continuousCorners = YES;
    self.view.layer.masksToBounds = YES;
    self.view.layer.cornerRadius = 10;
}
%end

@interface SUPDimExternalImageViewButton : UIView
- (void)setHighlighted:(bool)arg1;
@end

%hook SUPDimExternalImageViewButton
- (void)setHighlighted:(bool)arg1 {
    if (arg1 == YES) {

        UIViewPropertyAnimator *animator = [[UIViewPropertyAnimator alloc] initWithDuration:0.1 curve:UIViewAnimationCurveEaseOut animations:^{
            %orig;
        }];
        [animator startAnimation];
    } else {
        UIViewPropertyAnimator *animator = [[UIViewPropertyAnimator alloc] initWithDuration:0.4 dampingRatio:1 animations:^{
            %orig;
        }];
        [animator startAnimation];
    }
    return;
}
%end

%end

%group Things

%hook UAPopoverView
-(void)layoutSubviews {
    %orig;

    UIView* _contentView = MSHookIvar<UIView*>(self, "_contentView");
    _contentView.layer.continuousCorners = YES;
}
%end

%end

static void updatePreferences() {

  bundleIdentifier = [NSBundle mainBundle].bundleIdentifier;

  // Gather current preference keys.
  NSString *settingsPath = @"/var/mobile/Library/Preferences/com.duraidabdul.neptune.plist";

  NSFileManager *fileManager = [NSFileManager defaultManager];

  NSMutableDictionary *currentSettings;

  BOOL shouldReadAndWriteDefaults = false;

  if ([fileManager fileExistsAtPath:settingsPath]){
      currentSettings = [[NSMutableDictionary alloc] initWithContentsOfFile:settingsPath];
      if ([[currentSettings objectForKey:@"preferencesVersionID"] intValue] != 100) {
        shouldReadAndWriteDefaults = true;
      }
  } else {
    shouldReadAndWriteDefaults = true;
  }

  if (shouldReadAndWriteDefaults) {
    NSBundle *bundle = [[NSBundle alloc] initWithPath:kBundlePath];
    NSString *defaultsPath = [bundle pathForResource:@"defaults" ofType:@"plist"];
    currentSettings = [[NSMutableDictionary alloc] initWithContentsOfFile:defaultsPath];

    [currentSettings writeToFile: settingsPath atomically:YES];
  }

  isFluidInterfaceEnabled = [[currentSettings objectForKey:@"isFluidInterfaceEnabled"] boolValue];
  isHomeIndicatorEnabled = [[currentSettings objectForKey:@"isHomeIndicatorEnabled"] boolValue];
  isButtonCombinationOverrideDisabled = [[currentSettings objectForKey:@"isButtonCombinationOverrideDisabled"] boolValue];
  isTallKeyboardEnabled = [[currentSettings objectForKey:@"isTallKeyboardEnabled"] boolValue];
  isPIPEnabled = [[currentSettings objectForKey:@"isPIPEnabled"] boolValue];
  statusBarStyle = [[currentSettings objectForKey:@"statusBarStyle"] intValue];
  isWalletEnabled = [[currentSettings objectForKey:@"isWalletEnabled"] boolValue];
  isNewsIconEnabled = [[currentSettings objectForKey:@"isNewsIconEnabled"] boolValue];
  isTVIconEnabled = [[currentSettings objectForKey:@"isTVIconEnabled"] boolValue];
  rootCornerRadius = [[currentSettings objectForKey:@"rootCornerRadius"] doubleValue];
  isLockScreenControlCentreGrabberEnabled = [[currentSettings objectForKey:@"isLockScreenControlCentreGrabberEnabled"] boolValue];
  areQuickActionsEnabled = [[currentSettings objectForKey:@"areQuickActionsEnabled"] boolValue];

  [rootWindow layoutSubviews];

  NSString *modelName = (NSString*)MGCopyAnswer(kMGMarketingName);

  if ([modelName containsString:@"iPhone X"] || [modelName containsString:@"iPad"]) {
    isLegacyDevice = false;
  } else {
    isLegacyDevice = true;
  }

  if ([modelName containsString:@"iPhone SE"] || [modelName containsString:@"iPhone 5"]) {
    isRoundedDockEnabled = false;
  } else {
    isRoundedDockEnabled = true;
  }
}

static void requestPreferenceUpdate(CFNotificationCenterRef center,void *observer,CFStringRef name,const void *object,CFDictionaryRef userInfo){
	updatePreferences();
}

%ctor {

    updatePreferences();
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                    NULL,
                                    &requestPreferenceUpdate,
                                    CFSTR("com.duraidabdul.neptune/requestPreferenceUpdate"),
                                    NULL, 0);

    // Conditional status bar initialization
    NSArray *acceptedStatusBarIdentifiers = @[@"com.apple",
                                              @"com.culturedcode.ThingsiPhone",
                                              @"com.christianselig.Apollo",
                                              @"co.supertop.Castro-2",
                                              @"com.facebook.Messenger",
                                              @"com.saurik.Cydia",
                                              @"is.workflow.my.app"
                                              ];

    // Use iPad visual provider if the large status bar isn't supported.

    for (NSString *identifier in acceptedStatusBarIdentifiers) {
      if ([bundleIdentifier containsString:identifier]) {
        applicationSupportsLargeStatusBar = true;
      }
    }

    %init(StatusBarProvider);

    if (statusBarStyle == 0 || statusBarStyle == 1 || statusBarStyle == 3) {
      %init(StatusBarModern);
    }

    // Conditional inset adjustment initialization
    NSArray *acceptedInsetAdjustmentIdentifiers = @[@"com.apple",
                                                    @"com.culturedcode.ThingsiPhone",
                                                    @"com.christianselig.Apollo",
                                                    @"co.supertop.Castro-2",
                                                    @"com.chromanoir.Zeit",
                                                    @"com.chromanoir.spectre",
                                                    @"com.saurik.Cydia",
                                                    @"is.workflow.my.app"
                                                    ];
    NSArray *acceptedInsetAdjustmentIdentifiers_NoTabBarLabels = @[@"com.facebook.Facebook",
                                                                   @"com.facebook.Messenger",
                                                                   @"com.burbn.instagram",
                                                                   @"com.medium.reader",
                                                                   @"com.pcalc.mobile"
                                                                   ];

    BOOL isInsetAdjustmentEnabled = false;

    if (![bundleIdentifier containsString:@"mobilesafari"]) {
        for (NSString *identifier in acceptedInsetAdjustmentIdentifiers) {
            if ([bundleIdentifier containsString:identifier]) {
                isInsetAdjustmentEnabled = true;
                break;
            }
        }
        if (!isInsetAdjustmentEnabled) {
            for (NSString *identifier in acceptedInsetAdjustmentIdentifiers_NoTabBarLabels) {
                if ([bundleIdentifier containsString:identifier]) {
                    _bottomInset = 16;
                    isInsetAdjustmentEnabled = true;
                }
            }
        }
    }

    // Home indicator visibility
    if (isHomeIndicatorEnabled && isFluidInterfaceEnabled) {
      if (isInsetAdjustmentEnabled) {
          %init(TabBarSizing);
          %init(ToolbarSizing);
      } else {
          %init(HideLuma);
      }
    }

    // SpringBoard
    if ([bundleIdentifier isEqualToString:@"com.apple.springboard"]) {
        if (statusBarStyle != 0 && statusBarStyle != 3) {
            _statusBarHeightStyle = Regular;
            _controlCenterStatusBarInset = -24;
        }
        if (isFluidInterfaceEnabled) {
          %init(FluidInterface)
          if (!isRoundedDockEnabled) {
            %init(DisableRoundedDock)
          }
          if (!isButtonCombinationOverrideDisabled) {
            %init(ButtonRemap)
          }
        }

        %init(SBButtonRefinements)

        %init(ControlCenter122UI)
        if (isFluidInterfaceEnabled) {
          %init(ControlCenterModificationsStatusBar)
        }
    } else if ([bundleIdentifier containsString:@"Passbook"] && isWalletEnabled) {
        %init(Wallet122UI);
    } else if ([bundleIdentifier containsString:@"workflow"]) {
        %init(Shortcuts);
    } else if ([bundleIdentifier containsString:@"com.apple.mobilecal"]) {
        %init(Calendar);
    } else if ([bundleIdentifier containsString:@"com.apple.Maps"]) {
        %init(Maps);
    } else if ([bundleIdentifier containsString:@"supertop"]) {
        %init(Castro);
    } else if ([bundleIdentifier containsString:@"culturedcode.Things"]) {
        %init(Things);
    }

    if (isPIPEnabled) {
        %init(PIPOverride);
    }

    if ((isNewsIconEnabled || isTVIconEnabled) && [bundleIdentifier containsString:@"com.apple.springboard"]) {
        %init(NEPThemeEngine);
    }

    // Keyboard height adjustment
    if (isTallKeyboardEnabled && isLegacyDevice) {
      %init(KeyboardDock);
    }

    // Any ungrouped hooks
    %init(_ungrouped);
}
