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
#import <Parse/Parse.h>

@interface CreateViewController () <GMSAutocompleteViewControllerDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, CreateCellDelegate, ShareViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UISegmentedControl *routeTypeControl;
@property (strong, nonatomic) IBOutlet UILongPressGestureRecognizer *dragGestureRecognizer;

@property (strong, nonatomic) NSMutableArray<Destination *> *arrayOfDestinations;
@property (strong, nonatomic) NSArray<PFUser *> *arrayOfSharedUsers;
@property (copy, nonatomic) NSString *encodedPolyline;
@property (strong, nonatomic) NSArray<NSNumber *> *bounds;

@end

@implementation CreateViewController
static const NSString *detailsSegue = @"editDetailsSegue";
static const NSString *mapSegue = @"mapSegue";
static const NSString *shareSegue = @"shareSegue";
static const NSString *cellName = @"CreateCell";
static const NSString *dictKey = @"API_Key";
static const NSString *tripsKey = @"trips";
static const NSString *routesKey = @"routes";
static const NSString *baseURL = @"https://maps.googleapis.com/maps/api/directions/json?origin=place_id:%@&destination=place_id:%@&waypoints=optimize:%@%@&key=%@";

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    
    UICollectionViewFlowLayout *layout = [self.collectionView collectionViewLayout];
    CGFloat itemWidth = self.collectionView.frame.size.width;
    layout.itemSize = CGSizeMake(itemWidth, 150);
    
    self.arrayOfDestinations = [NSMutableArray array];
    self.arrayOfSharedUsers = [NSArray array];
    
    //is editing an existing trip
    if (!self.isNewTrip){
        self.arrayOfDestinations = [NSMutableArray arrayWithArray: self.trip.destinations];
        self.startLocation = self.arrayOfDestinations[0];
        self.endLocation = [self.arrayOfDestinations lastObject];
        self.startTime = self.trip.startTime;
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

- (void)fetchDetails {
    [self performSegueWithIdentifier:detailsSegue sender:self.trip];
}

# pragma mark - Create Route

- (IBAction)fetchRoute:(id)sender {
    [self.activityIndicator startAnimating];
    BOOL isOptimized = self.routeTypeControl.selectedSegmentIndex == 0;
    
    //create api endpoint based on waypoints in trip
    NSString *path = [[NSBundle mainBundle] pathForResource: @"Keys" ofType: @"plist"];
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile: path];
    const NSString *key= [dict objectForKey:dictKey];
    
    NSString *destinationsString = @"";
    for (Destination *dest in self.arrayOfDestinations){
        destinationsString = [destinationsString stringByAppendingString: [NSString stringWithFormat:@"|place_id:%@", dest.placeID]];
    }
    
    //optimized or planned route
    NSString *optimizationString = isOptimized ? @"true" : @"false";
    NSString *urlString = [NSString stringWithFormat: baseURL, self.startLocation.placeID, self.endLocation.placeID, optimizationString, destinationsString, key];
    NSString *encodedString = [urlString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    NSURL* url = [NSURL URLWithString:encodedString];
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30.0];

     __block NSError *error1 = [[NSError alloc] init];
    __weak typeof(self) weakSelf = self;
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:nil delegateQueue:[NSOperationQueue mainQueue]];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if ([data length]>0 && error == nil) {
            NSDictionary *resultsDictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:&error1];
            NSMutableArray *orderedArrayOfDestinations;
            //optimize route
            orderedArrayOfDestinations = [weakSelf orderDestinationswithResults:resultsDictionary];
            
            //create new trip or update existing one
            if (weakSelf.isNewTrip){
                [weakSelf createTripWithDestinations:orderedArrayOfDestinations];
            } else {
                [weakSelf editTripWithDestinations:orderedArrayOfDestinations];
            }
        }
    }];
    [task resume];
}

- (NSMutableArray *)orderDestinationswithResults:(NSDictionary *)resultsDictionary {
    static const NSString *legsKey = @"legs";
    static const NSString *waypointKey = @"waypoint_order";
    static const NSString *boundsKey = @"bounds";
    static const NSString *polylineKey = @"overview_polyline";
    static const NSString *pointsKey = @"points";
    static const NSString *northeastKey = @"northeast";
    static const NSString *southwestKey = @"southwest";
    static const NSString *latKey = @"lat";
    static const NSString *lngKey = @"lng";
    static const NSString *distanceKey = @"distance";
    static const NSString *textKey = @"text";
    static const NSString *durationKey = @"duration";
    static const NSString *valueKey = @"value";
    
    if (!resultsDictionary || resultsDictionary.count == 0){
        return nil;
    }
    NSArray *legs = resultsDictionary[routesKey][0][legsKey];
    NSArray *waypoints = resultsDictionary[routesKey][0][waypointKey];
    NSDictionary *bounds = resultsDictionary[routesKey][0][boundsKey];
    self.encodedPolyline = resultsDictionary[routesKey][0][polylineKey][pointsKey];
    self.bounds = @[@([bounds[northeastKey][latKey] doubleValue]),@([bounds[northeastKey][lngKey]doubleValue]), @([bounds[southwestKey][latKey] doubleValue]),@([bounds[southwestKey][lngKey] doubleValue])];
    
    //reorder destinations array based on optimized order for route
    NSMutableArray *orderedArrayOfDestinations = [NSMutableArray array];
    [orderedArrayOfDestinations addObject:self.startLocation];
    if (self.routeTypeControl.selectedSegmentIndex == 0){
        for (int i = 0; i < waypoints.count; i++) {
            int waypointIndex = [waypoints[i] intValue];
            [orderedArrayOfDestinations addObject:self.arrayOfDestinations[waypointIndex]];
        }
    }
    [orderedArrayOfDestinations addObject:self.endLocation];
    
    //add distance/time to next destination and planned time of current destination
    NSDate *currentTime = self.startTime;
    for (int i = 0; i < orderedArrayOfDestinations.count - 1; i++) {
        Destination *dest = orderedArrayOfDestinations[i];
        dest.distanceToNextDestination = legs[i][distanceKey][textKey];
        dest.timeToNextDestination = [NSNumber numberWithLong:[legs[i][durationKey][valueKey] longValue]];
        
        dest.time = currentTime;
        currentTime = [currentTime dateByAddingSeconds:[dest.duration intValue]];
        currentTime = [currentTime dateByAddingSeconds:[dest.timeToNextDestination longValue]];
        [dest saveInBackground];
    }
    
    self.endLocation.time = currentTime;
    [self.endLocation saveInBackground];
    
    return orderedArrayOfDestinations;
}

- (void)createTripWithDestinations:(NSArray *)destinationsArray {
    Trip *newTrip = [Trip new];
    newTrip.name = self.name;
    newTrip.tripDescription = self.tripDescription;
    newTrip.coverPhoto = [self getPFFileFromImage:self.photo];
    newTrip.owner = [PFUser currentUser];
    newTrip.region = self.region.name;
    newTrip.regionID = self.region.placeID;
    newTrip.startLocation = self.startLocation;
    newTrip.endLocation = self.endLocation;
    newTrip.startTime = self.startTime;
    newTrip.destinations = destinationsArray;
    newTrip.encodedPolyline = self.encodedPolyline;
    newTrip.users = self.arrayOfSharedUsers;
    newTrip.bounds = self.bounds;
    newTrip.isOptimized = self.routeTypeControl.selectedSegmentIndex == 0;
    
    NSLog(@"array of users%@", newTrip.users);
    
    [Trip postTrip:newTrip withCompletion:^(Trip * _Nullable trip, NSError * _Nullable error) {
        if (!error){
            NSMutableArray *userTrips = [NSMutableArray arrayWithArray:[PFUser currentUser][tripsKey]];
            [userTrips addObject:trip];
            [PFUser currentUser][tripsKey] = userTrips;
            [[PFUser currentUser] saveInBackground];
            
            //give all shared users access to trip
            for (PFUser *user in trip.users) {
                NSLog(@"user %@", user);
                NSMutableArray *userTrips = [NSMutableArray arrayWithArray:user[tripsKey]];
                [userTrips addObject:trip];
                user[tripsKey] = userTrips;
                [user saveInBackground];
            }
            
            [self.activityIndicator stopAnimating];
            [self performSegueWithIdentifier:mapSegue sender:trip];
        }
    }];
}

- (void)editTripWithDestinations:(NSArray *)destinationsArray {
    self.trip.destinations = destinationsArray;
    self.trip.encodedPolyline = self.encodedPolyline;
    self.trip.bounds = self.bounds;
    
    //add new users to trip
    for (PFUser *user in self.arrayOfSharedUsers){
        if (![self.trip.users containsObject:user]){
            NSMutableArray *userTrips = [NSMutableArray arrayWithArray:user[tripsKey]];
            [userTrips addObject:self.trip];
            user[tripsKey] = userTrips;
            [user saveInBackground];
        }
    }
    self.trip.users = self.arrayOfSharedUsers;
    [self.trip saveInBackground];
    
    [self.activityIndicator stopAnimating];
    [self performSegueWithIdentifier:mapSegue sender:self.trip];
}

- (void)didAddUsers:(NSArray *)users {
    self.arrayOfSharedUsers = users;
}

- (PFFileObject *)getPFFileFromImage: (UIImage * _Nullable)image {
    if (!image) {
        return nil;
    }
    NSData *imageData = UIImagePNGRepresentation(image);
    if (!imageData) {
        return nil;
    }
    return [PFFileObject fileObjectWithName:@"image.png" data:imageData];
}

#pragma mark - Google Places

- (IBAction)addLocation:(id)sender {
    GMSAutocompleteViewController *acController = [[GMSAutocompleteViewController alloc] init];
    acController.delegate = self;

    GMSPlaceField fields = (GMSPlaceFieldName | GMSPlaceFieldPlaceID | GMSPlaceFieldCoordinate);
    acController.placeFields = fields;

    GMSAutocompleteFilter *filter = [[GMSAutocompleteFilter alloc] init];
    filter.type = kGMSPlacesAutocompleteTypeFilterNoFilter;
    CLLocationCoordinate2D northEast = CLLocationCoordinate2DMake(self.region.coordinate.latitude - 0.5, self.region.coordinate.longitude + 0.5);
    CLLocationCoordinate2D southWest = CLLocationCoordinate2DMake(self.region.coordinate.latitude + 0.5, self.region.coordinate.longitude - 0.5);
    filter.locationBias = GMSPlaceRectangularLocationOption(northEast, southWest);
    acController.autocompleteFilter = filter;

    [self presentViewController:acController animated:YES completion:nil];
}

- (void)viewController:(GMSAutocompleteViewController *)viewController
    didAutocompleteWithPlace:(GMSPlace *)place {
    [self dismissViewControllerAnimated:YES completion:nil];
    [self.activityIndicator startAnimating];
    
    //add new location to destinations array and save as a destination 
    [Destination postDestination:place withCompletion:^(Destination * _Nullable dest, NSError * _Nullable error) {
        if (!error){
            [self.arrayOfDestinations addObject:dest];
            [self.collectionView reloadData];
            [self.activityIndicator stopAnimating];
        }
    }];
}

- (void)viewController:(GMSAutocompleteViewController *)viewController
didFailAutocompleteWithError:(NSError *)error {
    [self dismissViewControllerAnimated:YES completion:nil];
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

#pragma mark - Collection View

- (IBAction)changeRouteType:(id)sender {
    [self.collectionView reloadData];
}

- (void)deleteCell:(Destination *)dest {
    [self.arrayOfDestinations removeObject:dest];
    [self.collectionView reloadData];
    [dest deleteInBackground];
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

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.arrayOfDestinations.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    CreateCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellName forIndexPath:indexPath];
    cell.delegate = self;
    
    Destination *dest = self.arrayOfDestinations[indexPath.item];
    [cell setCellWithDestination:dest];
    cell.topConnectorView.hidden = indexPath.item == 0;
    
    //switch between optimized and planned views
    if (self.routeTypeControl.selectedSegmentIndex == 0) {
        cell.optimizeView.hidden = true;
        cell.planView.hidden = false;
    } else {
        cell.optimizeView.hidden = false;
        cell.planView.hidden = true;
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
    [self.collectionView reloadData];
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:mapSegue]){
        MapViewController *mapViewController = [segue destinationViewController];
        mapViewController.trip = sender;
        mapViewController.isNewTrip = true;
        mapViewController.canEditTrip = true;
    } else if ([segue.identifier isEqualToString:shareSegue]) {
        ShareViewController *shareViewController = [segue destinationViewController];
        shareViewController.delegate = self;
        shareViewController.arrayOfSharedUsers = [self.arrayOfSharedUsers mutableCopy];
    } else if ([segue.identifier isEqualToString:detailsSegue]){
        NewTripViewController *newTripViewController = [segue destinationViewController];
        newTripViewController.isNewTrip = false;
        newTripViewController.trip = sender;
    }
}

@end
