//
//  InfoWindowView.h
//  Nostalgia
//
//  Created by Pranitha Reddy Kona on 8/5/21.
//

#import <UIKit/UIKit.h>
#import "Cosmos/Cosmos-Swift.h"

NS_ASSUME_NONNULL_BEGIN

@interface InfoWindowView : UIView
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *addressLabel;
@property (weak, nonatomic) IBOutlet UILabel *typeLabel;
@property (weak, nonatomic) IBOutlet CosmosView *cosmosView;
@property (weak, nonatomic) IBOutlet UILabel *websiteLabel;
@property (weak, nonatomic) IBOutlet UILabel *phoneLabel;

@end

NS_ASSUME_NONNULL_END
