//
//  AppDelegate.m
//  Nostalgia
//
//  Created by Pranitha Reddy Kona on 7/10/21.
//

#import "AppDelegate.h"
#import "LocationManager.h"
#import <Parse/Parse.h>
#import <GoogleMaps/GoogleMaps.h>
#import <GooglePlaces/GooglePlaces.h>

@interface AppDelegate ()

@end

@implementation AppDelegate
static const NSString *serverURL = @"https://parseapi.back4app.com";

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    //parse
    ParseClientConfiguration *config = [ParseClientConfiguration  configurationWithBlock:^(id<ParseMutableClientConfiguration> configuration) {
        configuration.applicationId = @"IAioHjmgQ6wfFrvPJrIwSKflA3gEBfJ7qX0N3iOC";
        configuration.clientKey = @"8uynhUVAPUt0MINZrH3CH9gNUMoIcROV6zO7iCBe";
        configuration.server = serverURL;
    }];

    [Parse initializeWithConfiguration:config];
    
    NSString *path = [[NSBundle mainBundle] pathForResource: @"Keys" ofType: @"plist"];
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile: path];
    NSString *key= [dict objectForKey: @"API_Key"];
    
    //google
    [GMSServices provideAPIKey:key];
    [GMSPlacesClient provideAPIKey:key];
    
    //location manager
    CLLocationManager *locationManager = [LocationManager shared];
    [locationManager requestAlwaysAuthorization];

    return YES;
}

#pragma mark - UISceneSession lifecycle

- (UISceneConfiguration *)application:(UIApplication *)application configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession options:(UISceneConnectionOptions *)options {
    // Called when a new scene session is being created.
    // Use this method to select a configuration to create the new scene with.
    return [[UISceneConfiguration alloc] initWithName:@"Default Configuration" sessionRole:connectingSceneSession.role];
}


- (void)application:(UIApplication *)application didDiscardSceneSessions:(NSSet<UISceneSession *> *)sceneSessions {
    // Called when the user discards a scene session.
    // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
    // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
}


@end
