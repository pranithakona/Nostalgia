//
//  CreateCell.m
//  Nostalgia
//
//  Created by Pranitha Reddy Kona on 7/11/21.
//

#import "CreateCell.h"
#import "DateTools.h"

@implementation CreateCell

- (void)awakeFromNib{
    [super awakeFromNib];
    self.datePicker = [[UIDatePicker alloc] init];
    self.datePicker.datePickerMode = UIDatePickerModeTime;
    [self.datePicker setPreferredDatePickerStyle: UIDatePickerStyleInline];
    [self.datePicker addTarget:self action:@selector(dateChanged:) forControlEvents: UIControlEventValueChanged];
    [self.datePicker setLocale:[NSLocale localeWithLocaleIdentifier:@"en_GB"]];
    
    CGSize datePickerSize = [self.datePicker sizeThatFits:CGSizeZero];
    self.datePicker.frame = CGRectMake(10,100, datePickerSize.width, datePickerSize.height);
    [self.contentView addSubview:self.datePicker];
    
}

- (void)dateChanged:(UIDatePicker *) datePicker {
    NSDate *date = datePicker.date;
    NSNumber *duration = [NSNumber numberWithLong:(date.hour * 3600 + date.minute * 60)];
    
    self.destination.duration = duration;
    [self.destination saveInBackground];
}

- (IBAction)didDelete:(id)sender {
    [self.delegate deleteCell:self.destination];
}

- (void)setCellWithDestination:(Destination *) destination {
    self.destination = destination;
    self.nameLabel.text = destination.name;
}


@end
