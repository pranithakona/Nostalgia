//
//  ExploreFilterHeader.h
//  Nostalgia
//
//  Created by Pranitha Reddy Kona on 7/26/21.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ExploreFilterHeaderDelegate

- (void)filterByType:(NSString *)type;

@end

@interface ExploreFilterHeader : UICollectionReusableView

@property (weak, nonatomic) id<ExploreFilterHeaderDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
