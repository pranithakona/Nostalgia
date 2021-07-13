//
//  Trip.h
//  Nostalgia
//
//  Created by Pranitha Reddy Kona on 7/13/21.
//

#import <Parse/Parse.h>
@import GooglePlaces;

NS_ASSUME_NONNULL_BEGIN

@interface Trip : PFObject <PFSubclassing>

@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSString *description;
@property (strong, nonatomic) PFGeoPoint *region;
@property (strong, nonatomic) PFGeoPoint *startLocation;
@property (strong, nonatomic) PFGeoPoint *endLocation;
@property (strong, nonatomic) NSArray *locations;
@property (strong, nonatomic) NSDate *startTime;
@property (strong, nonatomic) NSDate *endtime;

+ (void) postDestination: (GMSPlace *)place withCompletion: (void (^)(Destination * _Nullable dest, NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
