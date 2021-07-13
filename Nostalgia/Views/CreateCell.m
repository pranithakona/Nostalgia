//
//  CreateCell.m
//  Nostalgia
//
//  Created by Pranitha Reddy Kona on 7/11/21.
//

#import "CreateCell.h"

@implementation CreateCell

- (void)setCellWithDestination: (Destination *) destination {
    self.destination = destination;
    self.nameLabel.text = destination.name;
}

- (IBAction)changeFixed:(id)sender {
    
}

@end
