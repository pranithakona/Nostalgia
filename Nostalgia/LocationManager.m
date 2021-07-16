//
//  LocationManager.m
//  Nostalgia
//
//  Created by Pranitha Reddy Kona on 7/16/21.
//

#import "LocationManager.h"

@implementation LocationManager

+ (CLLocationManager *)shared {
    static CLLocationManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[CLLocationManager alloc] init];
    });
    return sharedManager;
}

@end
