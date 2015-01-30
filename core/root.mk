# Component Path Configuration
export TARGET_PRODUCT := beagleboneblack
export ANDROID_INSTALL_DIR := $(patsubst %/,%, $(dir $(realpath $(lastword $(MAKEFILE_LIST)))))
export ANDROID_FS_DIR := $(ANDROID_INSTALL_DIR)/out/target/product/$(TARGET_PRODUCT)/android_rootfs
export CC_PREFIX := arm-linux-gnueabi-

kernel_not_configured := $(wildcard kernel/.config)

ifeq ($(TARGET_PRODUCT), beagleboneblack)
CLEAN_RULE = kernel_clean clean
rowboat: kernel_build
endif

kernel_build: droid
ifeq ($(strip $(kernel_not_configured)),)
	$(MAKE) -C kernel ARCH=arm am335x_evm_android_defconfig
endif
	$(MAKE) -C kernel ARCH=arm CROSS_COMPILE=$(CC_PREFIX) zImage dtbs -j9
	$(MAKE) -C kernel ARCH=arm CROSS_COMPILE=$(CC_PREFIX) modules -j9

kernel_clean:
	$(MAKE) -C kernel ARCH=arm  distclean

### DO NOT EDIT THIS FILE ###
include build/core/main.mk
### DO NOT EDIT THIS FILE ###

u-boot_build:
ifeq ($(TARGET_PRODUCT), beagleboneblack)
	$(MAKE) -C u-boot ARCH=arm am335x_evm_config
endif
	$(MAKE) -C u-boot ARCH=arm CROSS_COMPILE=$(CC_PREFIX)

u-boot_clean:
	$(MAKE) -C u-boot ARCH=arm CROSS_COMPILE=$(CC_PREFIX) distclean

# Make a tarball for the filesystem
fs_tarball: $(FS_GET_STATS)
	rm -rf $(ANDROID_FS_DIR)
	mkdir $(ANDROID_FS_DIR)
	cp -R $(ANDROID_INSTALL_DIR)/out/target/product/$(TARGET_PRODUCT)/root/* $(ANDROID_FS_DIR)
	cp -R $(ANDROID_INSTALL_DIR)/out/target/product/$(TARGET_PRODUCT)/system/* $(ANDROID_FS_DIR)/system
	$(MAKE) -C kernel ARCH=arm CROSS_COMPILE=$(CC_PREFIX) INSTALL_MOD_PATH=$(ANDROID_FS_DIR)/system modules_install
	(cd $(ANDROID_INSTALL_DIR)/out/target/product/$(TARGET_PRODUCT); \
	 ../../../../build/tools/mktarball.sh ../../../host/linux-x86/bin/fs_get_stats android_rootfs . rootfs rootfs.tar.bz2)

rowboat_clean: $(CLEAN_RULE)

sdcard_build: rowboat u-boot_build fs_tarball
	$(ANDROID_INSTALL_DIR)/external/ti_android_utilities/make_distribution.sh $(ANDROID_INSTALL_DIR) $(TARGET_PRODUCT)