//
//  Trip.h
//  Nostalgia
//
//  Created by Pranitha Reddy Kona on 7/13/21.
//

#import <Parse/Parse.h>
#import "Destination.h"
@import GooglePlaces;

NS_ASSUME_NONNULL_BEGIN

@interface Trip : PFObject <PFSubclassing>

@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSString *tripDescription;
@property (strong, nonatomic) PFUser *owner;
@property (strong, nonatomic) NSArray * _Nullable users;
@property (strong, nonatomic) PFGeoPoint *region;
@property (strong, nonatomic) PFGeoPoint *startLocation;
@property (strong, nonatomic) PFGeoPoint *endLocation;
@property (strong, nonatomic) NSArray *destinations;
@property (strong, nonatomic) NSDate * _Nullable startTime;
@property (strong, nonatomic) NSDate * _Nullable endtime;

+ (void) postTrip: (Trip *)trip withCompletion: (void (^)(Trip * _Nullable trip, NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
