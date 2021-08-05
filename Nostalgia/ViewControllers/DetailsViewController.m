//
//  DetailsViewController.m
//  Nostalgia
//
//  Created by Pranitha Reddy Kona on 7/28/21.
//

#import "DetailsViewController.h"
#import "DestinationHeader.h"
#import "ExploreCell.h"
#import "NSDate+NSDateHelper.h"
#import "DateTools.h"

@interface DetailsViewController () <UICollectionViewDelegate, UICollectionViewDataSource>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

@end

@implementation DetailsViewController
static const NSString *cellName = @"ExploreCell";
static const NSString *headerName = @"DestinationHeader";

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    [self.collectionView registerNib:[UINib nibWithNibName:cellName bundle:nil] forCellWithReuseIdentifier:cellName];
    
    UICollectionViewFlowLayout *layout = [self.collectionView collectionViewLayout];
    layout.minimumLineSpacing = 5;
    layout.minimumInteritemSpacing = 5;
    CGFloat itemWidth = self.collectionView.frame.size.width;
    layout.itemSize = CGSizeMake(itemWidth, 350);
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.destination.photos.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    ExploreCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellName forIndexPath:indexPath];
    cell.nameLabel.hidden = true;
    
    PFFileObject *imageFile = self.destination.photos[indexPath.item];
    [imageFile getDataInBackgroundWithBlock:^(NSData *imageData, NSError *error) {
        if (!error) {
            cell.backgroundImageView.image = [UIImage imageWithData:imageData];
        }
    }];
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    DestinationHeader *header = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:headerName forIndexPath:indexPath];
    header.nameLabel.text = self.destination.name;
    NSString *dateString = [NSDate timeOnlyString:self.destination.time];
    if (self.destination.duration && [self.destination.duration longValue] != 0){
        NSString *dateEndString = [NSDate timeOnlyString:[self.destination.time dateByAddingSeconds:[self.destination.duration longValue]]];
        header.timeLabel.text = [NSString stringWithFormat: @"%@ - %@",dateString, dateEndString];
    } else {
        header.timeLabel.text = dateString;
    }
    return header;
}

@end
