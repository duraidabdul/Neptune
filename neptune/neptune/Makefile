ARCHS = armv7 arm64 arm64e

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = Neptune
Neptune_FILES = NPTRootListController.m
Neptune_INSTALL_PATH = /Library/PreferenceBundles
Neptune_FRAMEWORKS = UIKit
Neptune_LDFLAGS += ./Preferences.tbd ./SpringBoardServices.tbd

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/Neptune.plist$(ECHO_END)