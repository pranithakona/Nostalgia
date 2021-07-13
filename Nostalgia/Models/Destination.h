//
//  Destination.h
//  Nostalgia
//
//  Created by Pranitha Reddy Kona on 7/11/21.
//

#import <Parse/Parse.h>
@import GooglePlaces;

NS_ASSUME_NONNULL_BEGIN

@interface Destination : PFObject <PFSubclassing>

@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSString *placeID;
@property (strong, nonatomic) PFGeoPoint *coordinates;
@property (strong, nonatomic) NSDate * time;
@property (strong, nonatomic) NSNumber * timeToNextDestination;
@property (strong, nonatomic) NSNumber * distanceToNextDestination;
@property (strong, nonatomic) NSNumber * duration;
@property (nonatomic) BOOL isFixed;

+ (void) postDestination: (GMSPlace *)place withCompletion: (void (^)(Destination * _Nullable dest, NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
