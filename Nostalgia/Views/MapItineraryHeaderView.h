//
//  MapItineraryHeaderView.h
//  Nostalgia
//
//  Created by Pranitha Reddy Kona on 7/14/21.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol MapItineraryHeaderViewDelegate

- (void)didExpandItinerary;
- (void)didCollapseItinerary;

@end

@interface MapItineraryHeaderView : UICollectionReusableView
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet UIButton *expandButton;
@property (weak, nonatomic) IBOutlet UIButton *collapseButton;

@property (weak, nonatomic) id<MapItineraryHeaderViewDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
