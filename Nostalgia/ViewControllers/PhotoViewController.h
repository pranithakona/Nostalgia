//
//  PhotoViewController.h
//  Nostalgia
//
//  Created by Pranitha Reddy Kona on 7/27/21.
//

#import <UIKit/UIKit.h>
#import <GooglePlaces/GooglePlaces.h>

NS_ASSUME_NONNULL_BEGIN

@interface PhotoViewController : UIViewController

@property (strong, nonatomic) GMSPlacePhotoMetadata *photoMetaData;

@end

NS_ASSUME_NONNULL_END
