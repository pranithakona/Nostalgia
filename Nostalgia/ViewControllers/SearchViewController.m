//
//  SearchViewController.m
//  Nostalgia
//
//  Created by Pranitha Reddy Kona on 7/26/21.
//

#import "SearchViewController.h"
#import "ExploreCell.h"
#import "ExploreFilterHeader.h"
#import "HomeCollectionHeader.h"
#import "MapViewController.h"
#import "PhotoViewController.h"
#import "Trip.h"
#import <GoogleMaps/GoogleMaps.h>
#import <GooglePlaces/GooglePlaces.h>
#import <Parse/Parse.h>

@interface SearchViewController () <GMSAutocompleteViewControllerDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, ExploreFilterHeaderDelegate, GMSMapViewDelegate>
@property (weak, nonatomic) IBOutlet UIView *buttonView;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UIView *detailsView;
@property (weak, nonatomic) IBOutlet UIButton *expandButton;
@property (weak, nonatomic) IBOutlet UIButton *collapseButton;

@property (strong, nonatomic) NSArray<GMSPlacePhotoMetadata *> *photosArray;
@property (strong, nonatomic) NSArray<Trip *> *itinerariesArray;
@property (strong, nonatomic) NSArray<NSDictionary *> *placesArray;
@property (strong, nonatomic) GMSMapView *mapView;
@property (strong, nonatomic) GMSPlace *currentRegion;
@property (strong, nonatomic) GMSMarker *infoMarker;
@property (strong, nonatomic) GMSPlacesClient *placesClient;

@end

@implementation SearchViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.placesClient = [GMSPlacesClient sharedClient];
    
    self.navigationController.navigationBarHidden = true;
    
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    [self.collectionView registerNib:[UINib nibWithNibName:@"ExploreCell" bundle:nil] forCellWithReuseIdentifier:@"ExploreCell"];
    [self.collectionView registerNib:[UINib nibWithNibName:@"HomeCollectionHeader" bundle:nil] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"HomeCollectionHeader"];
    [self.collectionView registerNib:[UINib nibWithNibName:@"ExploreFilterHeader" bundle:nil] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"ExploreFilterHeader"];
    self.collectionView.collectionViewLayout = [self generateLayout];
    
    GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:-33.7767 longitude:96.797 zoom:10];
    
    GMSMapID *mapID = [GMSMapID mapIDWithIdentifier:@"5c25f377317d20b8"];
    self.mapView = [GMSMapView mapWithFrame:self.view.frame mapID:mapID camera:camera];
    self.mapView.myLocationEnabled = YES;
    self.mapView.delegate = self;
    [self.view addSubview:self.mapView];
    [self.view insertSubview:self.buttonView aboveSubview:self.mapView];
    [self.view insertSubview:self.detailsView aboveSubview:self.mapView];
}

- (void)viewWillAppear:(BOOL)animated {
    self.navigationController.navigationBarHidden = true;
}

- (void)fetchItinerariesForRegion:(NSString *)placeID {
    PFQuery *query = [PFQuery queryWithClassName:@"Trip"];
    [query whereKey:@"regionID" equalTo:placeID];
    query.limit = 20;
    [query includeKey:@"name"];
    [query includeKey:@"owner"];
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *itineraries, NSError *error) {
        if (itineraries != nil) {
            self.itinerariesArray = itineraries;
            [self.collectionView reloadData];
        }
    }];
}

- (void)fetchPlacesForRegion:(CLLocationCoordinate2D)coordinate withType:(NSString *)type {
    //if type is nil, get all nearby places, otherwise filter by type of place
    NSString *path = [[NSBundle mainBundle] pathForResource: @"Keys" ofType: @"plist"];
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile: path];
    NSString *key= [dict objectForKey: @"API_Key"];
    
    NSString *keywordString = type != nil ? [NSString stringWithFormat:@"&keyword=%@",type] : @"";
    NSString *urlString = [NSString stringWithFormat: @"https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=%f,%f&radius=1500%@&key=%@",coordinate.latitude,coordinate.longitude, keywordString, key];
    NSString *encodedString = [urlString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    NSURL* url = [NSURL URLWithString:encodedString];
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30.0];

     __block NSError *error1 = [[NSError alloc] init];
    __weak typeof(self) weakSelf = self;
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:nil delegateQueue:[NSOperationQueue mainQueue]];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if ([data length]>0 && error == nil) {
            typeof(self) strongSelf = weakSelf;
            NSDictionary *resultsDictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:&error1];
            strongSelf.placesArray = resultsDictionary[@"results"];
            [strongSelf.collectionView reloadData];
        }
    }];
    [task resume];
}

- (void)filterByType:(NSString *)type {
    [self fetchPlacesForRegion:self.currentRegion.coordinate withType:type];
}

#pragma mark - Collection View

- (UICollectionViewLayout *)generateLayout {
    static int EDGE_INSETS = 5;
    
    UICollectionViewLayout *layout = [[UICollectionViewCompositionalLayout alloc] initWithSectionProvider:^NSCollectionLayoutSection *_Nullable(NSInteger section, id<NSCollectionLayoutEnvironment> sectionProvider) {
        
        int SECTION_HEADER_HEIGHT = section == 1 ? 100 : 45;
        
        //item
        NSCollectionLayoutSize *itemSize = [NSCollectionLayoutSize sizeWithWidthDimension:[NSCollectionLayoutDimension fractionalWidthDimension:1.0] heightDimension:[NSCollectionLayoutDimension fractionalHeightDimension:1.0]];
        
        NSCollectionLayoutItem *item = [NSCollectionLayoutItem itemWithLayoutSize:itemSize];
        
        //group
        NSCollectionLayoutSize *groupSize = [NSCollectionLayoutSize sizeWithWidthDimension:[NSCollectionLayoutDimension absoluteDimension:250] heightDimension:[NSCollectionLayoutDimension absoluteDimension:200]];
        
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
    return 3;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (section == 0) {
        return MIN(self.photosArray.count, 20);
    } else if (section == 1) {
        return MIN(self.placesArray.count, 20);
    } else if (section == 2) {
        return MIN(self.itinerariesArray.count, 20);
    }
    return 0;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        HomeCollectionHeader *header = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"HomeCollectionHeader" forIndexPath:indexPath];
        header.nameLabel.text = @"Photos";
        return header;
    } else if (indexPath.section == 1) {
        ExploreFilterHeader *header = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"ExploreFilterHeader" forIndexPath:indexPath];
        header.delegate = self;
        return header;
    } else if (indexPath.section == 2) {
        HomeCollectionHeader *header = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"HomeCollectionHeader" forIndexPath:indexPath];
        header.nameLabel.text = @"Itineraries";
        return header;
    }
    return nil;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    ExploreCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"ExploreCell" forIndexPath:indexPath];
    cell.backgroundImageView.image = nil;
    cell.nameLabel.hidden = false;
    
    if (indexPath.section == 0) {
        //place photos
        GMSPlacePhotoMetadata *photoMetadata = self.photosArray[indexPath.item];
        [self.placesClient loadPlacePhoto:photoMetadata callback:^(UIImage * _Nullable photo, NSError * _Nullable error) {
            if (error == nil) {
                [cell.backgroundImageView setImage:photo];
            }
        }];
        cell.nameLabel.hidden = true;
    } else if (indexPath.section == 1) {
        //explore places
        NSDictionary *place = self.placesArray[indexPath.item];
        cell.nameLabel.text = place[@"name"];
        
    } else if (indexPath.section == 2) {
        //existing itineraries
        Trip *trip = self.itinerariesArray[indexPath.item];
        cell.nameLabel.text = trip.name;
    }
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        //open photo
        [self performSegueWithIdentifier:@"photoSegue" sender:self.photosArray[indexPath.item]];
    } else if (indexPath.section == 1) {
        //show location details on icon view on map
        [self didCollapseDetails:self];
        NSDictionary *place = self.placesArray[indexPath.item];
        CLLocationCoordinate2D location = CLLocationCoordinate2DMake([place[@"geometry"][@"location"][@"lat"] doubleValue], [place[@"geometry"][@"location"][@"lng"] doubleValue]);
        self.infoMarker = [GMSMarker markerWithPosition:location];
        self.infoMarker.title = place[@"name"];
        self.infoMarker.opacity = 0;
        CGPoint pos = self.infoMarker.infoWindowAnchor;
        pos.y = 1;
        self.infoMarker.infoWindowAnchor = pos;
        self.infoMarker.map = self.mapView;
        self.mapView.selectedMarker = self.infoMarker;
        GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:location.latitude longitude:location.longitude zoom:15];
        [self.mapView setCamera:camera];
    } else if (indexPath.section == 2) {
        //open trip on map view
        [self performSegueWithIdentifier:@"existingItinerarySegue" sender:self.itinerariesArray[indexPath.item]];
    }
}

- (IBAction)didExpandDetails:(id)sender {
    [UIView animateWithDuration:0.5 animations:^{
        self.detailsView.transform = CGAffineTransformMakeTranslation(0, -600);
    }];
    self.expandButton.hidden = true;
    self.collapseButton.hidden = false;
    self.buttonView.hidden = true;
}

- (IBAction)didCollapseDetails:(id)sender {
    [UIView animateWithDuration:0.5 animations:^{
        self.detailsView.transform = CGAffineTransformMakeTranslation(0, 40);
    }];
    self.expandButton.hidden = false;
    self.collapseButton.hidden = true;
    self.buttonView.hidden = false;
}

#pragma mark - GoogleMaps/GooglePlaces

- (IBAction)searchCity:(id)sender {
    GMSAutocompleteViewController *acController = [[GMSAutocompleteViewController alloc] init];
    acController.delegate = self;

    GMSPlaceField fields = (GMSPlaceFieldName | GMSPlaceFieldCoordinate | GMSPlaceFieldPlaceID | GMSPlaceFieldPhotos);
    acController.placeFields = fields;

    GMSAutocompleteFilter *filter = [[GMSAutocompleteFilter alloc] init];
    filter.type = kGMSPlacesAutocompleteTypeFilterRegion;
    acController.autocompleteFilter = filter;

    [self presentViewController:acController animated:YES completion:nil];
}

- (void)viewController:(GMSAutocompleteViewController *)viewController didAutocompleteWithPlace:(GMSPlace *)place {
    [self dismissViewControllerAnimated:YES completion:nil];

    self.currentRegion = place;
    [self fetchItinerariesForRegion:place.placeID];
    [self fetchPlacesForRegion:place.coordinate withType:nil];
    self.photosArray = [NSArray arrayWithArray:place.photos];
    self.nameLabel.text = place.name;
    
    GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:place.coordinate.latitude longitude:place.coordinate.longitude zoom:10];
    [self.mapView setCamera:camera];
    self.detailsView.hidden = false;
}

- (void)viewController:(GMSAutocompleteViewController *)viewController didFailAutocompleteWithError:(NSError *)error {
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

- (void)mapView:(GMSMapView *)mapView didTapPOIWithPlaceID:(NSString *)placeID name:(NSString *)name location:(CLLocationCoordinate2D)location {
    self.infoMarker = [GMSMarker markerWithPosition:location];
    self.infoMarker.title = name;
    self.infoMarker.opacity = 0;
    CGPoint pos = self.infoMarker.infoWindowAnchor;
    pos.y = 1;
    self.infoMarker.infoWindowAnchor = pos;
    self.infoMarker.map = mapView;
    mapView.selectedMarker = self.infoMarker;
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"existingItinerarySegue"]) {
        MapViewController *mapViewController = [segue destinationViewController];
        mapViewController.trip = sender;
        mapViewController.canEditTrip = false;
        mapViewController.isNewTrip = false;
    } else if ([segue.identifier isEqualToString:@"photoSegue"]) {
        PhotoViewController *photoViewController = [segue destinationViewController];
        photoViewController.photoMetaData = sender;
        photoViewController.photoFile = nil;
    }
}


@end
