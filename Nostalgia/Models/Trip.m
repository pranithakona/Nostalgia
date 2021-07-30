//
//  Trip.m
//  Nostalgia
//
//  Created by Pranitha Reddy Kona on 7/13/21.
//

#import "Trip.h"
#import "CreateViewController.h"
#import <Parse/Parse.h>

@implementation Trip 

@dynamic name;
@dynamic tripDescription;
@dynamic owner;
@dynamic coverPhoto;
@dynamic users;
@dynamic region;
@dynamic regionID;
@dynamic startLocation;
@dynamic endLocation;
@dynamic destinations;
@dynamic realTimeCoordinates;
@dynamic startTime;
@dynamic encodedPolyline;
@dynamic bounds;
@dynamic isOptimized;
@dynamic photos;
@dynamic songs;

+ (nonnull NSString *)parseClassName {
    return @"Trip";
}

+ (void)postTrip:(Trip *)trip withCompletion:(tripCompletion)completion {
    if (!trip) {
        if (!completion){
            completion (nil, nil);
        }
        return;
    }
    [trip saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
        if (succeeded){
            completion(trip, error);
        } else{
            completion(nil, error);
        }
    }];
}


@end
