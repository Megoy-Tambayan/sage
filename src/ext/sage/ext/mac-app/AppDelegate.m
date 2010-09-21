//
//  AppDelegate.m
//
//  Created by Ivan Andrus on 26/6/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"
#import "AppController.h"
#import <WebKit/WebFrame.h>
#import <WebKit/WebView.h>
#import <Carbon/Carbon.h>

@implementation AppDelegate

+ (void)initialize{
    // Make sure default are up to date
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *factoryDefaults = [NSDictionary dictionaryWithContentsOfFile: [[NSBundle mainBundle] pathForResource:@"Defaults" ofType:@"plist"]];
    [defaults registerDefaults: factoryDefaults];
}

- (void)applicationWillFinishLaunching:(NSNotification *)aNotification{
    // This is early enough to show in the dock if we want to
    // http://www.cocoadev.com/index.pl?LSUIElement
    // http://codesorcery.net/2008/02/06/feature-requests-versus-the-right-way-to-do-it

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL isInDock = [defaults boolForKey:@"myShowInDock"];

    if ( isInDock ) {
        ProcessSerialNumber psn = { 0, kCurrentProcess };
        // display dock icon
        OSStatus returnCode = TransformProcessType(&psn, kProcessTransformToForegroundApplication);
        if( returnCode != 0 ) {
            // According to http://www.cocoadev.com/index.pl?TransformProcessType
            // TransformProcessType is available since 10.3, but doen't work for our case until 10.5
            NSLog(@"Could not show Sage.app in the dock. Error %d", returnCode);
            // It's forbidden to showInDock since it doesn't work
            [defaults setBool:NO forKey:@"myShowInDock"];
            [defaults synchronize];

        } else {

            // enable menu bar
            SetSystemUIMode(kUIModeNormal, 0);
            // switch to Dock.app
            [[NSWorkspace sharedWorkspace] launchAppWithBundleIdentifier:@"com.apple.dock"
                                                                 options:NSWorkspaceLaunchDefault
                                          additionalEventParamDescriptor:nil
                                                        launchIdentifier:nil];
            // switch back
            [[NSApplication sharedApplication] activateIgnoringOtherApps:TRUE];
        }
    } else {
        // NSLog(@"Not showing in Dock");
    }

    // If we are using the system browser we don't need all of the menus
    // TODO: make this use menu titles not indexes
    if ( [defaults boolForKey:@"useSystemBrowser"] ) {
        [[NSApp mainMenu] removeItemAtIndex:6]; // Window menu
        [[NSApp mainMenu] removeItemAtIndex:2]; // Edit menu
    }
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	// Register that we can open URLs
    NSAppleEventManager *em = [NSAppleEventManager sharedAppleEventManager];
    [em setEventHandler:self
            andSelector:@selector(getUrl:withReplyEvent:)
          forEventClass:kInternetEventClass
             andEventID:kAEGetURL];
}

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender{
    return NO;
}

// From here down are methods from NSApplicationDelegate, which probably do belong in another file.
// If/when this is done, I think you have to change the "File's Owner"'s delegate in IB
- (BOOL)application: (NSApplication * )theApplication openFile: (NSString * )filename{

    NSString *extension = [filename pathExtension];
    NSLog(@"Told to open %@ of type %@", filename, extension);

    // Handle the file based on extension
    if ( [extension isEqual:@"sage"] || [extension isEqual:@"py"] ) {
        // Run sage and python files in your terminal
        [appController sageTerminalRun:nil withArguments:[NSArray arrayWithObject:filename]];

    } else if ( [extension isEqual:@"sws"] ) {

        [[NSAlert alertWithMessageText:@"Worksheet upload unimplemented"
                         defaultButton:nil
                       alternateButton:nil
                           otherButton:nil
             informativeTextWithFormat:@"I don't know how to open sws files yet.  Please fix trac 8473 and get back to me."]
         runModal];

    } else if ( [extension isEqual:@"spkg"] ) {
        // Install the spkg
        [appController sageTerminalRun:@"i" withArguments:[NSArray arrayWithObject:filename]];

    } else if ( [extension isEqual:@"html"] || [extension isEqual:@"htm"] ) { // maybe others?

        NSError *outError = nil;
        id myDocument = [[NSDocumentController sharedDocumentController]
                         openUntitledDocumentAndDisplay:YES error:&outError];
        if ( myDocument == nil ) {
            [NSApp presentError:outError];
            NSLog(@"sageBrowser: Error creating document: %@", [outError localizedDescription]);
        } else {
            [[[myDocument webView] mainFrame]
             loadRequest:[NSURLRequest requestWithURL:
                          [NSURL URLWithString:
                           [NSString stringWithFormat:@"file://%@",
                            [filename stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]]]]];
        }

    } else if ( [[NSFileManager defaultManager] isExecutableFileAtPath:[NSString stringWithFormat:@"%@/sage", filename]] ) {
        // Use this as the sage folder
        // NSFileManager *fileManager = [NSFileManager defaultManager];
        [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%@/sage", filename]
                                                  forKey:@"SageBinary"];
        [appController setupPaths];

    } else {
        NSLog(@"I have no idea how I got a file of type %@.", extension);
        return NO;
    }
    return YES;
}

// http://stackoverflow.com/questions/49510/how-do-you-set-your-cocoa-application-as-the-default-web-browser
- (void)getUrl:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent{
    // Get the URL
    NSString *urlStr = [[event paramDescriptorForKeyword:keyDirectObject] stringValue];
    // Activate us
    [[NSApplication sharedApplication] activateIgnoringOtherApps:TRUE];

    // TODO: maybe sws links can be special too (once they work at all)
    if ( [[urlStr pathExtension] isEqual:@"spkg"] ) {
        // We can install spkg's from URLs
        [appController sageTerminalRun:@"i" withArguments:[NSArray arrayWithObject:urlStr]];
    } else {

        // Open the url in a new window
        NSError *outError = nil;
        id myDocument = [[NSDocumentController sharedDocumentController]
                         openUntitledDocumentAndDisplay:YES error:&outError];
        if ( myDocument == nil ) {
            [NSApp presentError:outError];
            NSLog(@"sageBrowser: Error creating document: %@", [outError localizedDescription]);
        } else {
            [[[myDocument webView] mainFrame]
             loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:urlStr]]];
        }

    }

    // Check if the server has started
    // TODO: This detection will only work if we are SAGE_BROWSER (i.e. we are in the dock)
    NSArray *components = [urlStr componentsSeparatedByString:@"/?startup_token="];
    if ( [components count] > 1 ) {
        urlStr = [components objectAtIndex:0];
        components = [urlStr componentsSeparatedByString:@"localhost:"];
        if ( [components count] > 1 ) {
            const int port = (int)[[components objectAtIndex:1] floatValue];
            [appController serverStartedWithPort:port];
        }
    }
}

@end
