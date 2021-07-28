//
//  CreateCell.m
//  Nostalgia
//
//  Created by Pranitha Reddy Kona on 7/11/21.
//

#import "CreateCell.h"
#import "DateTools.h"

@implementation CreateCell

- (IBAction)durationChanged:(id)sender {
    NSDate *date = self.durationDatePicker.date;
    NSNumber *duration = @(date.hour * 3600 + date.minute * 60);
    self.destination.duration = duration;
    [self.destination saveInBackground];
}

- (IBAction)startTimeChanged:(id)sender {
    self.destination.time = self.startDatePicker.date;
    self.endDatePicker.minimumDate = self.startDatePicker.date;
    self.destination.duration = @([self.endDatePicker.date secondsFrom:self.startDatePicker.date]);
    [self.destination saveInBackground];
}

- (IBAction)endTimeChanged:(id)sender {
    self.destination.duration = @([self.endDatePicker.date secondsFrom:self.startDatePicker.date]);
    [self.destination saveInBackground];
}

- (IBAction)didDelete:(id)sender {
    [self.delegate deleteCell:self.destination];
}

- (void)setCellWithDestination:(Destination *) destination {
    self.destination = destination;
    self.nameLabel.text = destination.name;
    
    if (destination.duration){
        NSCalendar *calendar = [NSCalendar currentCalendar];
        NSDateComponents *components = [calendar components: NSCalendarUnitYear| NSCalendarUnitMonth| NSCalendarUnitDay fromDate:self.durationDatePicker.date];
        int hours = [destination.duration intValue]/3600;
        int minutes = ([destination.duration intValue]%3600)/60;
        
        [components setHour:hours];
        [components setMinute:minutes];
        self.durationDatePicker.date = [calendar dateFromComponents:components];
    }
}

@end
