//
//  Trip.h
//  Nostalgia
//
//  Created by Pranitha Reddy Kona on 7/13/21.
//


#import "Destination.h"
#import <GooglePlaces/GooglePlaces.h>
@class PFUser;

NS_ASSUME_NONNULL_BEGIN

@interface Trip : PFObject <PFSubclassing>

@property (copy, nonatomic) NSString *name;
@property (copy, nonatomic) NSString *tripDescription;
@property (strong, nonatomic) PFUser *owner;
@property (strong, nonatomic) NSArray * _Nullable users;
@property (copy, nonatomic) NSString *region;
@property (copy, nonatomic) NSString *regionID;
@property (strong, nonatomic) Destination *startLocation;
@property (strong, nonatomic) Destination *endLocation;
@property (strong, nonatomic) NSArray *destinations;
@property (strong, nonatomic) NSArray *realTimeCoordinates;
@property (strong, nonatomic) NSArray *photos;
@property (strong, nonatomic) NSDate * _Nullable startTime;
@property (copy, nonatomic) NSString *encodedPolyline;
@property (strong, nonatomic) NSArray *bounds;
@property (assign, nonatomic) BOOL isOptimized;

typedef void(^tripCompletion)(Trip * _Nullable, NSError * _Nullable);

+ (void) postTrip:(Trip *)trip withCompletion:(tripCompletion)completion;

@end

NS_ASSUME_NONNULL_END
