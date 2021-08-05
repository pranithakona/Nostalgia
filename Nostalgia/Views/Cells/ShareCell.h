//
//  ShareCell.h
//  Nostalgia
//
//  Created by Pranitha Reddy Kona on 7/14/21.
//

#import <UIKit/UIKit.h>
#import <Parse/PFImageView.h>

NS_ASSUME_NONNULL_BEGIN

@interface ShareCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *userNameLabel;
@property (weak, nonatomic) IBOutlet PFImageView *profileImageView;

@end

NS_ASSUME_NONNULL_END
