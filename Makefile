TARGET := iphone:clang:latest:14.0
ARCHS = arm64 arm64e

INSTALL_TARGET_PROCESSES = Preferences

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = SettingsWiFiPassword

SettingsWiFiPassword_FILES = Tweak.swift Tweak.S
SettingsWiFiPassword_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
