//
//  ItineraryCell.h
//  Nostalgia
//
//  Created by Pranitha Reddy Kona on 7/14/21.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ItineraryCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UILabel *orderLabel;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UIView *topConnectorView;
@property (weak, nonatomic) IBOutlet UIView *bottomConnectorView;

@end

NS_ASSUME_NONNULL_END
