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
@property (strong, nonatomic) NSString *region;
@property (strong, nonatomic) NSString *regionID;
@property (strong, nonatomic) Destination *startLocation;
@property (strong, nonatomic) Destination *endLocation;
@property (strong, nonatomic) NSArray *destinations;
@property (strong, nonatomic) NSDate * _Nullable startTime;
@property (strong, nonatomic) NSDate * _Nullable endtime;
@property (strong, nonatomic) NSString *encodedPolyline;

+ (void) postTrip: (Trip *)trip withCompletion: (void (^)(Trip * _Nullable trip, NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
