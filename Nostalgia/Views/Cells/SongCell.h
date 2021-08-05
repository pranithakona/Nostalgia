//
//  SongCell.h
//  Nostalgia
//
//  Created by Pranitha Reddy Kona on 8/4/21.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SongCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *artistLabel;

@end

NS_ASSUME_NONNULL_END
