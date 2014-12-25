include theos/makefiles/common.mk

TARGET := iphone:8.0:2.0
ARCHS := armv7 arm64

TWEAK_NAME = LockMemosPlus
LockMemosPlus_FILES = Tweak.xm
LockMemosPlus_FRAMEWORKS = UIKit 

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"

