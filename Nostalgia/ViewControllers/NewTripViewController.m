//
//  NewTripViewController.m
//  Nostalgia
//
//  Created by Pranitha Reddy Kona on 7/12/21.
//

#import "NewTripViewController.h"
#import "CreateViewController.h"
@import GooglePlaces;

@interface NewTripViewController () <GMSAutocompleteViewControllerDelegate> 

@property (weak, nonatomic) IBOutlet UITextField *nameField;
@property (weak, nonatomic) IBOutlet UITextField *descriptionField;
@property (weak, nonatomic) IBOutlet UIButton *regionButton;
@property (weak, nonatomic) IBOutlet UITextField *startTimeLabel;
@property (weak, nonatomic) IBOutlet UIButton *startLocationButton;


@property (strong, nonatomic) GMSPlace *region;
@property (strong, nonatomic) NSDate *startTime;
@property (strong, nonatomic) GMSPlace *startLocation;
@end

@implementation NewTripViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    UIDatePicker *datePicker = [[UIDatePicker alloc] init];
    //[datePicker setPreferredDatePickerStyle: UIDatePickerStyleInline];
    datePicker.datePickerMode = UIDatePickerModeDateAndTime;
    
    self.startTimeLabel.inputView = datePicker;
    [datePicker addTarget:self action:@selector(dateChanged:) forControlEvents: UIControlEventValueChanged];
}

- (void) dateChanged: (UIDatePicker *) datePicker {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"E MMM d HH:mm:ss Z y";
    NSDate *date = datePicker.date;
    self.startTime = date;
    formatter.dateStyle = NSDateFormatterShortStyle;
    formatter.timeStyle = NSDateFormatterNoStyle;
    NSString *dateString = [formatter stringFromDate:date];

    formatter.dateStyle = NSDateFormatterNoStyle;
    formatter.timeStyle = NSDateFormatterShortStyle;
    NSString *timeString = [formatter stringFromDate:date];
    self.startTimeLabel.text = [NSString stringWithFormat:@"%@ %@", dateString, timeString];
}

- (IBAction)endEditing:(id)sender {
    [self.view endEditing:true];
}

- (IBAction)changeRegion:(id)sender {
    GMSAutocompleteViewController *acController = [[GMSAutocompleteViewController alloc] init];
    acController.delegate = self;

    GMSPlaceField fields = (GMSPlaceFieldName | GMSPlaceFieldPlaceID | GMSPlaceFieldCoordinate);
    acController.placeFields = fields;

    GMSAutocompleteFilter *filter = [[GMSAutocompleteFilter alloc] init];
    filter.type = kGMSPlacesAutocompleteTypeFilterRegion;
    acController.autocompleteFilter = filter;

    [self presentViewController:acController animated:YES completion:nil];
}

- (IBAction)changeStartLocation:(id)sender {
    GMSAutocompleteViewController *acController = [[GMSAutocompleteViewController alloc] init];
    acController.delegate = self;

    GMSPlaceField fields = (GMSPlaceFieldName | GMSPlaceFieldPlaceID | GMSPlaceFieldCoordinate);
    acController.placeFields = fields;

    GMSAutocompleteFilter *filter = [[GMSAutocompleteFilter alloc] init];
    filter.type = kGMSPlacesAutocompleteTypeFilterNoFilter;
    acController.autocompleteFilter = filter;

    [self presentViewController:acController animated:YES completion:nil];
}

- (void)viewController:(GMSAutocompleteViewController *)viewController
    didAutocompleteWithPlace:(GMSPlace *)place {
    [self dismissViewControllerAnimated:YES completion:nil];

    if (viewController.autocompleteFilter.type == kGMSPlacesAutocompleteTypeFilterRegion){
        [self.regionButton setTitle: place.name forState:UIControlStateNormal];
    } else {
        [self.startLocationButton setTitle: place.name forState:UIControlStateNormal];
    }
}

- (void)viewController:(GMSAutocompleteViewController *)viewController
didFailAutocompleteWithError:(NSError *)error {
    [self dismissViewControllerAnimated:YES completion:nil];
    // TODO: handle the error.
    NSLog(@"Error: %@", [error description]);
}

// User canceled the operation.
- (void)wasCancelled:(GMSAutocompleteViewController *)viewController {
[self dismissViewControllerAnimated:YES completion:nil];
}

// Turn the network activity indicator on and off again.
- (void)didRequestAutocompletePredictions:(GMSAutocompleteViewController *)viewController {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

- (void)didUpdateAutocompletePredictions:(GMSAutocompleteViewController *)viewController {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}


#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    CreateViewController *createViewController = [segue destinationViewController];
    createViewController.name = self.nameField.text;
    createViewController.description = self.descriptionField.text;
    createViewController.region = self.region;
    createViewController.startTime = self.startTime;
    createViewController.startLocation = self.startLocation;
}

@end
