//
//  MapViewController+Tests.h
//  Nostalgia
//
//  Created by Pranitha Reddy Kona on 7/30/21.
//

#ifndef MapViewController_Tests_h
#define MapViewController_Tests_h

@interface MapViewController (Tests)

- (NSArray *)decodePolyline:(NSString *)encodedString;
- (BOOL)isInbounds:(NSArray *)firstCoordinate withSecond:(NSArray *)secondCoordinate withActual:(NSArray *)realTimeCoordinate

@end

#endif /* MapViewController_Tests_h */
