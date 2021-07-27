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
#import "Trip.h"
#import <GoogleMaps/GoogleMaps.h>
#import <GooglePlaces/GooglePlaces.h>
#import <Parse/Parse.h>

@interface SearchViewController () <GMSAutocompleteViewControllerDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>
@property (weak, nonatomic) IBOutlet UIView *buttonView;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UIView *detailsView;
@property (weak, nonatomic) IBOutlet UIButton *expandButton;
@property (weak, nonatomic) IBOutlet UIButton *collapseButton;

@property (strong, nonatomic) GMSMapView *mapView;
@property (strong, nonatomic) NSArray *photosArray;
@property (strong, nonatomic) NSArray *itinerariesArray;
@property (strong, nonatomic) GMSPlacesClient *placesClient;

@end

@implementation SearchViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    [self.collectionView registerNib:[UINib nibWithNibName:@"ExploreCell" bundle:nil] forCellWithReuseIdentifier:@"ExploreCell"];
    [self.collectionView registerNib:[UINib nibWithNibName:@"HomeCollectionHeader" bundle:nil] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"HomeCollectionHeader"];
    [self.collectionView registerNib:[UINib nibWithNibName:@"ExploreFilterHeader" bundle:nil] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"ExploreFilterHeader"];
    self.collectionView.collectionViewLayout = [self generateLayout];
    
    GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:-33.86 longitude:153.67 zoom:10];
    
    GMSMapID *mapID = [GMSMapID mapIDWithIdentifier:@"5c25f377317d20b8"];
    self.mapView = [GMSMapView mapWithFrame:self.view.frame mapID:mapID camera:camera];
    self.mapView.myLocationEnabled = YES;
    [self.view addSubview:self.mapView];
    [self.view insertSubview:self.buttonView aboveSubview:self.mapView];
    [self.view insertSubview:self.detailsView aboveSubview:self.mapView];
    
    self.placesClient = [GMSPlacesClient sharedClient];
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

- (UICollectionViewLayout *) generateLayout {
    static int EDGE_INSETS = 5;
    
    UICollectionViewLayout *layout = [[UICollectionViewCompositionalLayout alloc] initWithSectionProvider:^NSCollectionLayoutSection *_Nullable(NSInteger section, id<NSCollectionLayoutEnvironment> sectionProvider) {
        
        int SECTION_HEADER_HEIGHT = section == 1 ? 100 : 45;
        
        //item
        NSCollectionLayoutSize *itemSize = [NSCollectionLayoutSize sizeWithWidthDimension:[NSCollectionLayoutDimension fractionalWidthDimension:1] heightDimension:[NSCollectionLayoutDimension fractionalWidthDimension:1]];
        
        NSCollectionLayoutItem *item = [NSCollectionLayoutItem itemWithLayoutSize:itemSize];
        //item.contentInsets = NSDirectionalEdgeInsetsMake(5, 5, 5, 5);
        
        //group
        NSCollectionLayoutSize *groupSize = [NSCollectionLayoutSize sizeWithWidthDimension:[NSCollectionLayoutDimension fractionalWidthDimension:1.0] heightDimension:[NSCollectionLayoutDimension absoluteDimension:250]];
        
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
        return MIN(self.itinerariesArray.count, 20);
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
    
    if (indexPath.section == 0) {
        GMSPlacePhotoMetadata *photoMetadata = self.photosArray[indexPath.item];
        [self.placesClient loadPlacePhoto:photoMetadata callback:^(UIImage * _Nullable photo, NSError * _Nullable error) {
            if (error == nil) {
                [cell.backgroundImageView setImage:photo];
            }
        }];
        cell.nameLabel.hidden = true;
    } else if (indexPath.section == 1) {
        
    } else if (indexPath.section == 2) {
        Trip *trip = self.itinerariesArray[indexPath.item];
        cell.nameLabel.text = trip.name;
    }
    return cell;
}

- (IBAction)didExpandDetails:(id)sender {
    [UIView animateWithDuration:0.5 animations:^{
        self.detailsView.transform = CGAffineTransformMakeTranslation(0, -600);
    }];
    self.expandButton.hidden = true;
    self.collapseButton.hidden = false;
    self.buttonView.hidden = true;
}

- (IBAction)didCollpseDetails:(id)sender {
    [UIView animateWithDuration:0.5 animations:^{
        self.detailsView.transform = CGAffineTransformMakeTranslation(0, 40);
    }];
    self.expandButton.hidden = false;
    self.collapseButton.hidden = true;
    self.buttonView.hidden = false;
}

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

- (void)viewController:(GMSAutocompleteViewController *)viewController
    didAutocompleteWithPlace:(GMSPlace *)place {
    [self dismissViewControllerAnimated:YES completion:nil];

    [self fetchItinerariesForRegion:place.placeID];
    self.photosArray = [NSArray arrayWithArray:place.photos];
    self.nameLabel.text = place.name;
    
    GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:place.coordinate.latitude longitude:place.coordinate.longitude zoom:10];
    [self.mapView setCamera:camera];
    self.detailsView.hidden = false;
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
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
