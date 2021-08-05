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
#import <Parse/PFImageView.h>

@interface ProfileViewController () <UIImagePickerControllerDelegate>

@property (weak, nonatomic) IBOutlet PFImageView *profileImageView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *usernameLabel;
@property (weak, nonatomic) IBOutlet UITextField *nameField;
@property (weak, nonatomic) IBOutlet UIButton *cameraButton;
@property (weak, nonatomic) IBOutlet UIButton *doneButton;
@property (weak, nonatomic) IBOutlet UIButton *editButton;

@property (strong, nonatomic) PFUser *user;
@end

@implementation ProfileViewController
static const NSString *nameKey = @"name";
static const NSString *sbName = @"Main";
static const NSString *vcName = @"LoginViewController";

- (void)viewDidLoad {
    [super viewDidLoad];
    self.nameLabel.text = [PFUser currentUser][nameKey];
    self.usernameLabel.text = [PFUser currentUser].username;
    self.user = [PFUser currentUser];
    
    if (self.user[@"photo"]){
        self.profileImageView.file = self.user[@"photo"];
        [self.profileImageView loadInBackground];
    }
}

- (IBAction)editProfile:(id)sender {
    self.editButton.hidden = true;
    self.doneButton.hidden = false;
    self.cameraButton.hidden = false;
    self.nameLabel.hidden = true;
    self.nameField.hidden = false;
    self.nameField.text = self.user[@"name"];
    
}

- (IBAction)doneEditingProfile:(id)sender {
    self.user[@"name"] = self.nameField.text;
    UIImage *newImage = [self resizeImage:self.profileImageView.image withSize:CGSizeMake(200, 200)];
    self.user[@"photo"] = [self getPFFileFromImage:newImage];
    [self.user saveInBackground];
    
    [self.nameLabel endEditing:true];
    self.nameLabel.text = self.nameField.text;
    self.editButton.hidden = false;
    self.doneButton.hidden = true;
    self.cameraButton.hidden = true;
    self.nameLabel.hidden = false;
    self.nameField.hidden = true;
}

- (IBAction)onLogout:(id)sender {
    [PFUser logOutInBackgroundWithBlock:^(NSError * _Nullable error) {
        SceneDelegate *sceneDelegate = (SceneDelegate *)[UIApplication sharedApplication].connectedScenes.allObjects[0].delegate;
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:sbName bundle:nil];
        LoginViewController *openingViewController = [storyboard instantiateViewControllerWithIdentifier:vcName];
        sceneDelegate.window.rootViewController = openingViewController;
    }];
}

- (PFFileObject *)getPFFileFromImage:(UIImage * _Nullable)image {
    if (!image) {
        return nil;
    }
    NSData *imageData = UIImagePNGRepresentation(image);
    if (!imageData) {
        return nil;
    }
    return [PFFileObject fileObjectWithName:@"image.png" data:imageData];
}

- (UIImage *)resizeImage:(UIImage *)image withSize:(CGSize)size {
    UIImageView *resizeImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];
    
    resizeImageView.contentMode = UIViewContentModeScaleAspectFill;
    resizeImageView.image = image;
    
    UIGraphicsBeginImageContext(size);
    [resizeImageView.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}

- (IBAction)doChangePhoto:(id)sender {
    UIImagePickerController *imagePickerVC = [UIImagePickerController new];
    imagePickerVC.delegate = self;
    imagePickerVC.allowsEditing = YES;
    imagePickerVC.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    [self presentViewController:imagePickerVC animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey,id> *)info {
    UIImage *originalImage = info[UIImagePickerControllerOriginalImage];
    self.profileImageView.image = originalImage;
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
