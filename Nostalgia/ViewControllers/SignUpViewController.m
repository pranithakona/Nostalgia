//
//  SignUpViewController.m
//  Nostalgia
//
//  Created by Pranitha Reddy Kona on 7/10/21.
//

#import "SignUpViewController.h"
#import <Parse/Parse.h>

@interface SignUpViewController ()

@property (weak, nonatomic) IBOutlet UITextField *usernameField;
@property (weak, nonatomic) IBOutlet UITextField *emailField;
@property (weak, nonatomic) IBOutlet UITextField *passwordField;

@end

@implementation SignUpViewController
static const NSString *segue = @"signupSegue";

- (IBAction)onSignup:(id)sender {
    PFUser *newUser = [PFUser user];
    newUser.username = self.usernameField.text;
    newUser.email = self.emailField.text;
    newUser.password = self.passwordField.text;
    newUser[@"name"] = self.usernameField.text;
    newUser[@"trips"] = [NSMutableArray array];
   
    [newUser signUpInBackgroundWithBlock:^(BOOL succeeded, NSError * error) {
        if (!error) {
            [self performSegueWithIdentifier:segue sender:nil];
        }
    }];
}

@end
