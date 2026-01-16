# Makefile for AwsUpdater

.PHONY: all clean test

all:
	xcodebuild -scheme AwsUpdater -configuration Release

clean:
	xcodebuild -scheme AwsUpdater clean

test:
	xcodebuild -scheme AwsUpdater test
