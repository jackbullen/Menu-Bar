#import <Cocoa/Cocoa.h>
#import <IOKit/ps/IOPowerSources.h>
#import <IOKit/ps/IOPSKeys.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>
@property (nonatomic, strong) NSWindow *window;
@property (nonatomic, strong) NSTextField *batteryStatusField;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification {

    // get screen params
    NSScreen *mainScreen = [NSScreen mainScreen];
    CGFloat screenHeight = mainScreen.frame.size.height;
    CGFloat screenWidth = mainScreen.frame.size.width;
    CGFloat menuBarHeight = 20;
    CGFloat coverWidth = 300;

    self.window = [[NSWindow alloc] initWithContentRect:NSMakeRect(screenWidth - coverWidth, screenHeight - menuBarHeight, coverWidth, menuBarHeight)
                                               styleMask:NSWindowStyleMaskBorderless
                                                 backing:NSBackingStoreBuffered
                                                   defer:NO];
    [self.window setLevel:NSMainMenuWindowLevel + 1];
    [self.window setBackgroundColor:[NSColor whiteColor]];

    [self createButtonWithTitle:@"Activity" action:@selector(openActivityMonitor) atX:97];
    [self createButtonWithTitle:@"Settings" action:@selector(openSystemPreferences) atX:195];
    // [self createButtonWithTitle:@"Volume" action:@selector(openSoundPreferences) atX:310];

    NSTextField *batteryStatusField = [[NSTextField alloc] initWithFrame:NSMakeRect(0, -2, 100, 20)];
    batteryStatusField.stringValue = [self batteryStatus];
    batteryStatusField.bezeled = NO;
    batteryStatusField.font = [NSFont systemFontOfSize:14];
    batteryStatusField.drawsBackground = NO;
    batteryStatusField.editable = NO;
    batteryStatusField.selectable = NO;
    batteryStatusField.textColor = [NSColor darkGrayColor];
    [[self.window contentView] addSubview:batteryStatusField];

    [self.window makeKeyAndOrderFront:nil];

    // update battery status every 5 minutes
    [NSTimer scheduledTimerWithTimeInterval:300
                                     target:self
                                   selector:@selector(updateBatteryStatus)
                                   userInfo:nil
                                    repeats:YES];

    // key listener to show/hide window
    __block BOOL ctrlKeyDown = NO;
    __block BOOL altKeyDown = NO;
    __block BOOL cmdKeyDown = NO;

    [NSEvent addGlobalMonitorForEventsMatchingMask:(NSEventMaskKeyDown | NSEventMaskFlagsChanged) handler:^(NSEvent *event) {
        if (event.type == NSEventTypeFlagsChanged) {
            ctrlKeyDown = ([event modifierFlags] & NSEventModifierFlagControl) != 0;
            altKeyDown = ([event modifierFlags] & NSEventModifierFlagOption) != 0;
            cmdKeyDown = ([event modifierFlags] & NSEventModifierFlagCommand) != 0;
        }

        if (ctrlKeyDown && altKeyDown && cmdKeyDown) {
            if ([self.window isVisible]) {
                [self.window orderOut:nil];
            } else {
                [self.window makeKeyAndOrderFront:nil];
            }
        }
    }];

}
// helper for creating buttons
- (void)createButtonWithTitle:(NSString *)title action:(SEL)action atX:(CGFloat)x {
    NSButton *button = [[NSButton alloc] initWithFrame:NSMakeRect(x, -10, 100, 40)];
    [button setTitle:title];
    [button setButtonType:NSButtonTypeMomentaryPushIn];
    button.bezelStyle = NSBezelStyleRounded;
    button.bordered = NO;
    button.font = [NSFont systemFontOfSize:14];
    [button setAttributedTitle:[[NSAttributedString alloc] initWithString:title attributes:@{NSForegroundColorAttributeName:[NSColor darkGrayColor]}]];
    [button setTarget:self];
    [button setAction:action];
    [[self.window contentView] addSubview:button];
}

- (void)openActivityMonitor {
    [[NSWorkspace sharedWorkspace] launchAppWithBundleIdentifier:@"com.apple.ActivityMonitor" options:NSWorkspaceLaunchDefault additionalEventParamDescriptor:nil launchIdentifier:nil];
}

- (void)openSystemPreferences {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"x-apple.systempreferences:"]];
}

// - (void)openSoundPreferences {
//     [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"x-apple.systempreferences:com.apple.preference.sound"]];
// }

- (void)updateBatteryStatus {
    NSLog(@"Updating battery status to %@", [self batteryStatus]);
    self.batteryStatusField.stringValue = [self batteryStatus];
}


- (NSString *)batteryStatus {
    // get battery status
    CFTypeRef blob = IOPSCopyPowerSourcesInfo();
    CFArrayRef sources = IOPSCopyPowerSourcesList(blob);

    CFDictionaryRef pSource = NULL;
    const void *psValue;

    int numOfSources = CFArrayGetCount(sources);
    if (numOfSources == 0) {
        NSLog(@"No battery available");
        return @"No battery available";
    }

    for (int i = 0 ; i < numOfSources ; i++) {
        pSource = IOPSGetPowerSourceDescription(blob, CFArrayGetValueAtIndex(sources, i));
        if (!pSource) {
            NSLog(@"Unable to get power source description for source %d", i);
            continue;
        }
        psValue = (CFStringRef)CFDictionaryGetValue(pSource, CFSTR(kIOPSNameKey));

        int curCapacity = 0;
        int maxCapacity = 0;
        double percentage;

        psValue = CFDictionaryGetValue(pSource, CFSTR(kIOPSCurrentCapacityKey));
        CFNumberGetValue((CFNumberRef)psValue, kCFNumberSInt32Type, &curCapacity);
        NSLog(@"Current Capacity: %d", curCapacity);
        psValue = CFDictionaryGetValue(pSource, CFSTR(kIOPSMaxCapacityKey));
        CFNumberGetValue((CFNumberRef)psValue, kCFNumberSInt32Type, &maxCapacity);
        NSLog(@"Max Capacity: %d", maxCapacity);

        percentage = ((double)curCapacity/(double)maxCapacity) * 100;
        NSString *statusString = [NSString stringWithFormat:@"%.0f%%", percentage];
        NSLog(@"Status String: %@", statusString);

        return statusString;
    }
    return @"Battery status unknown";
}

@end
