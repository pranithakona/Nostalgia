//
//  CreateViewController.m
//  Nostalgia
//
//  Created by Pranitha Reddy Kona on 7/10/21.
//

#import "CreateViewController.h"
#import "Trip.h"
#import "CreateCell.h"
#import "DateTools.h"
@import Parse;

@interface CreateViewController () <GMSAutocompleteViewControllerDelegate, UICollectionViewDelegate, UICollectionViewDataSource>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

@property (strong, nonatomic) NSMutableArray *arrayOfDestinations;
@property (strong, nonatomic) NSMutableDictionary *dictOfDestinations;


@end

@implementation CreateViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    
    UICollectionViewFlowLayout *layout = [self.collectionView collectionViewLayout];
    layout.minimumLineSpacing = 5;
    layout.minimumInteritemSpacing = 5;
    CGFloat itemWidth = self.collectionView.frame.size.width;
    layout.itemSize = CGSizeMake(itemWidth, 100);
    
    self.arrayOfDestinations = [NSMutableArray array];
    self.dictOfDestinations = [NSMutableDictionary dictionary];
    
}

- (IBAction)nextButton:(id)sender {
    [self fetchOptimizedRoute];
}

-(void)fetchOptimizedRoute {
    
    NSArray *startCoordinates = @[[NSNumber numberWithDouble:self.startLocation.coordinates.longitude],[NSNumber numberWithDouble:self.startLocation.coordinates.latitude]];
    NSArray *userArray = @[@{@"start_location":startCoordinates, @"end_location": startCoordinates}];
    
    NSMutableArray *locationsArray = [NSMutableArray array];
    for (Destination *dest in self.arrayOfDestinations){
        NSArray *coordinates = @[[NSNumber numberWithDouble:dest.coordinates.longitude],[NSNumber numberWithDouble:dest.coordinates.latitude]];
        NSDictionary *locationDict = @{ @"location" : coordinates, @"duration" : @3600, @"id" : dest.objectId};
        [locationsArray addObject:locationDict];
    }

    NSDictionary *bodyDictionary = @{@"mode" : @"drive", @"agents": userArray, @"jobs": locationsArray};
    
    if ([NSJSONSerialization isValidJSONObject:bodyDictionary]) {
        NSLog(@"hello");
        NSError* error;
        NSData* jsonData = [NSJSONSerialization dataWithJSONObject:bodyDictionary options:NSJSONWritingPrettyPrinted error: &error];
        NSURL* url = [NSURL URLWithString:@"https://api.geoapify.com/v1/routeplanner?apiKey=e4a9731275b64f91b0f45802e73d284e"];
        NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30.0];
        [request setHTTPMethod:@"POST"];
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [request setHTTPBody:jsonData];
         __block NSError *error1 = [[NSError alloc] init];

        NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:nil delegateQueue:[NSOperationQueue mainQueue]];
        NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            if ([data length]>0 && error == nil) {
                NSDictionary *resultsDictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:&error1];
                NSArray *orderedArrayOfDestinations = [self orderDestinationswithResults:resultsDictionary];
                
                

            } else if ([data length]==0 && error ==nil) {
                NSLog(@" download data is null");
            } else if( error!=nil) {
                NSLog(@" error is %@",error);
            }
        }];
        [task resume];
    }
}

- (NSArray *) orderDestinationswithResults: (NSDictionary *) resultsDictionary {
    NSArray *legs = resultsDictionary[@"features"][0][@"properties"][@"legs"];
    NSArray *waypoints = resultsDictionary[@"features"][0][@"properties"][@"waypoints"];
    
    NSMutableArray *orderedArrayOfDestinations = [NSMutableArray arrayWithArray:self.arrayOfDestinations];
    [orderedArrayOfDestinations insertObject:self.startLocation atIndex:0];
    [orderedArrayOfDestinations addObject:self.endLocation];
    
    NSDate *currentTime = self.startTime;
    
    for (int i = 0; i < self.arrayOfDestinations.count+1; i++){
        Destination *dest;
        if (i == 0){
            dest = self.startLocation;
        } else {
            int waypointIndex = [legs[i][@"from_waypoint_index"] intValue];
            NSString *destId = waypoints[waypointIndex][@"actions"][0][@"job_id"];
            dest = [self.dictOfDestinations objectForKey:destId];
        }
        dest.distanceToNextDestination = [NSNumber numberWithInt:[legs[i][@"distance"] intValue]];
        dest.timeToNextDestination = [NSNumber numberWithInt:[legs[i][@"time"] intValue]];
        
        dest.time = currentTime;
        currentTime = [currentTime dateByAddingSeconds:[dest.duration intValue]];
        currentTime = [currentTime dateByAddingSeconds:[dest.timeToNextDestination intValue]];
        [dest saveInBackground];
        [orderedArrayOfDestinations setObject:dest atIndexedSubscript:i];
    }
    
    self.endLocation.time = currentTime;
    [self.endLocation saveInBackground];
    
    NSLog(@"%@", orderedArrayOfDestinations);
    return orderedArrayOfDestinations;
}

- (void) createTripWithDestinations: (NSArray *)destinationsArray {
    Trip *newTrip = [Trip new];
    newTrip.name = self.name;
    newTrip.tripDescription = self.tripDescription;
    newTrip.owner = [PFUser currentUser];
    newTrip.region = [PFGeoPoint geoPointWithLatitude:self.region.coordinate.latitude longitude:self.region.coordinate.longitude];
    newTrip.startLocation = [PFGeoPoint geoPointWithLatitude:self.startLocation.coordinates.latitude longitude:self.startLocation.coordinates.longitude];
    newTrip.endLocation = [PFGeoPoint geoPointWithLatitude:self.endLocation.coordinates.latitude longitude:self.endLocation.coordinates.longitude];;
    newTrip.startTime = self.startTime;
    newTrip.destinations = destinationsArray;
    
    [Trip postTrip:newTrip withCompletion:^(Trip * _Nullable trip, NSError * _Nullable error) {
        if (!error){

        } else {
            NSLog(@"error: %@", error.localizedDescription);
        }
    }];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.arrayOfDestinations.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    CreateCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"CreateCell" forIndexPath:indexPath];
    
    Destination *dest = self.arrayOfDestinations[indexPath.item];
    [cell setCellWithDestination:dest];
    
    return cell;
}

- (IBAction)addLocation:(id)sender {
    GMSAutocompleteViewController *acController = [[GMSAutocompleteViewController alloc] init];
    acController.delegate = self;

    GMSPlaceField fields = (GMSPlaceFieldName | GMSPlaceFieldPlaceID | GMSPlaceFieldCoordinate);
    acController.placeFields = fields;

    GMSAutocompleteFilter *filter = [[GMSAutocompleteFilter alloc] init];
    filter.type = kGMSPlacesAutocompleteTypeFilterNoFilter;
    //filter.locationBias = self.region;
    acController.autocompleteFilter = filter;

    [self presentViewController:acController animated:YES completion:nil];
}

- (void)viewController:(GMSAutocompleteViewController *)viewController
    didAutocompleteWithPlace:(GMSPlace *)place {
    [self dismissViewControllerAnimated:YES completion:nil];
    
    [Destination postDestination:place withCompletion:^(Destination * _Nullable dest, NSError * _Nullable error) {
        if (!error){
            dest.duration = @3600;
            [self.arrayOfDestinations addObject:dest];
            [self.dictOfDestinations setObject:dest forKey:dest.objectId];
            [self.collectionView reloadData];
        } else {
            NSLog(@"error: %@", error.localizedDescription);
        }
    }];
        
    
    NSLog(@"Place name %@", place.name);
    NSLog(@"Place ID %@", place.placeID);
    NSLog(@"Place attributions %@", place.attributions.string);
}

- (void)viewController:(GMSAutocompleteViewController *)viewController
didFailAutocompleteWithError:(NSError *)error {
    [self dismissViewControllerAnimated:YES completion:nil];
    // TODO: handle the error.
    NSLog(@"Error: %@", [error description]);
}

- (void)wasCancelled:(GMSAutocompleteViewController *)viewController {
[self dismissViewControllerAnimated:YES completion:nil];
}

- (void)didRequestAutocompletePredictions:(GMSAutocompleteViewController *)viewController {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

- (void)didUpdateAutocompletePredictions:(GMSAutocompleteViewController *)viewController {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
