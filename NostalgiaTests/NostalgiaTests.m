//
//  NostalgiaTests.m
//  NostalgiaTests
//
//  Created by Pranitha Reddy Kona on 7/10/21.
//

#import <XCTest/XCTest.h>
#import "Trip.h"
#import "Destination.h"
#import "CreateViewController.h"
#import "CreateViewController+Tests.h"
#import "MapViewController.h"
#import "MapViewController+Tests.h"
#import "DateTools.h"
@import Parse;
@import GooglePlaces;

@interface NostalgiaTests : XCTestCase

@property (strong, nonatomic) Destination *startLocation;
@end

@implementation NostalgiaTests


- (void)testPostDestination {
    XCTestExpectation *destinationExpectation = [self expectationWithDescription:@"Destination expectation"];
    NSString *placeId = @"ChIJV4k8_9UodTERU5KXbkYpSYs";

    GMSPlaceField fields = (GMSPlaceFieldName | GMSPlaceFieldCoordinate | GMSPlaceFieldPlaceID);
    [[GMSPlacesClient sharedClient] fetchPlaceFromPlaceID:placeId placeFields:fields sessionToken:nil callback:^(GMSPlace * _Nullable place, NSError * _Nullable error) {
      if (error == nil && place != nil) {
          [Destination postDestination:place withCompletion:^(Destination * _Nullable dest, NSError * _Nullable error) {
              self.startLocation = dest;
              BOOL flag = (error == nil && dest);
              XCTAssert(flag);
              [destinationExpectation fulfill];
          }];
      }
    }];
    
    XCTestExpectation *nilDestinationExpectation = [self expectationWithDescription:@"nil destination expectation"];
    [Destination postDestination:nil withCompletion:^(Destination * _Nullable dest, NSError * _Nullable error) {
        BOOL flag = (error == nil && !dest);
        XCTAssert(flag);
        [nilDestinationExpectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:10 handler:nil];
}

- (void)testPostTrip {
    XCTestExpectation *tripExpectation = [self expectationWithDescription:@"Trip expectation"];
    Trip *trip = [Trip new];
    [Trip postTrip:trip withCompletion:^(Trip * _Nullable trip, NSError * _Nullable error) {
        BOOL flag = (error == nil && trip);
        XCTAssert(flag);
        [tripExpectation fulfill];
    }];
    
    XCTestExpectation *niltripExpectation = [self expectationWithDescription:@"nil trip expectation"];
    [Trip postTrip:nil withCompletion:^(Trip * _Nullable trip, NSError * _Nullable error) {
        BOOL flag = (error == nil && !trip);
        XCTAssert(flag);
        [niltripExpectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:10 handler:nil];
}

- (void)testOrderDestinationsWithResults {
    CreateViewController *vc = [CreateViewController new];
    vc.arrayOfDestinations = [NSMutableArray array];
    vc.routeTypeControl.selectedSegmentIndex = 0;
    vc.startLocation = [Destination new];
    vc.startLocation.duration = @0;
    vc.endLocation = [Destination new];
    vc.startTime = [NSDate now];
    
    NSMutableArray *legs = [NSMutableArray array];
    for (int i = 0; i < 4; i++){
        Destination *dest = [Destination new];
        dest.name = [NSString stringWithFormat:@"%d", i];
        dest.duration = @3600;
        [vc.arrayOfDestinations addObject:dest];
    }
    
    for (int i = 0; i < 5; i++ ){
        [legs addObject:@{@"distance":@{@"text": @""},
                          @"duration":@{@"value": @(i*60)}
        }];
    }
    
    NSDictionary *results =
    @{@"routes":@[@{@"legs":legs,
                    @"waypoint_order":@[@3,@1,@0,@2],
                    @"overview_polyline":@{}
    }]};

    NSMutableArray *orderedArray = [vc orderDestinationswithResults:results];
    
    NSArray *correctOrder = @[vc.startLocation,vc.arrayOfDestinations[3],vc.arrayOfDestinations[1],vc.arrayOfDestinations[0],vc.arrayOfDestinations[2],vc.endLocation];
    
    NSMutableArray *correctDates = [NSMutableArray array];
    NSDate *currentTime = vc.startTime;
    for (int i = 0; i < correctOrder.count; i++) {
        [correctDates addObject:currentTime];
        if (i!=0){
            currentTime = [currentTime dateByAddingSeconds:3600];
        }
        currentTime = [currentTime dateByAddingSeconds:i*60];
    }
    
    for (int i = 0; i < correctOrder.count; i++){
        Destination *dest = orderedArray[i];
        NSDate *correctDate = correctDates[i];
        XCTAssertEqualObjects(correctOrder[i], dest);
        XCTAssertEqual(correctDate.hour, dest.time.hour);
        XCTAssertEqual(correctDate.minute, dest.time.minute);
    }
}

- (void)testDecodePolyline {
    MapViewController *vc = [MapViewController new];
    NSArray *coords = [vc decodePolyline:@"egi~F~rbvOygEx}@p`@iyBd}FjnA"];
    NSArray *actualCoords = @[@[41.83171,-87.67296], @[41.86384,-87.68301], @[41.85847,-87.66344], @[41.81780,-87.67614]];
    
    for (int i = 0; i < actualCoords.count; i++){
        XCTAssertEqual(coords[i][0], actualCoords[i][0]);
        XCTAssertEqual(coords[i][1], actualCoords[i][1]);
    }
    
    NSArray *coords2 = [vc decodePolyline:@"wip~F|olzOe}BhyBgxDi{AvqFv|IrkCquEksHfzGexD}mJd{HioFd}CiR"];
    NSArray *actualCoords2 = @[@[41.86796,-88.37903], @[41.88815,-88.39860], @[41.91779,-88.38383], @[41.87895,-88.43979], @[41.85645,-88.40546], @[41.90579,-88.45078], @[41.93542,-88.39207], @[41.88483,-88.35362], @[41.85952,-88.35053]];
    
    for (int i = 0; i < actualCoords2.count; i++){
        XCTAssertEqual(coords2[i][0], actualCoords2[i][0]);
        XCTAssertEqual(coords2[i][1], actualCoords2[i][1]);
    }
    
    NSArray *coords3 = [vc decodePolyline:@"a{u~FbpmzO"];
    NSArray *actualCoords3 = @[@[41.89633,-88.38418]];

    for (int i = 0; i < actualCoords3.count; i++){
        XCTAssertEqual(coords3[i][0], actualCoords3[i][0]);
        XCTAssertEqual(coords3[i][1], actualCoords3[i][1]);
    }
    
    NSArray *coords4 = [vc decodePolyline:@""];
    XCTAssertNil(coords4);
    
    NSArray *coords5 = [vc decodePolyline:nil];
    XCTAssertNil(coords5);
}

- (void)testInBounds {
    MapViewController *vc = [MapViewController new];
    BOOL inbounds = [vc isInbounds:@[41.91787,-88.38855] withSecond:@[41.91692,-88.38879] withActual:@[41.91742,-88.38867]];
    XCTAssertTrue(inBounds);
    
    BOOL inbounds2 = [vc isInbounds:@[41.91787,-88.38855] withSecond:@[41.91692,-88.38879] withActual:@[41.91776,-88.38954]];
    XCTAssertFalse(inBounds2);
    
    BOOL inbounds3 = [vc isInbounds:nil withSecond:@[41.91692,-88.38879] withActual:@[41.91776,-88.38954]];
    XCTAssertFalse(inBounds3);
    
}

@end
