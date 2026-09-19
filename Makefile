ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:15.0
THEOS_PACKAGE_SCHEME = roothide
DEBUG ?= 0
FINALPACKAGE ?= 0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = SmartDialSIM

SmartDialSIM_FILES = \
    Tweak.xm \
    $(shell find Config Models Search Services DialerIntegration Suggestions SIMCustomization Runtime Utilities -type f -name '*.m' | sort)

SmartDialSIM_FRAMEWORKS = Foundation UIKit Contacts CoreFoundation
SmartDialSIM_CFLAGS = -fobjc-arc -Wall -Wextra -Wno-unused-parameter
SmartDialSIM_LOGOS_DEFAULT_GENERATOR = internal

include $(THEOS_MAKE_PATH)/tweak.mk

SUBPROJECTS += Preferences
include $(THEOS_MAKE_PATH)/aggregate.mk

after-install::
	@echo "SmartDialSIM G6.1 audit-fixed candidate installed."
	@echo "Target: Apple Phone only. Adaptive integration is fail-safe and never initiates calls."
