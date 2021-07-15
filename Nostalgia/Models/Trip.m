//
//  Trip.m
//  Nostalgia
//
//  Created by Pranitha Reddy Kona on 7/13/21.
//

#import "Trip.h"

@implementation Trip 

@dynamic name;
@dynamic tripDescription;
@dynamic owner;
@dynamic users;
@dynamic region;
@dynamic regionID;
@dynamic startLocation;
@dynamic endLocation;
@dynamic destinations;
@dynamic startTime;
@dynamic endtime;
@dynamic encodedPolyline;

+ (nonnull NSString *)parseClassName {
    return @"Trip";
}

+ (void) postTrip: (Trip *)trip withCompletion:(void (^)(Trip * _Nullable trip, NSError * _Nullable error))completion {
    [trip saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
        if (succeeded){
            completion(trip, error);
        } else{
            completion(nil, error);
        }
    }];
}

@end
