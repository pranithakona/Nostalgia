//
//  ExploreCell.h
//  Nostalgia
//
//  Created by Pranitha Reddy Kona on 7/26/21.
//

#import <UIKit/UIKit.h>
#import <Parse/PFImageView.h>

NS_ASSUME_NONNULL_BEGIN

@interface ExploreCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet PFImageView *backgroundImageView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;

@end

NS_ASSUME_NONNULL_END
