
XCODEBUILD_OPTIONS=-project 'HWMonitorSMC.xcodeproj' CONFIGURATION_BUILD_DIR=$(CURDIR)/build DEPLOYMENT_LOCATION=NO

XCODEBUILD_OPTIONS += -scheme 'HWMonitorSMC2'
XCODEBUILD_OPTIONS += -configuration 'Release'

HWMonitorSMC2:
	@echo [XCODE] $(PROGRAMS)
	@echo "Building HWMonitorSMC2.app.."
	@/usr/bin/xcodebuild $(XCODEBUILD_OPTIONS)
	@rm -rf build/*.swiftmodule
	@rm -rf build/*.dSYM
	@rm -rf build/*.zip
	@rm -rf build/HWMonitorSMC2\ Helper*
	@rm -f .DS_Store
	@build/hwmlpcconfig --release
	@open build

clean:
	@echo [CLEAN] $(PROGRAMS)
	@rm -rf build *~

.PHONY: HWMonitorSMC2 clean
