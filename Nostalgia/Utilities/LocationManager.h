//
//  LocationManager.h
//  Nostalgia
//
//  Created by Pranitha Reddy Kona on 7/16/21.
//

#import <Foundation/Foundation.h>
@import CoreLocation;

NS_ASSUME_NONNULL_BEGIN

@interface LocationManager : NSObject

+ (CLLocationManager *)shared;

@end

NS_ASSUME_NONNULL_END
