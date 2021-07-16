//
//  CreateViewController+Tests.h
//  Nostalgia
//
//  Created by Pranitha Reddy Kona on 7/16/21.
//

#ifndef CreateViewController_Tests_h
#define CreateViewController_Tests_h

@interface CreateViewController (Tests)

@property (strong, nonatomic) NSMutableArray *arrayOfDestinations;
@property (weak, nonatomic) IBOutlet UISegmentedControl *routeTypeControl;
@property (strong, nonatomic) Destination *startLocation;
@property (strong, nonatomic) Destination *endLocation;
@property (strong, nonatomic) NSDate *startTime;

- (NSMutableArray *)orderDestinationswithResults:(NSDictionary *)resultsDictionary;

@end

#endif /* CreateViewController_Tests_h */
