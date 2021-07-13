//
//  Destination.m
//  Nostalgia
//
//  Created by Pranitha Reddy Kona on 7/11/21.
//

#import "Destination.h"

@implementation Destination 

@dynamic name;
@dynamic placeID;
@dynamic coordinates;
@dynamic time;
@dynamic timeToNextDestination;
@dynamic distanceToNextDestination;
@dynamic duration;
@dynamic isFixed;

+ (nonnull NSString *)parseClassName {
    return @"Destination";
}

+ (void) postDestination: (GMSPlace *)place withCompletion:(void (^)(Destination * _Nullable dest, NSError * _Nullable error))completion {
    Destination *newDest = [Destination new];
    newDest.name = place.name;
    newDest.placeID = place.placeID;
    newDest.coordinates = [PFGeoPoint geoPointWithLatitude:place.coordinate.latitude longitude:place.coordinate.longitude];
    newDest.time = nil;
    newDest.isFixed = false;
    
    [newDest saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
        if (succeeded){
            completion(newDest, error);
        } else{
            completion(nil, error);
        }
    }];
}

@end
