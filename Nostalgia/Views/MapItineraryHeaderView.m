//
//  MapItineraryHeaderView.m
//  Nostalgia
//
//  Created by Pranitha Reddy Kona on 7/14/21.
//

#import "MapItineraryHeaderView.h"

@implementation MapItineraryHeaderView

- (IBAction)didExpand:(id)sender {
    self.collapseButton.hidden = false;
    self.expandButton.hidden = true;
    [self.delegate didExpandItinerary];
}

- (IBAction)didCollapse:(id)sender {
    self.expandButton.hidden = false;
    self.collapseButton.hidden = true;
    [self.delegate didCollapseItinerary];
}

@end
