//
//  AppDelegate.m
//  OSX LeapMouse DR
//
//  Created by Phil Plückthun on 3/27/13.
//  Copyright (c) 2013 Phil Plückthun. All rights reserved.
//

#import "AppDelegate.h"

#include <ApplicationServices/ApplicationServices.h>

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    handIsSet = NO;
    controller = [[LeapController alloc] init];
    [controller addListener:self];
}

- (void)onInit:(NSNotification *)notification
{
    NSLog(@"Initialized");
}

- (void)onConnect:(NSNotification *)notification;
{
    NSLog(@"Connected");
    
    LeapController *aController = (LeapController *)[notification object];
    [aController enableGesture:LEAP_GESTURE_TYPE_SCREEN_TAP enable:YES];
}

- (void)onDisconnect:(NSNotification *)notification;
{
    NSLog(@"Disconnected");
}

- (void)onExit:(NSNotification *)notification;
{
    NSLog(@"Exited");
}

- (void)onFrame:(NSNotification *)notification;
{
    LeapController *aController = (LeapController *)[notification object];
    
    LeapFrame *frame = [aController frame:0];
    
    NSArray *screenList = [aController calibratedScreens];
    LeapScreen *mainScreen = screenList[0];
    NSArray *hands = [frame hands];
    
    if (hands.count > 0) {
        
        LeapHand *leftHand;
        if (handIsSet == YES) {
            BOOL isSet = NO;
            for (int i = 0; i < hands.count; i++) {
                LeapHand *tempHand = hands[i];
                if (tempHand.id == handId) {
                    leftHand = tempHand;
                    isSet = YES;
                }
            }
            if (isSet == NO) {
                leftHand = hands[0];
                if (hands.count > 1) {
                    for (int i = 1; i < hands.count; i++) {
                        if ([[hands[i] palmPosition] x] < [[leftHand palmPosition] x]) {
                            leftHand = hands[i];
                        }
                    }
                }
            }
        } else {
            leftHand = hands[0];
            if (hands.count > 1) {
                for (int i = 1; i < hands.count; i++) {
                    if ([[hands[i] palmPosition] x] < [[leftHand palmPosition] x]) {
                        leftHand = hands[i];
                    }
                }
            }
        }
        
        NSMutableArray *fingersUnordered = [[NSMutableArray alloc] init];
        NSMutableArray *fingersFromLeftToRight = [[NSMutableArray alloc] init];
        
        [fingersUnordered addObjectsFromArray:[leftHand fingers]];
        if (fingersUnordered.count > 0) {
            while (fingersUnordered.count > 0) {
                int selectedFinger = 0;
                LeapFinger *leftFinger = fingersUnordered[0];
                for (int i = 0; i < fingersUnordered.count; i++) {
                    if ([[fingersUnordered[i] tipPosition] x] <= [[leftFinger tipPosition] x]) {
                        leftFinger = fingersUnordered[i];
                        selectedFinger = i;
                    }
                }
                [fingersFromLeftToRight addObject:leftFinger];
                [fingersUnordered removeObjectAtIndex:selectedFinger];
            }
            
            LeapFinger *nearestFinger = fingersFromLeftToRight[0];
            
            for(int i = 1; i < fingersFromLeftToRight.count; i++) {
                LeapFinger *tempFinger = fingersFromLeftToRight[i];
                float tempDistance = [mainScreen distanceToPoint:tempFinger.tipPosition];
                float currentShortestDistance = [mainScreen distanceToPoint:nearestFinger.tipPosition];
                
                if (tempDistance < currentShortestDistance) {
                    nearestFinger = tempFinger;
                }
            }
            
            if ([nearestFinger isValid]) {
                handIsSet = YES;
                handId = leftHand.id;
                
                LeapVector *screenFactors = [mainScreen
                                             intersect:[nearestFinger tipPosition]
                                             direction:[nearestFinger direction]
                                             normalize:YES
                                             clampRatio:1.0f];
                
                int x = screenFactors.x * [mainScreen widthPixels];
                int y = [mainScreen heightPixels] - (screenFactors.y * [mainScreen heightPixels]);
                
                CGEventSourceRef source = CGEventSourceCreate(kCGEventSourceStateCombinedSessionState);
                CGEventRef mouse = CGEventCreateMouseEvent (NULL, kCGEventMouseMoved, CGPointMake(x, y), 0);
                CGEventPost(kCGHIDEventTap, mouse);
                CFRelease(mouse);
                
                NSArray *gestures = [frame gestures:nil];
                for (int g = 0; g < [gestures count]; g++) {
                    LeapGesture *gesture = [gestures objectAtIndex:g];
                    if (gesture.type == LEAP_GESTURE_TYPE_SCREEN_TAP) {
                        CGEventRef mouseDown = CGEventCreateMouseEvent(NULL, kCGEventLeftMouseDown, CGPointMake(x, y), 0);
                        CGEventPost(kCGHIDEventTap, mouseDown);
                        CFRelease(mouseDown);
                        
                        CGEventRef mouseUp = CGEventCreateMouseEvent(NULL, kCGEventLeftMouseUp, CGPointMake(x, y), 0);
                        CGEventPost(kCGHIDEventTap, mouseUp);
                        CFRelease(mouseUp);
                    }
                }
                
                CFRelease(source);
            }
        }
    }
}

@end
