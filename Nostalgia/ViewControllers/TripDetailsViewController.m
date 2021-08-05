//
//  TripDetailsViewController.m
//  Nostalgia
//
//  Created by Pranitha Reddy Kona on 8/4/21.
//

#import "TripDetailsViewController.h"
#import "ExploreCell.h"
#import "SongCell.h"
#import "TripDetailsHeader.h"
#import "NSDate+NSDateHelper.h"

@interface TripDetailsViewController () <UICollectionViewDelegate, UICollectionViewDataSource, UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

@end

@implementation TripDetailsViewController
static const NSString *cellName = @"ExploreCell";
static const NSString *headerName = @"TripDetailsHeader";
static const NSString *tableCellName = @"SongCell";

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    [self.collectionView registerNib:[UINib nibWithNibName:cellName bundle:nil] forCellWithReuseIdentifier:cellName];
    
    UICollectionViewFlowLayout *layout = self.collectionView.collectionViewLayout;
    layout.minimumLineSpacing = 5;
    layout.minimumInteritemSpacing = 5;
    CGFloat itemWidth = (self.collectionView.frame.size.width - layout.minimumInteritemSpacing)/2;
    layout.itemSize = CGSizeMake(itemWidth, itemWidth);
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    TripDetailsHeader *header = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:headerName forIndexPath:indexPath];
    
    header.nameLabel.text = self.trip.name;
    header.regionLabel.text = self.trip.region;
    header.dateLabel.text = [NSDate dateOnlyString:self.trip.startTime];
    
    header.tableView.delegate = self;
    header.tableView.dataSource = self;
    
    return header;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.trip.photos.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    ExploreCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellName forIndexPath:indexPath];
    cell.nameLabel.hidden = true;
    
    NSArray *photo = self.trip.photos[indexPath.item];
    cell.backgroundImageView.file = photo[0];
    [cell.backgroundImageView loadInBackground];
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.trip.songs.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SongCell *cell = [tableView dequeueReusableCellWithIdentifier:tableCellName];
    NSArray *song = self.trip.songs[indexPath.row];
    
    cell.nameLabel.text = song[0];
    cell.artistLabel.text = song[1];
    
    return cell;
}

@end
