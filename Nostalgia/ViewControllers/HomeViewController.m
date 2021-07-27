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
@import Parse;

@interface HomeViewController () <UICollectionViewDelegate, UICollectionViewDataSource, CLLocationManagerDelegate, UICollectionViewDelegateFlowLayout>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

@property (strong, nonatomic) NSMutableArray *futureTrips;
@property (strong, nonatomic) NSMutableArray *pastTrips;
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) NSMutableArray *realTimeLocations;
@property (strong, nonatomic) Trip *newestTrip;

@end

@implementation HomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.locationManager = [LocationManager shared];
    self.locationManager.delegate = self;
    self.realTimeLocations = [NSMutableArray array];
    
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    [self.collectionView registerNib:[UINib nibWithNibName:@"HomeCollectionHeader" bundle:nil] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"HomeCollectionHeader"];
    [self.collectionView registerNib:[UINib nibWithNibName:@"HomeCell" bundle:nil] forCellWithReuseIdentifier:@"HomeCell"];
    
    self.collectionView.collectionViewLayout = [self generateLayout];
//    layout.minimumLineSpacing = 5;
//    layout.minimumInteritemSpacing = 5;
//    CGFloat itemHeight = self.futureCollectionView.frame.size.height;
//    layout.itemSize = CGSizeMake(itemHeight, itemHeight);
    
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
                [self startLocationUpdates];
            }
        });
    }
    [self.locationManager requestWhenInUseAuthorization];
}

- (void)didCreateTrip:(Trip *)trip {
    //sets timer for new trips
    [self.futureTrips addObject:trip];
    [self.collectionView reloadData];
    self.newestTrip = trip;
    
    NSTimeInterval timeInterval = trip.startTime.timeIntervalSince1970 - [NSDate now].timeIntervalSince1970;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timeInterval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (CLLocationManager.locationServicesEnabled){
            [self startLocationUpdates];
        }
    });
}

- (UICollectionViewLayout *) generateLayout {
    static int EDGE_INSETS = 5;
    static int SECTION_HEADER_HEIGHT = 44;
    
    UICollectionViewLayout *layout = [[UICollectionViewCompositionalLayout alloc] initWithSectionProvider:^NSCollectionLayoutSection *_Nullable(NSInteger section, id<NSCollectionLayoutEnvironment> sectionProvider) {
        
        //item
        NSCollectionLayoutSize *itemSize = [NSCollectionLayoutSize sizeWithWidthDimension:[NSCollectionLayoutDimension fractionalWidthDimension:1] heightDimension:[NSCollectionLayoutDimension fractionalWidthDimension:1]];
        
        NSCollectionLayoutItem *item = [NSCollectionLayoutItem itemWithLayoutSize:itemSize];
        item.contentInsets = NSDirectionalEdgeInsetsMake(5, 5, 5, 5);
        
        //group
        NSCollectionLayoutSize *groupSize = [NSCollectionLayoutSize sizeWithWidthDimension:[NSCollectionLayoutDimension fractionalWidthDimension:1.0] heightDimension:[NSCollectionLayoutDimension fractionalHeightDimension:0.4]];
        
        NSCollectionLayoutGroup *group = [NSCollectionLayoutGroup horizontalGroupWithLayoutSize:groupSize subitem:item count:1];
        group.contentInsets = NSDirectionalEdgeInsetsMake(EDGE_INSETS, EDGE_INSETS, EDGE_INSETS, EDGE_INSETS);
        
        //section
        NSCollectionLayoutSection *sectionLayout = [NSCollectionLayoutSection sectionWithGroup:group];
        
        NSCollectionLayoutSize *headerSize = [NSCollectionLayoutSize sizeWithWidthDimension:[NSCollectionLayoutDimension fractionalWidthDimension:1] heightDimension:[NSCollectionLayoutDimension estimatedDimension:SECTION_HEADER_HEIGHT]];
        
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
    HomeCollectionHeader *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"HomeCollectionHeader" forIndexPath:indexPath];
    headerView.nameLabel.text = indexPath.section == 0 ? @"Upcoming" : @"Past";
    return headerView;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *data = [collectionView.restorationIdentifier isEqualToString: @"futureCollectionView"] ? self.futureTrips : self.pastTrips;
    Trip *trip = data[indexPath.item];
    [self performSegueWithIdentifier:@"tripDetailsSegue" sender:trip];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return section == 0 ? self.futureTrips.count : self.pastTrips.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *data = indexPath.section == 0 ? self.futureTrips : self.pastTrips;
    HomeCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"HomeCell" forIndexPath:indexPath];
    
    if (cell == nil) {
            NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"HomeCell" owner:self options:nil];
            cell = [topLevelObjects objectAtIndex:0];
    }
    
    Trip *trip = data[indexPath.item];
    cell.nameLabel.text = trip.name;
    cell.descriptionLabel.text = trip.tripDescription;
    cell.dateLabel.text = [trip.startTime formattedDateWithStyle:NSDateFormatterMediumStyle];
    
    [cell setNeedsLayout];
    [cell layoutIfNeeded];
    
    return cell;
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    for (CLLocation *location in locations){
        if (location.horizontalAccuracy < 20 && fabs([location.timestamp timeIntervalSinceNow]) < 10) {
            [self.realTimeLocations addObject:location];
        }
    }
}

- (void)startLocationUpdates {
    self.locationManager.activityType = CLActivityTypeAutomotiveNavigation;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    self.locationManager.distanceFilter = 100;
    self.locationManager.allowsBackgroundLocationUpdates = true;
    [self.locationManager startUpdatingLocation];
    [self.locationManager startMonitoringSignificantLocationChanges];
    
    //commented out for testing purposes
    [self performSelector:@selector(saveRouteWithTrip:) withObject:self.newestTrip afterDelay:120];
   // [self performSelector:@selector(saveRouteWithTrip:) withObject:self.newestTrip afterDelay:[self.newestTrip.endLocation.time timeIntervalSinceDate:self.newestTrip.startTime]];
}

- (void)saveRouteWithTrip:(Trip *)trip {
    NSMutableArray *tripLocations = [NSMutableArray array];
    for (CLLocation *location in self.realTimeLocations){
        [tripLocations addObject:@[[NSNumber numberWithDouble: location.coordinate.latitude], [NSNumber numberWithDouble: location.coordinate.longitude], location.timestamp]];
    }
    [self.locationManager stopUpdatingLocation];
    [self.locationManager stopMonitoringSignificantLocationChanges];
    
    [self snapToRoadsWithCoordinates:tripLocations];
}

- (void)snapToRoadsWithCoordinates:(NSArray *)coordinates {
    //calls Google Roads API to snap coordinates to exact roads traveled
    NSString *path = [[NSBundle mainBundle] pathForResource: @"Keys" ofType: @"plist"];
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile: path];
    NSString *key= [dict objectForKey: @"API_Key"];
    
    NSString *coords = @"";
    for (NSArray *coordinate in coordinates) {
        coords = [coords stringByAppendingString:[NSString stringWithFormat:@"|%f,%f",[coordinate[0] doubleValue],[coordinate[1] doubleValue]]];
    }
    coords = [coords substringFromIndex:1];
    
    NSString *urlString = [NSString stringWithFormat: @"https://roads.googleapis.com/v1/snapToRoads?path=%@&interpolate=true&key=%@",coords,key];
    NSString *encodedString = [urlString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    NSURL* url = [NSURL URLWithString:encodedString];
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30.0];

     __block NSError *error1 = [[NSError alloc] init];
    __weak typeof(self) weakSelf = self;
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:nil delegateQueue:[NSOperationQueue mainQueue]];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if ([data length]>0 && error == nil) {
            NSDictionary *resultsDictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:&error1];
            NSMutableArray *tripLocations = [NSMutableArray array];
            
            //save coordinates, placeID, and time for each point on trip
            NSArray *points = resultsDictionary[@"snappedPoints"];
            for (NSDictionary *point in points){
                NSDictionary *location = point[@"location"];
                NSMutableArray *coordinate = [@[[NSNumber numberWithDouble:[location[@"latitude"] doubleValue]],[NSNumber numberWithDouble:[location[@"longitude"] doubleValue]], point[@"placeId"]] mutableCopy];
                if (point[@"originalIndex"]){
                    [coordinate addObject:coordinates[[point[@"originalIndex"] intValue]][2]];
                }
                [tripLocations addObject:coordinate];
            }
            
            weakSelf.newestTrip.realTimeCoordinates = tripLocations;
            [weakSelf.newestTrip saveInBackground];
        }
    }];
    [task resume];
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"tripDetailsSegue"]){
        MapViewController *mapViewController = [segue destinationViewController];
        mapViewController.trip = sender;
        mapViewController.isNewTrip = false;
        mapViewController.isOwnTrip = true;
    } else if ([segue.identifier isEqualToString:@"newTripSegue"]){
        NewTripViewController *newTripViewController = [segue destinationViewController];
        newTripViewController.isNewTrip = true;
    }
}

@end
