# Makefile for AwsUpdater

.PHONY: all clean test install

BUILD_DIR = build
INSTALL_DIR = $(HOME)/bin

all:
	xcodebuild -scheme AwsUpdater -configuration Release -derivedDataPath $(BUILD_DIR)

install: all
	mkdir -p $(INSTALL_DIR)
	cp $(BUILD_DIR)/Build/Products/Release/AwsUpdater $(INSTALL_DIR)/

clean:
	xcodebuild -scheme AwsUpdater clean
	rm -rf $(PWD)/build

test:
	xcodebuild -scheme AwsUpdater test
