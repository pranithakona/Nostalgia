//
//  CreateViewController.m
//  Nostalgia
//
//  Created by Pranitha Reddy Kona on 7/10/21.
//

#import "CreateViewController.h"
#import "MapViewController.h"
#import "Trip.h"
#import "CreateCell.h"
#import "DateTools.h"
@import Parse;

@interface CreateViewController () <GMSAutocompleteViewControllerDelegate, UICollectionViewDelegate, UICollectionViewDataSource>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

@property (strong, nonatomic) NSMutableArray *arrayOfDestinations;
@property (strong, nonatomic) NSMutableDictionary *dictOfDestinations;
@property (strong, nonatomic) NSString *encodedPolyline;


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

- (void)fetchOptimizedRoute {
    [self.activityIndicator startAnimating];
    NSString *path = [[NSBundle mainBundle] pathForResource: @"Keys" ofType: @"plist"];
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile: path];
    NSString *key= [dict objectForKey: @"API_Key"];
    
    NSString *destinationsString = @"";
    for (Destination *dest in self.arrayOfDestinations){
        destinationsString = [destinationsString stringByAppendingString: [NSString stringWithFormat:@"|place_id:%@", dest.placeID]];
    }
    
    NSString *urlString = [NSString stringWithFormat: @"https://maps.googleapis.com/maps/api/directions/json?origin=place_id:%@&destination=place_id:%@&waypoints=optimize:true%@&key=%@",
       self.startLocation.placeID, self.startLocation.placeID, destinationsString, key];
    
    NSString *encodedString = [urlString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    NSLog(@"%@",  urlString);
    NSLog(@"%@", destinationsString);

    NSURL* url = [NSURL URLWithString:encodedString];
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30.0];

     __block NSError *error1 = [[NSError alloc] init];

    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:nil delegateQueue:[NSOperationQueue mainQueue]];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if ([data length]>0 && error == nil) {
            NSDictionary *resultsDictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:&error1];
            NSArray *orderedArrayOfDestinations = [self orderDestinationswithResults:resultsDictionary];
            [self createTripWithDestinations:orderedArrayOfDestinations];

        } else if ([data length]==0 && error ==nil) {
            NSLog(@" download data is null");
        } else if( error!=nil) {
            NSLog(@" error is %@",error);
        }
    }];
    [task resume];
    
}

- (NSArray *) orderDestinationswithResults: (NSDictionary *) resultsDictionary {
    NSArray *legs = resultsDictionary[@"routes"][0][@"legs"];
    NSArray *waypoints = resultsDictionary[@"routes"][0][@"waypoint_order"];
    self.encodedPolyline = resultsDictionary[@"routes"][0][@"overview_polyline"][@"points"];
    
    NSMutableArray *orderedArrayOfDestinations = [NSMutableArray arrayWithArray:self.arrayOfDestinations];
    [orderedArrayOfDestinations insertObject:self.startLocation atIndex:0];
    [orderedArrayOfDestinations addObject:self.endLocation];
    
    NSDate *currentTime = self.startTime;
    
    for (int i = 0; i < waypoints.count; i++){
        Destination *dest;
        if (i == 0){
            dest = self.startLocation;
        } else {
            int waypointIndex = [waypoints[i-1] intValue];
            dest = self.arrayOfDestinations[waypointIndex];
        }
        dest.distanceToNextDestination = legs[i][@"distance"][@"text"];
        dest.timeToNextDestination = [NSNumber numberWithLong:[legs[i][@"duration"][@"value"] longValue]];
        
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
    newTrip.startLocation = self.startLocation;
    newTrip.endLocation = self.endLocation;
    newTrip.startTime = self.startTime;
    newTrip.destinations = destinationsArray;
    newTrip.encodedPolyline = self.encodedPolyline;
    
    [Trip postTrip:newTrip withCompletion:^(Trip * _Nullable trip, NSError * _Nullable error) {
        if (!error){
            [self.activityIndicator stopAnimating];
            [self performSegueWithIdentifier:@"mapSegue" sender:trip];
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
            [dest saveInBackground];
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

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqual: @"mapSegue"]){
        MapViewController *mapViewController = [segue destinationViewController];
        mapViewController.trip = sender;
    }
}


@end
