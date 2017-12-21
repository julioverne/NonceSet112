include theos/makefiles/common.mk

APPLICATION_NAME = async_wake_ios

async_wake_ios_FILES = /mnt/d/codes/async_wake_ios/async_wake.c /mnt/d/codes/async_wake_ios/early_kalloc.c /mnt/d/codes/async_wake_ios/find_port.c /mnt/d/codes/async_wake_ios/kcall.c /mnt/d/codes/async_wake_ios/kmem.c /mnt/d/codes/async_wake_ios/kutils.c /mnt/d/codes/async_wake_ios/main.m /mnt/d/codes/async_wake_ios/symbols.c /mnt/d/codes/async_wake_ios/fun.c /mnt/d/codes/async_wake_ios/fun_objc.m /mnt/d/codes/async_wake_ios/patchfinder64.c /mnt/d/codes/async_wake_ios/NonceSet.mm
async_wake_ios_FRAMEWORKS =  UIKit MessageUI Social Twitter QuartzCore CoreGraphics Foundation CoreFoundation IOKit
async_wake_ios_PRIVATE_FRAMEWORKS = Preferences
async_wake_ios_LIBRARIES = MobileGestalt
async_wake_ios_LDFLAGS = -Wl,-segalign,4000 -Wl,-undefined,dynamic_lookup
async_wake_ios_CFLAGS = -fobjc-arc
async_wake_ios_ARCHS = arm64
export ARCHS = arm64

include $(THEOS_MAKE_PATH)/application.mk

all::
