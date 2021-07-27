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

- (void)deleteCell:(Destination *)dest;

@end

@interface CreateCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UIButton *deleteButton;
@property (weak, nonatomic) IBOutlet UIDatePicker *durationDatePicker;
@property (weak, nonatomic) IBOutlet UIDatePicker *startDatePicker;
@property (weak, nonatomic) IBOutlet UIDatePicker *endDatePicker;
@property (weak, nonatomic) IBOutlet UILabel *orderLabel;
@property (weak, nonatomic) IBOutlet UIView *planView;
@property (weak, nonatomic) IBOutlet UIView *optimizeView;

@property (strong, nonatomic) Destination *destination;
@property (weak, nonatomic) id<CreateCellDelegate> delegate;

- (void)setCellWithDestination: (Destination *) destination;

@end


NS_ASSUME_NONNULL_END
