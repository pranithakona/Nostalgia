//
//  MapViewController.h
//  Nostalgia
//
//  Created by Pranitha Reddy Kona on 7/10/21.
//

#import <UIKit/UIKit.h>
#import "Trip.h"

NS_ASSUME_NONNULL_BEGIN


@interface MapViewController : UIViewController

@property (strong, nonatomic) Trip *trip;
@property (nonatomic) BOOL isNewTrip;

@end

NS_ASSUME_NONNULL_END
