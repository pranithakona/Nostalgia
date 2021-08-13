//
//  SharedTrip.h
//  Nostalgia
//
//  Created by Pranitha Reddy Kona on 8/11/21.
//

#import <Parse/Parse.h>
#import "Trip.h"
@class PFUser;

NS_ASSUME_NONNULL_BEGIN

@interface SharedTrip : PFObject <PFSubclassing>

@property (strong, nonatomic) Trip *trip;
@property (strong, nonatomic) PFUser *user;

+ (void)postSharedTrip:(Trip *)trip withUser:(PFUser *)user;

@end

NS_ASSUME_NONNULL_END
