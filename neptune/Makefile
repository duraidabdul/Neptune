ARCHS = armv7 arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Neptune
_THEOS_INTERNAL_PACKAGE_VERSION = 1.3-1
Neptune_FILES = Tweak.xm
Neptune_LIBRARIES = MobileGestalt

include $(THEOS_MAKE_PATH)/tweak.mk

SUBPROJECTS += neptune
include $(THEOS_MAKE_PATH)/aggregate.mk

after-install::
	install.exec "killall -9 backboardd"
