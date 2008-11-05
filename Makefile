BUILD_DIR=build
DEFAULT_BUILDCONFIGURATION=Release

BUILDCONFIGURATION?=$(DEFAULT_BUILDCONFIGURATION)

all: 
	xcodebuild -alltargets -configuration $(BUILDCONFIGURATION) build

clean:
	xcodebuild -alltargets clean
