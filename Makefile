# Makefile for AwsUpdater

.PHONY: all clean test

all:
	xcodebuild -scheme AwsUpdater -configuration Release CONFIGURATION_BUILD_DIR=$(PWD)/build

clean:
	xcodebuild -scheme AwsUpdater clean
	rm -rf $(PWD)/build

test:
	xcodebuild -scheme AwsUpdater test
