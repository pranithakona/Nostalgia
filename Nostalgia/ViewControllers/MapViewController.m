//
//  MapViewController.m
//  Nostalgia
//
//  Created by Pranitha Reddy Kona on 7/10/21.
//

#import "MapViewController.h"
#import "MapItineraryHeaderView.h"
#import "ItineraryCell.h"
#import "DateTools.h"
@import GoogleMaps;

@interface MapViewController () <MapItineraryHeaderViewDelegate, UICollectionViewDelegate, UICollectionViewDataSource>

@property (weak, nonatomic) IBOutlet UIView *mapBaseView;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

@end

@implementation MapViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    
    [self.trip.startLocation fetchIfNeeded];
    GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:self.trip.startLocation.coordinates.latitude longitude:self.trip.startLocation.coordinates.longitude zoom:10];
    
    GMSMapView *mapView = [GMSMapView mapWithFrame:self.mapBaseView.frame camera:camera];
      mapView.myLocationEnabled = YES;
      [self.mapBaseView addSubview:mapView];
    
    for (Destination *dest in self.trip.destinations){
        [dest fetchIfNeeded];
        CLLocationCoordinate2D position = CLLocationCoordinate2DMake(dest.coordinates.latitude, dest.coordinates.longitude);
        GMSMarker *marker = [GMSMarker markerWithPosition:position];
        marker.title = dest.name;
        marker.map = mapView;
    }
    
    GMSPath *path = [GMSPath pathFromEncodedPath:self.trip.encodedPolyline];
    GMSPolyline *polyline = [GMSPolyline polylineWithPath:path];
    polyline.map = mapView;
    
}

- (void)didExpandItinerary {
    [UIView animateWithDuration:0.5 animations:^{
        self.collectionView.transform = CGAffineTransformMakeTranslation(0, -400);
    }];
}

- (void)didCollapseItinerary {
    [UIView animateWithDuration:1.0 animations:^{
        self.collectionView.transform = CGAffineTransformMakeTranslation(0, 30);
    }];
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath{
    MapItineraryHeaderView *headerView = [collectionView dequeueReusableSupplementaryViewOfKind: UICollectionElementKindSectionHeader withReuseIdentifier:@"MapItineraryHeaderView" forIndexPath:indexPath];
    
    headerView.delegate = self;
    headerView.nameLabel.text = self.trip.name;
    headerView.dateLabel.text = [NSString stringWithFormat: @"%@", self.trip.startTime];
    return headerView;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.trip.destinations.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    ItineraryCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"ItineraryCell" forIndexPath:indexPath];
    Destination *dest = self.trip.destinations[indexPath.item];
    [dest fetchIfNeeded];
    cell.orderLabel.text = [NSString stringWithFormat:@"%ld", (long)indexPath.item];
    cell.nameLabel.text = dest.name;
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"E MMM d HH:mm:ss Z y";
    NSDate *date = self.trip.startTime;
    formatter.dateStyle = NSDateFormatterNoStyle;
    formatter.timeStyle = NSDateFormatterShortStyle;
    NSString *dateString = [formatter stringFromDate:date];
    cell.timeLabel.text = dateString;
    
    return cell;
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
