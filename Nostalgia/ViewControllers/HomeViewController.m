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
@import Parse;

@interface HomeViewController () <UICollectionViewDelegate, UICollectionViewDataSource, CLLocationManagerDelegate>

@property (weak, nonatomic) IBOutlet UICollectionView *futureCollectionView;
@property (weak, nonatomic) IBOutlet UICollectionView *pastCollectionView;
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
    
    self.futureCollectionView.delegate = self;
    self.futureCollectionView.dataSource = self;
    self.pastCollectionView.delegate = self;
    self.pastCollectionView.dataSource = self;
    
    [self.futureCollectionView registerNib:[UINib nibWithNibName:@"HomeCell" bundle:nil] forCellWithReuseIdentifier:@"HomeCell"];
    [self.pastCollectionView registerNib:[UINib nibWithNibName:@"HomeCell" bundle:nil] forCellWithReuseIdentifier:@"HomeCell"];
    
    UICollectionViewFlowLayout *layout = [self.futureCollectionView collectionViewLayout];
    layout.minimumLineSpacing = 5;
    layout.minimumInteritemSpacing = 5;
    CGFloat itemHeight = self.futureCollectionView.frame.size.height;
    layout.itemSize = CGSizeMake(itemHeight, itemHeight);
    
    UICollectionViewFlowLayout *layout2 = [self.pastCollectionView collectionViewLayout];
    layout2.minimumLineSpacing = 5;
    layout2.minimumInteritemSpacing = 5;
    CGFloat itemHeight2 = self.pastCollectionView.frame.size.height;
    layout2.itemSize = CGSizeMake(itemHeight2, itemHeight2);
    
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
    
    [self.locationManager requestWhenInUseAuthorization];
}

- (void)didCreateTrip:(Trip *)trip {
    [self.futureTrips addObject:trip];
    [self.futureCollectionView reloadData];
    self.newestTrip = trip;
    
    if (CLLocationManager.locationServicesEnabled){
        NSTimer *timer = [[NSTimer alloc] initWithFireDate:trip.startTime interval:0 target:self selector:@selector(startLocationUpdates) userInfo:nil repeats:false];
        [NSRunLoop.mainRunLoop addTimer:timer forMode:NSDefaultRunLoopMode];
    }
}

- (IBAction)onLogout:(id)sender {
    [PFUser logOutInBackgroundWithBlock:^(NSError * _Nullable error) {
        SceneDelegate *sceneDelegate = (SceneDelegate *)[UIApplication sharedApplication].connectedScenes.allObjects[0].delegate;
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        LoginViewController *openingViewController = [storyboard instantiateViewControllerWithIdentifier:@"LoginViewController"];
        sceneDelegate.window.rootViewController = openingViewController;
    }];
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *data = [collectionView.restorationIdentifier isEqualToString: @"futureCollectionView"] ? self.futureTrips : self.pastTrips;
    Trip *trip = data[indexPath.item];
    [self performSegueWithIdentifier:@"tripDetailsSegue" sender:trip];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [collectionView.restorationIdentifier isEqualToString: @"futureCollectionView"] ? self.futureTrips.count : self.pastTrips.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *data = [collectionView.restorationIdentifier isEqualToString: @"futureCollectionView"] ? self.futureTrips : self.pastTrips;
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
    NSLog(@"location update");
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
    NSLog(@"location is updating starting now");
    
    
    [self performSelector:@selector(saveRouteWithTrip:) withObject:self.newestTrip afterDelay:120];
   // [self performSelector:@selector(saveRouteWithTrip:) withObject:self.newestTrip afterDelay:[self.newestTrip.endLocation.time timeIntervalSinceDate:self.newestTrip.startTime]];
}

- (void)saveRouteWithTrip:(Trip *)trip  {
    NSLog(@"location is stopping updates now");
    NSMutableArray *tripLocations = [NSMutableArray array];
    for (CLLocation *location in self.realTimeLocations){
        [tripLocations addObject:@[[NSNumber numberWithDouble: location.coordinate.latitude], [NSNumber numberWithDouble: location.coordinate.longitude], location.timestamp]];
    }
    [self.locationManager stopUpdatingLocation];
    [self.locationManager stopMonitoringSignificantLocationChanges];
    
    [self snapToRoadsWithCoordinates:tripLocations];
}

- (void)snapToRoadsWithCoordinates:(NSArray *)coordinates {
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
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:nil delegateQueue:[NSOperationQueue mainQueue]];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if ([data length]>0 && error == nil) {
            NSDictionary *resultsDictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:&error1];
            NSMutableArray *tripLocations = [NSMutableArray array];
            
            NSArray *points = resultsDictionary[@"snappedPoints"];
            for (NSDictionary *point in points){
                NSDictionary *location = point[@"location"];
                NSMutableArray *coordinate = [@[[NSNumber numberWithDouble:[location[@"latitude"] doubleValue]],[NSNumber numberWithDouble:[location[@"longitude"] doubleValue]], point[@"placeId"]] mutableCopy];
                if (point[@"originalIndex"]){
                    [coordinate addObject:coordinates[[point[@"originalIndex"] intValue]]];
                }
                [tripLocations addObject:coordinate];
            }
            
            NSLog(@"trip locations : %@", tripLocations);
            self.newestTrip.realTimeCoordinates = tripLocations;
            [self.newestTrip saveInBackground];
        } else {
            NSLog(@"error: %@", error);
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
    } else if ([segue.identifier isEqualToString:@"newTripSegue"]){
        NewTripViewController *newTripViewController = [segue destinationViewController];
        newTripViewController.isNewTrip = true;
    }
}

@end
