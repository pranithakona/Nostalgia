//
//  DetailsViewController.m
//  Nostalgia
//
//  Created by Pranitha Reddy Kona on 7/28/21.
//

#import "DetailsViewController.h"
#import "DestinationHeader.h"
#import "ExploreCell.h"

@interface DetailsViewController () <UICollectionViewDelegate, UICollectionViewDataSource>
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

@end

@implementation DetailsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    [self.collectionView registerNib:[UINib nibWithNibName:@"ExploreCell" bundle:nil] forCellWithReuseIdentifier:@"ExploreCell"];
    
    self.collectionView.collectionViewLayout = [self generateLayout];
}

- (UICollectionViewLayout *)generateLayout {
    //item sizes
    NSCollectionLayoutItem *largeItem = [NSCollectionLayoutItem itemWithLayoutSize:[NSCollectionLayoutSize sizeWithWidthDimension:[NSCollectionLayoutDimension fractionalWidthDimension:1.0] heightDimension:[NSCollectionLayoutDimension fractionalWidthDimension:(1 - 1/3)]]];
    largeItem.contentInsets = NSDirectionalEdgeInsetsMake(2, 2, 2, 2);
    
    NSCollectionLayoutItem *mediumItem = [NSCollectionLayoutItem itemWithLayoutSize:[NSCollectionLayoutSize sizeWithWidthDimension:[NSCollectionLayoutDimension fractionalWidthDimension:(1 - 1/3)] heightDimension:[NSCollectionLayoutDimension fractionalHeightDimension:1.0]]];
    mediumItem.contentInsets = NSDirectionalEdgeInsetsMake(2, 2, 2, 2);
    
    NSCollectionLayoutItem *smallItem = [NSCollectionLayoutItem itemWithLayoutSize:[NSCollectionLayoutSize sizeWithWidthDimension:[NSCollectionLayoutDimension fractionalWidthDimension:1.0] heightDimension:[NSCollectionLayoutDimension fractionalHeightDimension:0.5]]];
    smallItem.contentInsets = NSDirectionalEdgeInsetsMake(2, 2, 2, 2);
    
    NSCollectionLayoutItem *tripletItem = [NSCollectionLayoutItem itemWithLayoutSize:[NSCollectionLayoutSize sizeWithWidthDimension:[NSCollectionLayoutDimension fractionalWidthDimension:(1 - 2/3)] heightDimension:[NSCollectionLayoutDimension fractionalHeightDimension:1.0]]];
    tripletItem.contentInsets = NSDirectionalEdgeInsetsMake(2, 2, 2, 2);
    
    //first layout
    NSCollectionLayoutGroup *trailingGroup = [NSCollectionLayoutGroup verticalGroupWithLayoutSize:[NSCollectionLayoutSize sizeWithWidthDimension:[NSCollectionLayoutDimension fractionalWidthDimension:(1 - 2/3)] heightDimension:[NSCollectionLayoutDimension fractionalHeightDimension:1.0]] subitem:smallItem count:2];
    
    //second layout
    NSCollectionLayoutGroup *mainGroup = [NSCollectionLayoutGroup horizontalGroupWithLayoutSize:[NSCollectionLayoutSize sizeWithWidthDimension:[NSCollectionLayoutDimension fractionalWidthDimension:1.0] heightDimension:[NSCollectionLayoutDimension fractionalWidthDimension:(1 - 5/9)]] subitems:@[mediumItem, trailingGroup]];
    
    NSCollectionLayoutGroup *mainGroupReversed = [NSCollectionLayoutGroup horizontalGroupWithLayoutSize:[NSCollectionLayoutSize sizeWithWidthDimension:[NSCollectionLayoutDimension fractionalWidthDimension:1.0] heightDimension:[NSCollectionLayoutDimension fractionalWidthDimension:(1 - 5/9)]] subitems:@[trailingGroup, mediumItem]];
    
    //third layout
    NSCollectionLayoutGroup *tripletGroup = [NSCollectionLayoutGroup horizontalGroupWithLayoutSize:[NSCollectionLayoutSize sizeWithWidthDimension:[NSCollectionLayoutDimension fractionalWidthDimension:1.0] heightDimension:[NSCollectionLayoutDimension fractionalWidthDimension:(1 - 7/9)]] subitems:@[tripletItem, tripletItem, tripletItem]];

    //combined layout
    NSCollectionLayoutGroup *nestedGroup = [NSCollectionLayoutGroup verticalGroupWithLayoutSize:[NSCollectionLayoutSize sizeWithWidthDimension:[NSCollectionLayoutDimension fractionalWidthDimension:1.0] heightDimension:[NSCollectionLayoutDimension fractionalWidthDimension:(1 + 7/9)]] subitems:@[ tripletGroup]];
    
    NSCollectionLayoutSection *section = [NSCollectionLayoutSection sectionWithGroup:nestedGroup];
    
    UICollectionViewCompositionalLayout *layout = [[UICollectionViewCompositionalLayout alloc] initWithSection:section];
    return layout;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
    //return self.destination.photos.count/10;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.destination.photos.count;
    //return (section + 1) * 10 > self.destination.photos.count ? self.destination.photos.count % 10 : 10;
    
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    ExploreCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"ExploreCell" forIndexPath:indexPath];
    cell.nameLabel.hidden = true;
    
    //int index = indexPath.section * 10 + indexPath.item;
    PFFileObject *imageFile = self.destination.photos[indexPath.item];
    [imageFile getDataInBackgroundWithBlock:^(NSData *imageData, NSError *error) {
        if (!error) {
            cell.backgroundImageView.image = [UIImage imageWithData:imageData];
        }
    }];
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    DestinationHeader *header = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"DestinationHeader" forIndexPath:indexPath];
    header.nameLabel.text = self.destination.name;
    return header;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
