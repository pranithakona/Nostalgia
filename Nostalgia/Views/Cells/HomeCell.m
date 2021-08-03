//
//  HomeCell.m
//  Nostalgia
//
//  Created by Pranitha Reddy Kona on 7/14/21.
//

#import "HomeCell.h"

@implementation HomeCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.cardView.layer.cornerRadius = 15;
    self.backgroundImageView.layer.cornerRadius = 15;
}

@end
