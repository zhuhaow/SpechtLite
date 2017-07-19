#import "AppDelegate.h"

@interface AppDelegate ()
    
@end

@implementation AppDelegate
    
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    BOOL alreadyRunning = NO;
    NSArray *running = [[NSWorkspace sharedWorkspace] runningApplications];
    for (NSRunningApplication *app in running) {
        if ([[app bundleIdentifier] isEqualToString:@"me.zhuhaow.osx.SpechtLite"]) {
            alreadyRunning = YES;
        }
    }
    
    if (!alreadyRunning) {
        NSArray *pathComponents = [[[NSBundle mainBundle] bundlePath] pathComponents];
        pathComponents = [pathComponents subarrayWithRange:NSMakeRange(0, [pathComponents count] - 4)];
        NSString *path = [NSString pathWithComponents:pathComponents];
        NSString *binaryPath = [[NSBundle bundleWithPath:path] executablePath];
        [[NSWorkspace sharedWorkspace] launchApplication:binaryPath];
        [NSApp terminate:nil];
    }
}
    
- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}
    
@end
