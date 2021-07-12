//
//  Destination.m
//  Nostalgia
//
//  Created by Pranitha Reddy Kona on 7/11/21.
//

#import "Destination.h"

@implementation Destination 

@dynamic objectID;
@dynamic name;
@dynamic placeID;
@dynamic coordinates;
@dynamic time;
@dynamic order;
@dynamic isFixed;

+ (nonnull NSString *)parseClassName {
    return @"Destination";
}

+ (Destination *) postDestination: (GMSPlace *)place withCompletion: (PFBooleanResultBlock _Nullable)completion {
    Destination *newDest = [Destination new];
    newDest.name = place.name;
    newDest.placeID = place.placeID;
    newDest.coordinates = [PFGeoPoint geoPointWithLatitude:place.coordinate.latitude longitude:place.coordinate.longitude];
    newDest.time = nil;
    newDest.isFixed = false;
    newDest.order = 0;
    
    [newDest saveInBackgroundWithBlock:completion];
    
    return newDest;
}

@end
