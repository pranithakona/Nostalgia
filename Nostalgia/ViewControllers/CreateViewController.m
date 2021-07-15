//
//  CreateViewController.m
//  Nostalgia
//
//  Created by Pranitha Reddy Kona on 7/10/21.
//

#import "CreateViewController.h"
#import "NewTripViewController.h"
#import "MapViewController.h"
#import "ShareViewController.h"
#import "Trip.h"
#import "CreateCell.h"
#import "DateTools.h"
#import "MaterialButtons.h"
@import Parse;

@interface CreateViewController () <GMSAutocompleteViewControllerDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, CreateCellDelegate, ShareViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UISegmentedControl *routeTypeControl;
@property (strong, nonatomic) IBOutlet UILongPressGestureRecognizer *dragGestureRecognizer;

@property (strong, nonatomic) NSMutableArray *arrayOfDestinations;
@property (strong, nonatomic) NSString *encodedPolyline;
@property (strong, nonatomic) NSArray *arrayOfSharedUsers;


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
    layout.itemSize = CGSizeMake(itemWidth, 150);
    
    self.arrayOfDestinations = [NSMutableArray array];
    self.arrayOfSharedUsers = [NSArray array];
    
    if (!self.isNewTrip){
        self.arrayOfDestinations = [NSMutableArray arrayWithArray: self.trip.destinations];
        [self.arrayOfDestinations removeObjectAtIndex:0];
        [self.arrayOfDestinations removeLastObject];
        self.arrayOfSharedUsers = self.trip.users;
        UIBarButtonItem *detailsButton = [[UIBarButtonItem alloc] initWithTitle:@"Details" style:UIBarButtonItemStylePlain target:self action:@selector(fetchDetails)];
        [self.navigationItem setLeftBarButtonItem:detailsButton];
        if (!self.trip.isOptimized) {
            [self.routeTypeControl setSelectedSegmentIndex:1];
        }
    }
}

- (IBAction)handleDrag:(id)sender {
    switch (self.dragGestureRecognizer.state) {
        case UIGestureRecognizerStateBegan:{;
            NSIndexPath *targetIndexPath = [self.collectionView indexPathForItemAtPoint:[self.dragGestureRecognizer locationInView:self.collectionView]];
            if (!targetIndexPath) {
                return;
            }
            [self.collectionView beginInteractiveMovementForItemAtIndexPath:targetIndexPath];
            break;
        }
        case UIGestureRecognizerStateChanged: {
            [self.collectionView updateInteractiveMovementTargetPosition:[self.dragGestureRecognizer locationInView:self.collectionView]];
            break;
        }
        case UIGestureRecognizerStateEnded: {
            [self.collectionView endInteractiveMovement];
            break;
        }
        default: {
            [self.collectionView cancelInteractiveMovement];;
            break;
        }
    }
}

- (IBAction)changeRouteType:(id)sender {
    [self.collectionView reloadData];
}

- (void)fetchDetails {
    [self performSegueWithIdentifier:@"editDetailsSegue" sender:self.trip];
}

- (IBAction)fetchRoute:(id)sender {
    [self.activityIndicator startAnimating];
    NSString *path = [[NSBundle mainBundle] pathForResource: @"Keys" ofType: @"plist"];
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile: path];
    NSString *key= [dict objectForKey: @"API_Key"];
    
    NSString *destinationsString = @"";
    for (Destination *dest in self.arrayOfDestinations){
        destinationsString = [destinationsString stringByAppendingString: [NSString stringWithFormat:@"|place_id:%@", dest.placeID]];
    }
    
    NSString *optimizationString = self.routeTypeControl.selectedSegmentIndex == 0 ? @"true" : @"false";
    
    NSString *urlString = [NSString stringWithFormat: @"https://maps.googleapis.com/maps/api/directions/json?origin=place_id:%@&destination=place_id:%@&waypoints=optimize:%@%@&key=%@",
       self.startLocation.placeID, self.endLocation.placeID, optimizationString, destinationsString, key];
    
    NSString *encodedString = [urlString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];

    NSURL* url = [NSURL URLWithString:encodedString];
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30.0];

     __block NSError *error1 = [[NSError alloc] init];

    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:nil delegateQueue:[NSOperationQueue mainQueue]];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if ([data length]>0 && error == nil) {
            NSDictionary *resultsDictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:&error1];
            NSArray *orderedArrayOfDestinations = [self orderDestinationswithResults:resultsDictionary];
            
            if (self.isNewTrip){
                [self createTripWithDestinations:orderedArrayOfDestinations];
            } else {
                [self editTripWithDestinations:orderedArrayOfDestinations];
            }

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
    
    for (int i = 0; i < waypoints.count + 1; i++){
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
    newTrip.region = self.region.name;
    newTrip.regionID = self.region.placeID;
    newTrip.startLocation = self.startLocation;
    newTrip.endLocation = self.endLocation;
    newTrip.startTime = self.startTime;
    newTrip.destinations = destinationsArray;
    newTrip.encodedPolyline = self.encodedPolyline;
    newTrip.users = self.arrayOfSharedUsers;
    newTrip.isOptimized = self.routeTypeControl.selectedSegmentIndex == 0;
    
    [Trip postTrip:newTrip withCompletion:^(Trip * _Nullable trip, NSError * _Nullable error) {
        if (!error){
            NSMutableArray *userTrips = [NSMutableArray arrayWithArray:[PFUser currentUser][@"trips"]];
            [userTrips addObject:trip];
            [PFUser currentUser][@"trips"] = userTrips;
            [[PFUser currentUser] saveInBackground];
            
            for (PFUser *user in trip.users){
                NSMutableArray *userTrips = [NSMutableArray arrayWithArray:user[@"trips"]];
                [userTrips addObject:trip];
                user[@"trips"] = userTrips;
                [user saveInBackground];
            }
            
            [self.activityIndicator stopAnimating];
            [self performSegueWithIdentifier:@"mapSegue" sender:trip];
        } else {
            NSLog(@"error: %@", error.localizedDescription);
        }
    }];
}

- (void) editTripWithDestinations: (NSArray *)destinationsArray {
    self.trip.destinations = destinationsArray;
    self.trip.encodedPolyline = self.encodedPolyline;
    
    for (PFUser *user in self.arrayOfSharedUsers){
        if (![self.trip.users containsObject:user]){
            NSMutableArray *userTrips = [NSMutableArray arrayWithArray:user[@"trips"]];
            [userTrips addObject:self.trip];
            user[@"trips"] = userTrips;
            [user saveInBackground];
        }
    }
    self.trip.users = self.arrayOfSharedUsers;
    
    [self.trip saveInBackground];
    [self.activityIndicator stopAnimating];
    [self performSegueWithIdentifier:@"mapSegue" sender:self.trip];
    
}

- (void)didAddUsers:(NSArray *)users {
    self.arrayOfSharedUsers = users;
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
    
    [self.activityIndicator startAnimating];
    [Destination postDestination:place withCompletion:^(Destination * _Nullable dest, NSError * _Nullable error) {
        if (!error){
            dest.duration = @3600;
            [dest saveInBackground];
            [self.arrayOfDestinations addObject:dest];
            [self.collectionView reloadData];
            [self.activityIndicator stopAnimating];
        } else {
            NSLog(@"error: %@", error.localizedDescription);
        }
    }];
        
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

- (void)deleteCell:(Destination *)dest {
    [self.arrayOfDestinations removeObject:dest];
    [self.collectionView reloadData];
    [dest deleteInBackground];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.arrayOfDestinations.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    CreateCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"CreateCell" forIndexPath:indexPath];
    cell.delegate = self;
    
    Destination *dest = self.arrayOfDestinations[indexPath.item];
    [cell setCellWithDestination:dest];
    
    if (self.routeTypeControl.selectedSegmentIndex == 0) {
        cell.durationLabel.hidden = false;
        cell.durationDatePicker.hidden = false;
        cell.startLabel.hidden = true;
        cell.startDatePicker.hidden = true;
        cell.endLabel.hidden = true;
        cell.endDatePicker.hidden = true;
        cell.orderLabel.hidden = true;
    } else {
        cell.durationLabel.hidden = true;
        cell.durationDatePicker.hidden = true;
        cell.startLabel.hidden = false;
        cell.startDatePicker.hidden = false;
        cell.endLabel.hidden = false;
        cell.endDatePicker.hidden = false;
        cell.orderLabel.hidden = false;
        cell.orderLabel.text = [NSString stringWithFormat:@"%ld",(long)indexPath.item];
    }
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat itemWidth = self.collectionView.frame.size.width;
    return CGSizeMake(itemWidth, 150);
}

- (BOOL)collectionView:(UICollectionView *)collectionView canMoveItemAtIndexPath:(NSIndexPath *)indexPath {
    return self.routeTypeControl.selectedSegmentIndex == 1;
}

- (void)collectionView:(UICollectionView *)collectionView moveItemAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
    Destination *dest = self.arrayOfDestinations[sourceIndexPath.item];
    [self.arrayOfDestinations removeObjectAtIndex:sourceIndexPath.item];
    [self.arrayOfDestinations insertObject:dest atIndex:destinationIndexPath.item];
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString: @"mapSegue"]){
        MapViewController *mapViewController = [segue destinationViewController];
        mapViewController.trip = sender;
        mapViewController.isNewTrip = true;
    } else if ([segue.identifier isEqualToString: @"shareSegue"]){
        ShareViewController *shareViewController = [segue destinationViewController];
        shareViewController.delegate = self;
        shareViewController.arrayOfSharedUsers = [self.arrayOfSharedUsers mutableCopy];
    } else if ([segue.identifier isEqualToString: @"editDetailsSegue"]){
        NewTripViewController *newTripViewController = [segue destinationViewController];
        newTripViewController.isNewTrip = false;
        newTripViewController.trip = sender;
    }
}


@end
