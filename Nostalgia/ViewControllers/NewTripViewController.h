//
//  NewTripViewController.h
//  Nostalgia
//
//  Created by Pranitha Reddy Kona on 7/12/21.
//

#import <UIKit/UIKit.h>
#import "Trip.h"

NS_ASSUME_NONNULL_BEGIN

@interface NewTripViewController : UIViewController

@property (strong, nonatomic) Trip *trip;
@property (assign, nonatomic) BOOL isNewTrip;

@end

NS_ASSUME_NONNULL_END
