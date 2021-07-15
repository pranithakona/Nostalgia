//
//  SharingViewController.h
//  Nostalgia
//
//  Created by Pranitha Reddy Kona on 7/14/21.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol SharingViewControllerDelegate;



@interface SharingViewController : UIViewController

@property (strong, nonatomic) NSMutableArray *arrayOfSharedUsers;
@property (weak, nonatomic) id<SharingViewControllerDelegate> delegate;

@end

@protocol SharingViewControllerDelegate

- (void) didAddUsers:(NSArray *)users;

@end

NS_ASSUME_NONNULL_END
