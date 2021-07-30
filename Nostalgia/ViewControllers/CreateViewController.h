//
//  CreateViewController.h
//  Nostalgia
//
//  Created by Pranitha Reddy Kona on 7/10/21.
//

#import <UIKit/UIKit.h>
#import "Destination.h"
#import "Trip.h"
#import <GooglePlaces/GooglePlaces.h>

NS_ASSUME_NONNULL_BEGIN

@interface CreateViewController : UIViewController

@property (copy, nonatomic) NSString *name;
@property (copy, nonatomic) NSString *tripDescription;
@property (strong, nonatomic) GMSPlace *region;
@property (strong, nonatomic) NSDate *startTime;
@property (strong, nonatomic) Destination *startLocation;
@property (strong, nonatomic) Destination *endLocation;
@property (strong, nonatomic) Trip *trip;
@property (strong, nonatomic) UIImage *photo;
@property (nonatomic) BOOL isNewTrip;

@end

NS_ASSUME_NONNULL_END
