//
//  ProfileViewController.m
//  Nostalgia
//
//  Created by Pranitha Reddy Kona on 7/26/21.
//

#import "ProfileViewController.h"
#import "SceneDelegate.h"
#import "LoginViewController.h"
#import <Parse/Parse.h>

@interface ProfileViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *profileImageView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *usernameLabel;

@end

@implementation ProfileViewController
static const NSString *nameKey = @"name";
static const NSString *sbName = @"Main";
static const NSString *vcName = @"LoginViewController";

- (void)viewDidLoad {
    [super viewDidLoad];
    self.nameLabel.text = [PFUser currentUser][nameKey];
    self.usernameLabel.text = [PFUser currentUser].username;
}

- (IBAction)onLogout:(id)sender {
    [PFUser logOutInBackgroundWithBlock:^(NSError * _Nullable error) {
        SceneDelegate *sceneDelegate = (SceneDelegate *)[UIApplication sharedApplication].connectedScenes.allObjects[0].delegate;
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:sbName bundle:nil];
        LoginViewController *openingViewController = [storyboard instantiateViewControllerWithIdentifier:vcName];
        sceneDelegate.window.rootViewController = openingViewController;
    }];
}

@end
