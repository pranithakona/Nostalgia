//
//  NewTripViewController.m
//  Nostalgia
//
//  Created by Pranitha Reddy Kona on 7/12/21.
//

#import "NewTripViewController.h"
#import "CreateViewController.h"
#import "Destination.h"
#import <GooglePlaces/GooglePlaces.h>

@interface NewTripViewController () <GMSAutocompleteViewControllerDelegate> 

@property (weak, nonatomic) IBOutlet UITextField *nameField;
@property (weak, nonatomic) IBOutlet UITextField *descriptionField;
@property (weak, nonatomic) IBOutlet UIButton *regionButton;
@property (weak, nonatomic) IBOutlet UIButton *startLocationButton;
@property (weak, nonatomic) IBOutlet UIButton *endLocationButton;
@property (weak, nonatomic) IBOutlet UIButton *nextButton;
@property (weak, nonatomic) IBOutlet UIDatePicker *datePicker;


@property (strong, nonatomic) GMSPlace *region;
@property (strong, nonatomic) NSDate *startTime;
@property (strong, nonatomic) GMSPlace *startLocation;
@property (strong, nonatomic) GMSPlace *endLocation;
@property (assign, nonatomic) BOOL isEditingStartLocation;

@end

@implementation NewTripViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.startTime = self.datePicker.date;
    self.nextButton.enabled = [self requiredFields];
    
    //set fields with existing descriptions if is an existing trip
    if (!self.isNewTrip) {
        self.nameField.text = self.trip.name;
        self.descriptionField.text = self.trip.tripDescription;
        [self.regionButton setTitle:self.trip.region forState:UIControlStateNormal];
        self.datePicker.date = self.startTime;
        [self.startLocationButton setTitle:self.trip.startLocation.name forState:UIControlStateNormal];
        [self.endLocationButton setTitle:self.trip.endLocation.name forState:UIControlStateNormal];
        self.nextButton.hidden = true;
    }
    
    self.datePicker.minimumDate = [NSDate now];
}

- (BOOL)requiredFields {
    //commented out for testing purposes
    //return (![self.nameField.text isEqualToString:@""] && self.startTime && self.region && self.startLocation && self.endLocation) || (![self.nameField.text isEqualToString:@""] && !self.isNewTrip);
    return true;
}

- (IBAction)dateChanged:(id)sender {
    self.datePicker.minimumDate = [NSDate now];
    self.startTime = self.datePicker.date;
    self.nextButton.enabled = [self requiredFields];
    if (!self.isNewTrip){
        self.trip.startTime = self.startTime;
        [self.trip saveInBackground];
    }
}

- (IBAction)nameChanged:(id)sender {
    self.nextButton.enabled = [self requiredFields];
}

- (IBAction)nameEditingEnded:(id)sender {
    if (!self.isNewTrip){
        self.trip.name = self.nameField.text;
        [self.trip saveInBackground];
    }
}

- (IBAction)changeRegion:(id)sender {
    [self createPlacesViewControllerWithFilter:kGMSPlacesAutocompleteTypeFilterRegion];
    self.nextButton.enabled = [self requiredFields];
    if (!self.isNewTrip) {
        self.trip.region = self.region.name;
        self.trip.region = self.region.placeID;
        [self.trip saveInBackground];
    }
}

- (IBAction)changeStartLocation:(id)sender {
    self.isEditingStartLocation = true;
    [self createPlacesViewControllerWithFilter:kGMSPlacesAutocompleteTypeFilterNoFilter];
    self.nextButton.enabled = [self requiredFields];
    
    if (!self.isNewTrip) {
        [self.trip.startLocation deleteInBackground];
        [Destination postDestination:self.startLocation withCompletion:^(Destination * _Nullable dest, NSError * _Nullable error) {
            if (!error){
                self.trip.startLocation = dest;
            }
        }];
        [self.trip saveInBackground];
    }
}

- (IBAction)changeEndLocation:(id)sender {
    self.isEditingStartLocation = false;
    [self createPlacesViewControllerWithFilter:kGMSPlacesAutocompleteTypeFilterNoFilter];
    self.nextButton.enabled = [self requiredFields];
    
    if (!self.isNewTrip) {
        [self.trip.endLocation deleteInBackground];
        [Destination postDestination:self.endLocation withCompletion:^(Destination * _Nullable dest, NSError * _Nullable error) {
            if (!error){
                self.trip.endLocation = dest;
            }
        }];
        [self.trip saveInBackground];
    }
}

#pragma mark - Google Places

- (void)createPlacesViewControllerWithFilter:(GMSPlacesAutocompleteTypeFilter)type {
    GMSAutocompleteViewController *acController = [[GMSAutocompleteViewController alloc] init];
    acController.delegate = self;
    
    GMSPlaceField fields = (GMSPlaceFieldName | GMSPlaceFieldPlaceID | GMSPlaceFieldCoordinate);
    acController.placeFields = fields;

    GMSAutocompleteFilter *filter = [[GMSAutocompleteFilter alloc] init];
    filter.type = type;
    acController.autocompleteFilter = filter;

    [self presentViewController:acController animated:YES completion:nil];
}

- (void)viewController:(GMSAutocompleteViewController *)viewController
    didAutocompleteWithPlace:(GMSPlace *)place {
    [self dismissViewControllerAnimated:YES completion:nil];

    if (viewController.autocompleteFilter.type == kGMSPlacesAutocompleteTypeFilterRegion){
        [self.regionButton setTitle: place.name forState:UIControlStateNormal];
        self.region = place;
    } else {
        if (self.isEditingStartLocation){
            [self.startLocationButton setTitle: place.name forState:UIControlStateNormal];
            self.startLocation = place;
        } else {
            [self.endLocationButton setTitle: place.name forState:UIControlStateNormal];
            self.endLocation = place;
        }
    }
    self.nextButton.enabled = [self requiredFields];
}

- (void)viewController:(GMSAutocompleteViewController *)viewController didFailAutocompleteWithError:(NSError *)error {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)wasCancelled:(GMSAutocompleteViewController *)viewController {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)didRequestAutocompletePredictions:(GMSAutocompleteViewController *)viewController {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

- (void)didUpdateAutocompletePredictions:(GMSAutocompleteViewController *)viewController {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    CreateViewController *createViewController = [segue destinationViewController];
    //save start and end locations as new destinations and pass trip info to next screen
    if (self.isNewTrip) {
        [Destination postDestination:self.startLocation withCompletion:^(Destination * _Nullable dest, NSError * _Nullable error) {
            if (!error){
                dest.duration = @0;
                [dest saveInBackground];
                createViewController.startLocation = dest;
            }
        }];
        
        [Destination postDestination:self.endLocation withCompletion:^(Destination * _Nullable dest, NSError * _Nullable error) {
            if (!error){
                dest.duration = @0;
                [dest saveInBackground];
                createViewController.endLocation = dest;
            }
        }];
        
        createViewController.name = self.nameField.text;
        createViewController.tripDescription = self.descriptionField.text;
        createViewController.region = self.region;
        createViewController.startTime = self.startTime;
        createViewController.isNewTrip = true;
    } 
}

@end
