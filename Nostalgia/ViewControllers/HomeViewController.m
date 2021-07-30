//
//  HomeViewController.m
//  Nostalgia
//
//  Created by Pranitha Reddy Kona on 7/10/21.
//

#import "HomeViewController.h"
#import "LoginViewController.h"
#import "MapViewController.h"
#import "NewTripViewController.h"
#import "SceneDelegate.h"
#import "Trip.h"
#import "DateTools.h"
#import "HomeCell.h"
#import "LocationManager.h"
#import "HomeCollectionHeader.h"
#import <Parse/Parse.h>

@interface HomeViewController () <UICollectionViewDelegate, UICollectionViewDataSource, CLLocationManagerDelegate, UICollectionViewDelegateFlowLayout>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

@property (strong, nonatomic) NSMutableArray<Trip *> *futureTrips;
@property (strong, nonatomic) NSMutableArray<Trip *> *pastTrips;
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) NSMutableArray<CLLocation *> *realTimeLocations;

@end

@implementation HomeViewController
static const NSString *headerName = @"HomeCollectionHeader";
static const NSString *cellName = @"HomeCell";
static const NSString *tripSegue = @"tripDetailsSegue";
static const NSString *newTripSegue = @"newTripSegue";
static const NSString *dictKey = @"API_Key";
static const NSString *baseURL = @"https://roads.googleapis.com/v1/snapToRoads?path=%@&interpolate=true&key=%@";

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.navigationController.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
    self.navigationController.navigationBar.shadowImage = [UIImage new];
    self.navigationController.navigationBar.translucent = YES;
    self.navigationController.view.backgroundColor = [UIColor clearColor];
    
    self.locationManager = [LocationManager shared];
    self.locationManager.delegate = self;
    self.realTimeLocations = [NSMutableArray array];
    
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    [self.collectionView registerNib:[UINib nibWithNibName:headerName bundle:nil] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:headerName];
    [self.collectionView registerNib:[UINib nibWithNibName:cellName bundle:nil] forCellWithReuseIdentifier:cellName];
    self.collectionView.collectionViewLayout = [self generateLayout];
    
    self.futureTrips = [NSMutableArray array];
    self.pastTrips = [NSMutableArray array];
    
    //sort user trips based on date
    [self.activityIndicator startAnimating];
    NSDate *now = [NSDate now];
    for (Trip *trip in [PFUser currentUser][@"trips"]){
        [trip fetchIfNeeded];
        if ([trip.startTime isEarlierThanOrEqualTo:now]){
            [self.pastTrips addObject:trip];
        } else {
            [self.futureTrips addObject:trip];
        }
    }
    [self.activityIndicator stopAnimating];
    
    //schedule route tracking for each future trip
    for (Trip *trip in self.futureTrips) {
        NSTimeInterval timeInterval = trip.startTime.timeIntervalSince1970 - [NSDate now].timeIntervalSince1970;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timeInterval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (CLLocationManager.locationServicesEnabled){
                [self startLocationUpdatesForTrip:trip];
            }
        });
    }
    [self.locationManager requestWhenInUseAuthorization];
}

#pragma mark - Collection View

- (UICollectionViewLayout *)generateLayout {    
    UICollectionViewLayout *layout = [[UICollectionViewCompositionalLayout alloc] initWithSectionProvider:^NSCollectionLayoutSection *_Nullable(NSInteger section, id<NSCollectionLayoutEnvironment> sectionProvider) {
        //item
        NSCollectionLayoutSize *itemSize = [NSCollectionLayoutSize sizeWithWidthDimension:[NSCollectionLayoutDimension fractionalWidthDimension:1] heightDimension:[NSCollectionLayoutDimension fractionalHeightDimension:1]];
        NSCollectionLayoutItem *item = [NSCollectionLayoutItem itemWithLayoutSize:itemSize];
        item.contentInsets = NSDirectionalEdgeInsetsMake(5, 5, 5, 5);
        
        //group
        NSCollectionLayoutSize *groupSize = [NSCollectionLayoutSize sizeWithWidthDimension:[NSCollectionLayoutDimension fractionalWidthDimension:0.5] heightDimension:[NSCollectionLayoutDimension fractionalHeightDimension:0.4]];
        NSCollectionLayoutGroup *group = [NSCollectionLayoutGroup horizontalGroupWithLayoutSize:groupSize subitem:item count:1];
        group.contentInsets = NSDirectionalEdgeInsetsMake(5, 5, 5, 5);
        
        //section
        NSCollectionLayoutSection *sectionLayout = [NSCollectionLayoutSection sectionWithGroup:group];
        NSCollectionLayoutSize *headerSize = [NSCollectionLayoutSize sizeWithWidthDimension:[NSCollectionLayoutDimension fractionalWidthDimension:1] heightDimension:[NSCollectionLayoutDimension estimatedDimension:44]];
        NSCollectionLayoutBoundarySupplementaryItem *sectionHeader = [NSCollectionLayoutBoundarySupplementaryItem boundarySupplementaryItemWithLayoutSize:headerSize elementKind:UICollectionElementKindSectionHeader alignment:NSRectAlignmentTop];
        sectionLayout.boundarySupplementaryItems = @[sectionHeader];
        sectionLayout.orthogonalScrollingBehavior = UICollectionLayoutSectionOrthogonalScrollingBehaviorContinuous;
        
        return sectionLayout;
    }];
    return layout;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 2;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    HomeCollectionHeader *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:headerName forIndexPath:indexPath];
    headerView.nameLabel.text = indexPath.section == 0 ? @"Upcoming" : @"Past";
    return headerView;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *data = indexPath.section == 0 ? self.futureTrips : self.pastTrips;
    Trip *trip = data[indexPath.item];
    [self performSegueWithIdentifier:tripSegue sender:trip];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return section == 0 ? self.futureTrips.count : self.pastTrips.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *data = indexPath.section == 0 ? self.futureTrips : self.pastTrips;
    HomeCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellName forIndexPath:indexPath];
    
    Trip *trip = data[indexPath.item];
    cell.nameLabel.text = trip.name;
    cell.descriptionLabel.text = trip.tripDescription;
    cell.dateLabel.text = [trip.startTime formattedDateWithStyle:NSDateFormatterMediumStyle];
    
    [cell setNeedsLayout];
    [cell layoutIfNeeded];
    
    return cell;
}

#pragma mark - Route Tracking

- (void)didCreateTrip:(Trip *)trip {
    //sets timer for new trips
    [self.futureTrips addObject:trip];
    [self.collectionView reloadData];
    NSTimeInterval timeInterval = trip.startTime.timeIntervalSince1970 - [NSDate now].timeIntervalSince1970;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timeInterval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (CLLocationManager.locationServicesEnabled){
            [self startLocationUpdatesForTrip:trip];
        }
    });
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    for (CLLocation *location in locations) {
        if (location.horizontalAccuracy < 20 && fabs([location.timestamp timeIntervalSinceNow]) < 10) {
            [self.realTimeLocations addObject:location];
        }
    }
}

- (void)startLocationUpdatesForTrip:(Trip *)trip {
    self.locationManager.activityType = CLActivityTypeAutomotiveNavigation;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    self.locationManager.distanceFilter = 100;
    self.locationManager.allowsBackgroundLocationUpdates = true;
    [self.locationManager startUpdatingLocation];
    [self.locationManager startMonitoringSignificantLocationChanges];
    [SceneDelegate clearCurrentTripSongs];
    [SceneDelegate setIsCurrentlyRouting:true];
    
    //commented out for testing purposes
    NSTimeInterval timeInterval = 60; //trip.endLocation.time.timeIntervalSince1970 - trip.startTime.timeIntervalSince1970;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timeInterval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self saveRouteWithTrip:trip];
    });
}

- (void)saveRouteWithTrip:(Trip *)trip {
    NSMutableArray *tripLocations = [NSMutableArray array];
    for (CLLocation *location in self.realTimeLocations){
        [tripLocations addObject:@[@(location.coordinate.latitude), @(location.coordinate.longitude), location.timestamp]];
    }
    [self.locationManager stopUpdatingLocation];
    [self.locationManager stopMonitoringSignificantLocationChanges];
    [SceneDelegate setIsCurrentlyRouting:false];
    
    [self snapToRoadsWithCoordinates:tripLocations forTrip:trip];
}

- (void)snapToRoadsWithCoordinates:(NSArray *)coordinates forTrip:(Trip *)trip {
    //calls Google Roads API to snap coordinates to exact roads traveled
    NSString *path = [[NSBundle mainBundle] pathForResource: @"Keys" ofType: @"plist"];
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile: path];
    NSString *key= [dict objectForKey:dictKey];
    
    NSString *coords = @"";
    for (NSArray *coordinate in coordinates) {
        coords = [coords stringByAppendingString:[NSString stringWithFormat:@"|%f,%f",[coordinate[0] doubleValue],[coordinate[1] doubleValue]]];
    }
    coords = [coords substringFromIndex:1];
    
    NSString *urlString = [NSString stringWithFormat: baseURL,coords,key];
    NSString *encodedString = [urlString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    NSURL* url = [NSURL URLWithString:encodedString];
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30.0];

     __block NSError *error1 = [[NSError alloc] init];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:nil delegateQueue:[NSOperationQueue mainQueue]];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if ([data length]>0 && error == nil) {
            NSDictionary *resultsDictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:&error1];
            NSMutableArray *tripLocations = [NSMutableArray array];
            
            //save coordinates, placeID, and time for each point on trip
            NSArray *points = resultsDictionary[@"snappedPoints"];
            for (NSDictionary *point in points){
                NSDictionary *location = point[@"location"];
                NSMutableArray *coordinate = [@[@([location[@"latitude"] doubleValue]),@([location[@"longitude"] doubleValue]), point[@"placeId"]] mutableCopy];
                if (point[@"originalIndex"]){
                    [coordinate addObject:coordinates[[point[@"originalIndex"] intValue]][2]];
                }
                [tripLocations addObject:coordinate];
            }
            
            trip.realTimeCoordinates = tripLocations;
            trip.songs = [NSArray arrayWithArray:[SceneDelegate getCurrentTripSongs]];
            [trip saveInBackground];
        }
    }];
    [task resume];
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:tripSegue]){
        MapViewController *mapViewController = [segue destinationViewController];
        mapViewController.trip = sender;
        mapViewController.isNewTrip = false;
        mapViewController.canEditTrip = true;
    } else if ([segue.identifier isEqualToString:newTripSegue]){
        NewTripViewController *newTripViewController = [segue destinationViewController];
        newTripViewController.isNewTrip = true;
    }
}

@end
