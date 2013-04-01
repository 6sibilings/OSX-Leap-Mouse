//
//  AppDelegate.h
//  OSX LeapMouse DR
//
//  Created by Phil Plückthun on 3/27/13.
//  Copyright (c) 2013 Phil Plückthun. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "LeapObjectiveC.h"

@interface AppDelegate : NSObject <NSApplicationDelegate, LeapListener> {
    LeapController *controller;
    int handId;
    BOOL handIsSet;
}

@property (assign) IBOutlet NSWindow *window;

@end
