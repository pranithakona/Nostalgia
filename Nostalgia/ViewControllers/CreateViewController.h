//
//  CreateViewController.h
//  Nostalgia
//
//  Created by Pranitha Reddy Kona on 7/10/21.
//

#import <UIKit/UIKit.h>
@import GooglePlaces;

NS_ASSUME_NONNULL_BEGIN

@interface CreateViewController : UIViewController

@property (strong, nonatomic) NSString *name;
//@property (strong, nonatomic) NSString *description;
@property (strong, nonatomic) GMSPlace *region;
@property (strong, nonatomic) NSDate *startTime;
@property (strong, nonatomic) GMSPlace *startLocation;

@end

NS_ASSUME_NONNULL_END
