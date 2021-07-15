//
//  SharingViewController.h
//  Nostalgia
//
//  Created by Pranitha Reddy Kona on 7/14/21.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ShareViewControllerDelegate;



@interface ShareViewController : UIViewController

@property (strong, nonatomic) NSMutableArray *arrayOfSharedUsers;
@property (weak, nonatomic) id<ShareViewControllerDelegate> delegate;

@end

@protocol ShareViewControllerDelegate

- (void) didAddUsers:(NSArray *)users;

@end

NS_ASSUME_NONNULL_END
