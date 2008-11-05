SRC_DIR=..
DOC_DIR=$(SRC_DIR)/Documentation
OUTPUT_DIR=build
DISK_IMG_DIR=$(OUTPUT_DIR)/DiskImage
RELEASE_NAME=SynergyKM
BUILDSTYLE=Release
SYNERGY_BUILD_DIR=$(SRC_DIR)/build/$(BUILDSTYLE)
BUILDFLAGS="BUILDCONFIGURATION=$(BUILDSTYLE)"

# What to do before running this script:
# - Set RELEASE_NAME

all: compile release source

compile:
	$(MAKE) $(BUILDFLAGS) -C $(SRC_DIR)

clean:
	$(MAKE) $(BUILDFLAGS) -C $(SRC_DIR) clean
	rm -rf $(OUTPUT_DIR)

openUp:
	$(MAKE) $(BUILDFLAGS) -C ./tools/openUp


source:
	rm -rf $(OUTPUT_DIR)/source
	mkdir $(OUTPUT_DIR)/source
	cp -R $(SRC_DIR)/Components $(OUTPUT_DIR)/source/Components
	cp -R -L $(SRC_DIR)/Documentation $(OUTPUT_DIR)/source/Documentation
	cp -R $(SRC_DIR)/SynergyKM.xcodeproj $(OUTPUT_DIR)/source/SynergyKM.xcodeproj
	cp $(SRC_DIR)/makefile $(OUTPUT_DIR)/source/makefile
	rm -rf $(OUTPUT_DIR)/source/build
	rm -rf $(OUTPUT_DIR)/source/Components/synergy/build/
	find $(OUTPUT_DIR)/source \( -name build -or -name .svn \) -type d -exec rm -rf {} \; -prune
	find $(OUTPUT_DIR)/source \( -name "*~" -or -name .DS_Store \) -type f -delete
	find $(OUTPUT_DIR)/source \( -name "*\.mode1" -or -name "*pbxuser" \) -type f -delete
	tar -c -C $(OUTPUT_DIR)/source -f $(OUTPUT_DIR)/$(RELEASE_NAME)-src.tar .
	bzip2 $(OUTPUT_DIR)/$(RELEASE_NAME)-src.tar

release: openUp
	@# clean build directory
	rm -rf $(OUTPUT_DIR)
	mkdir $(OUTPUT_DIR)
	mkdir $(DISK_IMG_DIR)
	@# copy installer
	cp -R $(SYNERGY_BUILD_DIR)/SynergyKM\ Installer.app $(DISK_IMG_DIR)
	/Developer/Tools/SetFile -a E $(DISK_IMG_DIR)/SynergyKM\ Installer.app
	@# copy Help Book
	cp -R -L $(DOC_DIR) $(DISK_IMG_DIR)
	mv $(DISK_IMG_DIR)/Documentation/SynergyKM\ Help $(DISK_IMG_DIR)/
	@# copy PrefPane
	cp -R $(SYNERGY_BUILD_DIR)/SynergyKM.prefpane $(DISK_IMG_DIR)
	@# delete svn and backup files
	find $(OUTPUT_DIR) -name ".svn" -type d -exec rm -rf {} \; -prune
	find $(OUTPUT_DIR) \( -name "*~" -or -name .DS_Store -or -name classes.nib -or -name info.nib \) -type f -delete
	@# make synergy disk image
	mkdir $(DISK_IMG_DIR)/.background
	cp $(SRC_DIR)/Components/Common/SynergyBackground.png $(DISK_IMG_DIR)/.background
	cp $(SRC_DIR)/Components/Common/SynergyKMDiskImage.icns $(DISK_IMG_DIR)/.VolumeIcon.icns
	./make-diskimage.sh $(OUTPUT_DIR)/$(RELEASE_NAME).dmg $(DISK_IMG_DIR) $(RELEASE_NAME) dmg.scpt


