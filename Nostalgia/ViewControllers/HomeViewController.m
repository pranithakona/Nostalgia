//
//  HomeViewController.m
//  Nostalgia
//
//  Created by Pranitha Reddy Kona on 7/10/21.
//

#import "HomeViewController.h"
#import "LoginViewController.h"
#import "MapViewController.h"
#import "NewTripViewController.h"
#import "SceneDelegate.h"
#import "Trip.h"
#import "DateTools.h"
#import "HomeCell.h"
@import Parse;

@interface HomeViewController () <UICollectionViewDelegate, UICollectionViewDataSource>

@property (weak, nonatomic) IBOutlet UICollectionView *futureCollectionView;
@property (weak, nonatomic) IBOutlet UICollectionView *pastCollectionView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

@property (strong, nonatomic) NSMutableArray *futureTrips;
@property (strong, nonatomic) NSMutableArray *pastTrips;

@end

@implementation HomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.futureCollectionView.delegate = self;
    self.futureCollectionView.dataSource = self;
    self.pastCollectionView.delegate = self;
    self.pastCollectionView.dataSource = self;
    
    [self.futureCollectionView registerNib:[UINib nibWithNibName:@"HomeCell" bundle:nil] forCellWithReuseIdentifier:@"HomeCell"];
    [self.pastCollectionView registerNib:[UINib nibWithNibName:@"HomeCell" bundle:nil] forCellWithReuseIdentifier:@"HomeCell"];
    
    UICollectionViewFlowLayout *layout = [self.futureCollectionView collectionViewLayout];
    layout.minimumLineSpacing = 5;
    layout.minimumInteritemSpacing = 5;
    CGFloat itemHeight = self.futureCollectionView.frame.size.height;
    layout.itemSize = CGSizeMake(itemHeight, itemHeight);
    
    UICollectionViewFlowLayout *layout2 = [self.pastCollectionView collectionViewLayout];
    layout2.minimumLineSpacing = 5;
    layout2.minimumInteritemSpacing = 5;
    CGFloat itemHeight2 = self.pastCollectionView.frame.size.height;
    layout2.itemSize = CGSizeMake(itemHeight2, itemHeight2);
    
    self.futureTrips = [NSMutableArray array];
    self.pastTrips = [NSMutableArray array];
    
    [self.activityIndicator startAnimating];
    NSDate *now = [NSDate now];
    for (Trip *trip in [PFUser currentUser][@"trips"]){
        [trip fetchIfNeeded];
        if ([trip.startTime isEarlierThanOrEqualTo:now]){
            [self.pastTrips addObject:trip];
        } else {
            [self.futureTrips addObject:trip];
        }
    }
    [self.activityIndicator stopAnimating];
}

- (IBAction)onLogout:(id)sender {
    [PFUser logOutInBackgroundWithBlock:^(NSError * _Nullable error) {
        SceneDelegate *sceneDelegate = (SceneDelegate *)[UIApplication sharedApplication].connectedScenes.allObjects[0].delegate;
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        LoginViewController *openingViewController = [storyboard instantiateViewControllerWithIdentifier:@"LoginViewController"];
        sceneDelegate.window.rootViewController = openingViewController;
    }];
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    NSArray *data = [collectionView.restorationIdentifier isEqualToString: @"futureCollectionView"] ? self.futureTrips : self.pastTrips;
    Trip *trip = data[indexPath.item];
    [self performSegueWithIdentifier:@"tripDetailsSegue" sender:trip];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [collectionView.restorationIdentifier isEqualToString: @"futureCollectionView"] ? self.futureTrips.count : self.pastTrips.count;
    
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    NSArray *data = [collectionView.restorationIdentifier isEqualToString: @"futureCollectionView"] ? self.futureTrips : self.pastTrips;
    
    HomeCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"HomeCell" forIndexPath:indexPath];
    
    if (cell == nil) {
            NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"HomeCell" owner:self options:nil];
            cell = [topLevelObjects objectAtIndex:0];
    }
    
    Trip *trip = data[indexPath.item];
    cell.nameLabel.text = trip.name;
    
    [cell setNeedsLayout];
    [cell layoutIfNeeded];
    
    return cell;
}


#pragma mark - Navigation


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"tripDetailsSegue"]){
        MapViewController *mapViewController = [segue destinationViewController];
        mapViewController.trip = sender;
        mapViewController.isNewTrip = false;
    } else if ([segue.identifier isEqualToString:@"newTripSegue"]){
        NewTripViewController *newTripViewController = [segue destinationViewController];
        newTripViewController.isNewTrip = true;
    }
}


@end
