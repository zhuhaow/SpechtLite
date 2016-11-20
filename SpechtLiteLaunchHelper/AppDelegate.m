#import "AppDelegate.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    NSArray *pathComponents = [[[NSBundle mainBundle] bundlePath] pathComponents];
    pathComponents = [pathComponents subarrayWithRange:NSMakeRange(0, [pathComponents count] - 4)];
    NSString *path = [NSString pathWithComponents:pathComponents];
    NSString *binaryPath = [[NSBundle bundleWithPath:path] executablePath];
    [[NSWorkspace sharedWorkspace] launchApplication:binaryPath];
    [NSApp terminate:nil];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

@end
