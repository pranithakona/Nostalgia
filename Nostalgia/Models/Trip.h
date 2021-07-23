//
//  Trip.h
//  Nostalgia
//
//  Created by Pranitha Reddy Kona on 7/13/21.
//


#import "Destination.h"
@import GooglePlaces;
@class PFUser;

NS_ASSUME_NONNULL_BEGIN

@interface Trip : PFObject <PFSubclassing>

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *tripDescription;
@property (strong, nonatomic) PFUser *owner;
@property (strong, nonatomic) NSArray * _Nullable users;
@property (nonatomic, copy) NSString *region;
@property (nonatomic, copy) NSString *regionID;
@property (strong, nonatomic) Destination *startLocation;
@property (strong, nonatomic) Destination *endLocation;
@property (strong, nonatomic) NSArray *destinations;
@property (strong, nonatomic) NSArray *realTimeCoordinates;
@property (strong, nonatomic) NSDate * _Nullable startTime;
@property (nonatomic, copy) NSString *encodedPolyline;
@property (strong, nonatomic) NSArray *bounds;
@property (nonatomic, assign) BOOL isOptimized;

typedef void(^tripCompletion)(Trip * _Nullable, NSError * _Nullable);

+ (void) postTrip:(Trip *)trip withCompletion:(tripCompletion)completion;

@end

NS_ASSUME_NONNULL_END
