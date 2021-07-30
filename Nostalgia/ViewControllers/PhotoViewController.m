//
//  PhotoViewController.m
//  Nostalgia
//
//  Created by Pranitha Reddy Kona on 7/27/21.
//

#import "PhotoViewController.h"

@interface PhotoViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *photoImageView;

@property (strong, nonatomic) GMSPlacesClient *placesClient;

@end

@implementation PhotoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.placesClient = [GMSPlacesClient sharedClient];
    
    if (self.photoMetaData) {
        [self.placesClient loadPlacePhoto:self.photoMetaData callback:^(UIImage * _Nullable photo, NSError * _Nullable error) {
            if (error == nil) {
                float imageViewHeight = self.photoImageView.frame.size.width/photo.size.width * photo.size.height;
                self.photoImageView.frame = CGRectMake(self.photoImageView.frame.origin.x, self.photoImageView.frame.origin.y, self.photoImageView.frame.size.width, imageViewHeight);
                self.photoImageView.image = photo;
            }
        }];
    } else if (self.photoFile) {
        UIImage *resizedImage = [self resizeImage:self.photoFile withSize:CGSizeMake(self.photoImageView.frame.size.width, 350)];
        self.photoImageView.image = resizedImage;
    }
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

- (IBAction)didDismiss:(id)sender {
    [self dismissViewControllerAnimated:true completion:nil];
}

@end
