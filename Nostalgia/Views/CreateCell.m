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
    if (self.fixedSwitch.isOn){
        self.timeLabel.hidden = false;
    } else {
        self.timeLabel.hidden = false;
    }
}

@end
