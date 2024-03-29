//
//  LoginViewController.m
//  Nostalgia
//
//  Created by Pranitha Reddy Kona on 7/10/21.
//

#import "LoginViewController.h"
#import <Parse/Parse.h>

@interface LoginViewController ()

@property (weak, nonatomic) IBOutlet UITextField *usernameField;
@property (weak, nonatomic) IBOutlet UITextField *passwordField;

@end

@implementation LoginViewController
static const NSString *segue = @"loginSegue";

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (IBAction)onLogin:(id)sender {
    NSString *username = self.usernameField.text;
    NSString *password = self.passwordField.text;
    
    [PFUser logInWithUsernameInBackground:username password:password block:^(PFUser * user, NSError *  error) {
        if (!error) {
            [self performSegueWithIdentifier:segue sender:nil];
        }
    }];
}

- (IBAction)dismissKeyboard:(id)sender {
    [self.passwordField endEditing:true];
    [self.usernameField endEditing:true];
}

@end
