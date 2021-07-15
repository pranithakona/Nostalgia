//
//  CreateViewController.h
//  Nostalgia
//
//  Created by Pranitha Reddy Kona on 7/10/21.
//

#import <UIKit/UIKit.h>
#import "Destination.h"
#import "Trip.h"
@import GooglePlaces;

NS_ASSUME_NONNULL_BEGIN

@interface CreateViewController : UIViewController

@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSString *tripDescription;
@property (strong, nonatomic) GMSPlace *region;
@property (strong, nonatomic) NSDate *startTime;
@property (strong, nonatomic) Destination *startLocation;
@property (strong, nonatomic) Destination *endLocation;
@property (strong, nonatomic) Trip *trip;
@property (nonatomic) BOOL isNewTrip;

@end

NS_ASSUME_NONNULL_END
