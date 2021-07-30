//
//  SceneDelegate.h
//  Nostalgia
//
//  Created by Pranitha Reddy Kona on 7/10/21.
//

#import <UIKit/UIKit.h>

@interface SceneDelegate : UIResponder <UIWindowSceneDelegate>

@property (strong, nonatomic) UIWindow *window;

+ (NSArray *)getCurrentTripSongs;
+ (void)clearCurrentTripSongs;
+ (void)setIsCurrentlyRouting:(BOOL)isRouting;

@end

