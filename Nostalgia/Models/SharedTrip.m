//
//  SharedTrip.m
//  Nostalgia
//
//  Created by Pranitha Reddy Kona on 8/11/21.
//

#import "SharedTrip.h"

@implementation SharedTrip

@dynamic trip;
@dynamic user;

+ (nonnull NSString *)parseClassName {
    return @"SharedTrip";
}

+ (void)postSharedTrip:(Trip *)trip withUser:(PFUser *)user{
    if (!trip || !user) {
        return;
    }
    SharedTrip *newSharedTrip = [SharedTrip new];
    newSharedTrip.trip = trip;
    newSharedTrip.user = user;
    
    [newSharedTrip saveInBackground];
}


@end
