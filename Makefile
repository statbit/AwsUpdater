# Makefile for AwsUpdater

SOURCES = AwsUpdater/main.swift \
          AwsUpdater/Providers.swift \
          AwsUpdater/CredentialsUpdater.swift

TARGET = aws-updater

.PHONY: all clean

all: $(TARGET)

$(TARGET): $(SOURCES)
	swiftc -O -o $(TARGET) $(SOURCES)

clean:
	rm -f $(TARGET)
