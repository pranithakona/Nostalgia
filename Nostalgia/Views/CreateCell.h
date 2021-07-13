//
//  CreateCell.h
//  Nostalgia
//
//  Created by Pranitha Reddy Kona on 7/11/21.
//

#import <UIKit/UIKit.h>
#import "Destination.h"

NS_ASSUME_NONNULL_BEGIN

@protocol CreateCellDelegate

- (void)changeIsFixed: (Destination *) destination;

@end

@interface CreateCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UISwitch *fixedSwitch;
@property (weak, nonatomic) IBOutlet UITextField *timeLabel;

@property (strong, nonatomic) Destination *destination;
@property (weak, nonatomic) id<CreateCellDelegate> delegate;

- (void)setCellWithDestination: (Destination *) destination;

@end

NS_ASSUME_NONNULL_END
