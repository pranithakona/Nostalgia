//
//  ExploreFilterHeader.m
//  Nostalgia
//
//  Created by Pranitha Reddy Kona on 7/26/21.
//

#import "ExploreFilterHeader.h"

@implementation ExploreFilterHeader

- (IBAction)filterByFood:(id)sender {
    [self.delegate filterByType:@"food"];
}

- (IBAction)filterByShop:(id)sender {
    [self.delegate filterByType:@"shop"];
}

- (IBAction)filterByFun:(id)sender {
    [self.delegate filterByType:@"fun"];
}

- (IBAction)filterByAttractions:(id)sender {
    [self.delegate filterByType:@"sightseeing"];
}


@end
