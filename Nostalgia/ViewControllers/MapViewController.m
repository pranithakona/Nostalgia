//
//  MapViewController.m
//  Nostalgia
//
//  Created by Pranitha Reddy Kona on 7/10/21.
//

#import "MapViewController.h"
#import "MapItineraryHeaderView.h"
#import "HomeViewController.h"
#import "CreateViewController.h"
#import "LocationManager.h"
#import "ItineraryCell.h"
#import "DateTools.h"
#import "NSDate+NSDateHelper.h"
@import GoogleMaps;

@interface MapViewController () <MapItineraryHeaderViewDelegate, UICollectionViewDelegate, UICollectionViewDataSource>

@property (weak, nonatomic) IBOutlet UIView *mapBaseView;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UIButton *editButton;

@property (strong, nonatomic) GMSMapView *mapView;

@end

@implementation MapViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    
    [self.trip.startLocation fetchIfNeeded];
    [self.trip.endLocation fetchIfNeeded];
    
    if (self.isNewTrip) {
        [self.editButton setTitle:@"Done" forState:UIControlStateNormal];
        [self.editButton removeTarget:self action:@selector(didPressEdit) forControlEvents:UIControlEventTouchUpInside];
        [self.editButton addTarget:self action:@selector(didPressDone) forControlEvents:UIControlEventTouchUpInside];
    }
    else {
        [self.editButton setTitle:@"Edit" forState:UIControlStateNormal];
        [self.editButton removeTarget:self action:@selector(didPressDone) forControlEvents:UIControlEventTouchUpInside];
        [self.editButton addTarget:self action:@selector(didPressEdit) forControlEvents:UIControlEventTouchUpInside];
    }
    
    GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:self.trip.startLocation.coordinates.latitude longitude:self.trip.startLocation.coordinates.longitude zoom:10];
    
    self.mapView = [GMSMapView mapWithFrame:self.mapBaseView.frame camera:camera];
      self.mapView.myLocationEnabled = YES;
      [self.mapBaseView addSubview:self.mapView];
    
    //make markers for map and find outermmost points of trip to set camera view on map
    Destination *topMost = self.trip.startLocation;
    Destination *bottomMost = self.trip.startLocation;
    Destination *leftMost = self.trip.startLocation;
    Destination *rightMost = self.trip.startLocation;
    for (Destination *dest in self.trip.destinations) {
        [dest fetchIfNeeded];
        CLLocationCoordinate2D position = CLLocationCoordinate2DMake(dest.coordinates.latitude, dest.coordinates.longitude);
        GMSMarker *marker = [GMSMarker markerWithPosition:position];
        marker.title = dest.name;
        marker.map = self.mapView;
        topMost = dest.coordinates.latitude > topMost.coordinates.latitude ? dest : topMost;
        bottomMost = dest.coordinates.latitude < bottomMost.coordinates.latitude ? dest : bottomMost;
        rightMost = dest.coordinates.longitude > rightMost.coordinates.longitude ? dest : rightMost;
        leftMost = dest.coordinates.longitude < leftMost.coordinates.longitude ? dest : leftMost;
    }
    
    //find bounds of coordinates for camera view
    GMSCoordinateBounds *bounds;
    if ((rightMost.coordinates.longitude - leftMost.coordinates.longitude) > (topMost.coordinates.latitude - bottomMost.coordinates.latitude)) {
        bounds = [[GMSCoordinateBounds alloc] initWithCoordinate:CLLocationCoordinate2DMake(rightMost.coordinates.latitude, rightMost.coordinates.longitude)  coordinate:CLLocationCoordinate2DMake(leftMost.coordinates.latitude, leftMost.coordinates.longitude)];
    } else {
        bounds = [[GMSCoordinateBounds alloc] initWithCoordinate:CLLocationCoordinate2DMake(topMost.coordinates.latitude, topMost.coordinates.longitude)  coordinate:CLLocationCoordinate2DMake(bottomMost.coordinates.latitude, bottomMost.coordinates.longitude)];
    }
    [self.mapView moveCamera:[GMSCameraUpdate fitBounds:bounds withPadding:50]];
    
    //if trip has already taken place, compare existing and planned journeys
    if (self.trip.realTimeCoordinates && self.trip.realTimeCoordinates.count > 0){
        //decode encoded polyline
        NSArray *polylines = [self comparePolylines:[self decodePolyline:self.trip.encodedPolyline]];
        NSArray *colors = @[[UIColor greenColor], [UIColor blueColor], [UIColor redColor]];
        for (int i = 0; i < polylines.count; i++) {
            for (NSArray *segment in polylines[i]){
                GMSMutablePath *path = [GMSMutablePath path];
                for (NSArray *coordinate in segment){
                    [path addCoordinate:CLLocationCoordinate2DMake([coordinate[0] doubleValue],[coordinate[1] doubleValue])];
                }
                GMSPolyline *polyline = [GMSPolyline polylineWithPath:path];
                polyline.strokeWidth = 3;
                polyline.strokeColor = colors[i];
                polyline.map = self.mapView;
            }
        }
    } else {
        //only map planned route
        GMSPath *path = [GMSPath pathFromEncodedPath:self.trip.encodedPolyline];
        GMSPolyline *polyline = [GMSPolyline polylineWithPath:path];
        polyline.map = self.mapView;
    }
}

- (NSArray *)comparePolylines:(NSArray *)plannedTripCoordinates {
    NSMutableArray *combinedPolylineSegments = [NSMutableArray array];
    NSMutableArray *plannedPolylineSegments = [NSMutableArray array];
    NSMutableArray *realTimePolylineSegments = [NSMutableArray array];
    
    int prevJ = -1;
    int prevI = 0;
    int i = 0;
    int j = 0;
    
    //iterate through each planned coordinate
    for (; i < plannedTripCoordinates.count-1 ; i ++) {
        NSArray *planCoordinate = plannedTripCoordinates[i];
        NSArray *nextPlanCoordinate = plannedTripCoordinates[i+1];
        BOOL inbounds = false;
        j = prevJ;
        //find first real time coordinate that is inside the bounds of two planned coordinates
        while (!inbounds && (j < self.trip.realTimeCoordinates.count - 1 || j == -1)) {
            j++;
            NSArray *realTimeCoordinate = self.trip.realTimeCoordinates[j];
            inbounds = [self isInbounds:planCoordinate withSecond:nextPlanCoordinate withActual:realTimeCoordinate];
        }
        
        if (inbounds) {
            NSMutableArray *tempRealTime = [NSMutableArray array];
            NSMutableArray *tempPlan = [NSMutableArray array];
            //if there is a gap between the last in bounds position and this one, it is a divergence
            if (prevJ != j || prevI != i){
                int temp = prevJ == -1 ? 0 : prevJ;
                tempRealTime = [NSMutableArray arrayWithArray:[self.trip.realTimeCoordinates subarrayWithRange:NSMakeRange(temp, j-temp)]];
                tempPlan = [NSMutableArray arrayWithArray:[plannedTripCoordinates subarrayWithRange:NSMakeRange(prevI, i-prevI)]];
            }
            //connect polylines to current position
            [tempRealTime addObject:self.trip.realTimeCoordinates[j]];
            [tempPlan addObject:self.trip.realTimeCoordinates[j]];
            [realTimePolylineSegments addObject:tempRealTime];
            [plannedPolylineSegments addObject:tempPlan];
            
            BOOL inboundsI = true;
            BOOL inboundsJ = true;
            NSMutableArray *tempArray = [NSMutableArray array];
            //move through real time and planned coordinates until they are no longer in bounds of each other and update corresponding arrays accordingly
            while (inboundsI && i < plannedTripCoordinates.count && j < self.trip.realTimeCoordinates.count - 1) {
                [tempArray addObject:planCoordinate];
                [tempArray addObject:nextPlanCoordinate];
                i++;
                planCoordinate = plannedTripCoordinates[i];
                nextPlanCoordinate = plannedTripCoordinates[i+1];
                NSArray *realTimeCoordinate = self.trip.realTimeCoordinates[j];
                inboundsI = [self isInbounds:planCoordinate withSecond:nextPlanCoordinate withActual:realTimeCoordinate];
                inboundsJ = inboundsI;
                while ((inboundsI && inboundsJ) && j < self.trip.realTimeCoordinates.count - 1) {
                    j++;
                    realTimeCoordinate = self.trip.realTimeCoordinates[j];
                    inboundsJ = [self isInbounds:planCoordinate withSecond:nextPlanCoordinate withActual:realTimeCoordinate];
                }
            }
            [combinedPolylineSegments addObject:tempArray];
            prevJ = j;
            prevI = i;
        }
    }
    //if left over coordinates at the end, they are diverged so they are added to the corresponding arrays
    if (i <= plannedTripCoordinates.count-1){
        [plannedPolylineSegments addObject:[plannedTripCoordinates subarrayWithRange:NSMakeRange(prevI, i-prevI)]];
    }
    if (j <= self.trip.realTimeCoordinates.count-1){
        int temp = prevJ == -1 ? 0 : prevJ;
        [realTimePolylineSegments addObject:[self.trip.realTimeCoordinates subarrayWithRange:NSMakeRange(temp, j-temp)]];
    }
    return @[combinedPolylineSegments, plannedPolylineSegments, realTimePolylineSegments];
}

- (BOOL)isInbounds:(NSArray *)firstCoordinate withSecond:(NSArray *)secondCoordinate withActual:(NSArray *)realTimeCoordinate {
    //check orientation of two planned coordinates (up vs down and left vs right)
    BOOL up = [firstCoordinate[0] doubleValue] <= [secondCoordinate[0] doubleValue];
    BOOL left = [firstCoordinate[1] doubleValue] <= [secondCoordinate[1] doubleValue];
    
    //check if real time coordinate is in between the first and second coordinate with a margin of error
    BOOL inboundsX = false;
    if (up) {
        inboundsX = [realTimeCoordinate[0] doubleValue] >= [firstCoordinate[0] doubleValue]-0.0006 && [realTimeCoordinate[0] doubleValue] <= [secondCoordinate[0] doubleValue]+0.0006;
    } else {
        inboundsX = [realTimeCoordinate[0] doubleValue] >= [secondCoordinate[0] doubleValue]-0.0006 && [realTimeCoordinate[0] doubleValue] <= [firstCoordinate[0] doubleValue]+0.0006;
    }
    if (left) {
        return [realTimeCoordinate[1] doubleValue] >= [firstCoordinate[1] doubleValue]-0.0006 && [realTimeCoordinate[1] doubleValue] <= [secondCoordinate[1] doubleValue]+0.0006 && inboundsX;
    } else {
        return [realTimeCoordinate[1] doubleValue] >= [secondCoordinate[1] doubleValue]-0.0006 && [realTimeCoordinate[1] doubleValue] <= [firstCoordinate[1] doubleValue]+0.0006 && inboundsX;
    }
}

- (NSArray *)decodePolyline:(NSString *)encodedString {
    //turn encoded polyline string into an array of coordinates
    //based on Google's encoded polyline equation
    NSMutableArray *points = [NSMutableArray array];
    if (!encodedString || [encodedString isEqualToString:@""]) {
        return nil;
    }
    int index = 0;
    int currentLat = 0;
    int currentLng = 0;
    int next5bits;
    int sum;
    int shifter;
    
     while (index < encodedString.length) {
         // calculate next latitude
         sum = 0;
         shifter = 0;
         do {
             next5bits = (int)[encodedString characterAtIndex:index++] - 63;
             sum |= (next5bits & 31) << shifter;
             shifter += 5;
         } while (next5bits >= 32 && index < encodedString.length);

         if (index >= encodedString.length)
             break;

         currentLat += (sum & 1) == 1 ? ~(sum >> 1) : (sum >> 1);

         //calculate next longitude
         sum = 0;
         shifter = 0;
         do {
             next5bits = (int)[encodedString characterAtIndex:index++] - 63;
             sum |= (next5bits & 31) << shifter;
             shifter += 5;
         } while (next5bits >= 32 && index < encodedString.length);

         if (index >= encodedString.length && next5bits >= 32)
             break;

         currentLng += (sum & 1) == 1 ? ~(sum >> 1) : (sum >> 1);
         NSArray *coordinate = @[[NSNumber numberWithDouble:((double)currentLat/ 100000.0)], [NSNumber numberWithDouble:((double)currentLng/ 100000.0)]];
         [points addObject:coordinate];
     }
    return points;
}

- (void)didPressEdit {
    [self performSegueWithIdentifier:@"editDestinationsSegue" sender:self];
}

- (void)didPressDone {
    [self performSegueWithIdentifier:@"endCreateSegue" sender:self];
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

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    MapItineraryHeaderView *headerView = [collectionView dequeueReusableSupplementaryViewOfKind: UICollectionElementKindSectionHeader withReuseIdentifier:@"MapItineraryHeaderView" forIndexPath:indexPath];
    headerView.delegate = self;
    headerView.nameLabel.text = self.trip.name;
    headerView.dateLabel.text = [NSDate fullDateString:self.trip.startTime];
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
    
    NSString *dateString = [NSDate timeOnlyString:dest.time];
    cell.timeLabel.text = dateString;
    
    return cell;
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"editDestinationsSegue"]){
        CreateViewController *createViewController = [segue destinationViewController];
        createViewController.isNewTrip = false;
        createViewController.trip = self.trip; 
    } else if ([segue.identifier isEqualToString:@"endCreateSegue"]){
        HomeViewController *homeViewController = [segue destinationViewController];
        [homeViewController didCreateTrip:self.trip];
    }
}

@end
