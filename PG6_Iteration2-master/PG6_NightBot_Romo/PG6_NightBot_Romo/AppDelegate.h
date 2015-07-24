//
//  AppDelegate.h
//  PG6_NightBot_Romo
//
//  Created by Jeff Lanning on 7/12/15.
//  Copyright (c) 2015 Jeff Lanning. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <CoreMotion/CoreMotion.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate, CLLocationManagerDelegate>

@property (strong, nonatomic) UIWindow *window;

// Add location manager property to app delegate.
@property (strong, nonatomic) CLLocationManager *locationManager;

@property (strong, nonatomic) CMMotionManager *motionManager;

- (CMMotionManager*)sharedMotionManager;

@end

