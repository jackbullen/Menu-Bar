CC = clang
CFLAGS = -fobjc-arc -framework Cocoa -framework IOKit
SOURCES = main.c AppDelegate.m
OUTPUT = taskBar

all: $(SOURCES)
	$(CC) $(CFLAGS) $(SOURCES) -o $(OUTPUT)

clean:
	rm -f $(OUTPUT)
