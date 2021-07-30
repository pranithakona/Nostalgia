//
//  SceneDelegate.m
//  Nostalgia
//
//  Created by Pranitha Reddy Kona on 7/10/21.
//

#import "SceneDelegate.h"
#import "AppDelegate.h"
#import "HomeViewController.h"
@import Parse;

@interface SceneDelegate () <SPTSessionManagerDelegate, SPTAppRemoteDelegate, SPTAppRemotePlayerStateDelegate>

@property (strong, nonatomic) SPTSessionManager *sessionManager;
@property (strong, nonatomic) SPTConfiguration *configuration;
@property (strong, nonatomic) SPTAppRemote *appRemote;

@end

@implementation SceneDelegate
static NSMutableArray<NSArray *> *currentTripSongs;
static NSMutableSet<NSString *> *songNames;
static BOOL isCurrentlyRouting;

- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)connectionOptions {
    if (PFUser.currentUser) {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        self.window.rootViewController = [storyboard instantiateViewControllerWithIdentifier:@"HomeTabBarController"];
    }
    
    //spotify
    NSString *spotifyClientID = @"077bd8cb70884d9b8c1f8d18b316e735";
    NSURL *spotifyRedirectURL = [NSURL URLWithString:@"spotify-ios-quick-start://spotify-login-callback"];

    self.configuration  = [[SPTConfiguration alloc] initWithClientID:spotifyClientID redirectURL:spotifyRedirectURL];
    
    NSURL *tokenSwapURL = [NSURL URLWithString:@"https://nostalgiafbu.herokuapp.com/api/token"];
    NSURL *tokenRefreshURL = [NSURL URLWithString:@"https://nostalgiafbu.herokuapp.com/api/refresh_token"];

    self.configuration.tokenSwapURL = tokenSwapURL;
    self.configuration.tokenRefreshURL = tokenRefreshURL;
    self.configuration.playURI = @"";

    self.sessionManager = [[SPTSessionManager alloc] initWithConfiguration:self.configuration delegate:self];
    
    SPTScope requestedScope = SPTAppRemoteControlScope;
    [self.sessionManager initiateSessionWithScope:requestedScope options:SPTDefaultAuthorizationOption];
    
    self.appRemote = [[SPTAppRemote alloc] initWithConfiguration:self.configuration logLevel:SPTAppRemoteLogLevelDebug];
    self.appRemote.delegate = self;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        currentTripSongs = [NSMutableArray array];
        songNames = [NSMutableSet set];
    });
}

- (void)scene:(UIScene *)scene openURLContexts:(NSSet<UIOpenURLContext *> *)URLContexts {
    [self.sessionManager application:[UIApplication sharedApplication] openURL:URLContexts.allObjects.firstObject.URL options:@{}];
}

+ (NSArray *)getCurrentTripSongs {
    return currentTripSongs;
}

+ (void)clearCurrentTripSongs {
    [currentTripSongs removeAllObjects];
    [songNames removeAllObjects];
}

+ (void)setIsCurrentlyRouting:(BOOL)isRouting {
    isCurrentlyRouting = isRouting;
}

#pragma mark - Spotify

- (void)sessionManager:(SPTSessionManager *)manager didInitiateSession:(SPTSession *)session {
    self.appRemote.connectionParameters.accessToken = session.accessToken;
    [self.appRemote connect];
}

- (void)sessionManager:(SPTSessionManager *)manager didFailWithError:(NSError *)error {
}

- (void)sessionManager:(SPTSessionManager *)manager didRenewSession:(SPTSession *)session {
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {
    [self.sessionManager application:app openURL:url options:options];
    return true;
}

- (void)appRemoteDidEstablishConnection:(SPTAppRemote *)appRemote {
  self.appRemote.playerAPI.delegate = self;
  [self.appRemote.playerAPI subscribeToPlayerState:nil];
}

- (void)appRemote:(SPTAppRemote *)appRemote didDisconnectWithError:(NSError *)error {
}

- (void)appRemote:(SPTAppRemote *)appRemote didFailConnectionAttemptWithError:(NSError *)error {
}

- (void)playerStateDidChange:(id<SPTAppRemotePlayerState>)playerState {
    NSLog(@"Track name: %@", playerState.track.name);
    if (isCurrentlyRouting && ![songNames containsObject:playerState.track.name]){
        [currentTripSongs addObject:@[playerState.track.name, playerState.track.artist.name]];
        [songNames addObject:playerState.track.name];
    }
}

- (void)sceneDidDisconnect:(UIScene *)scene {
    // Called as the scene is being released by the system.
    // This occurs shortly after the scene enters the background, or when its session is discarded.
    // Release any resources associated with this scene that can be re-created the next time the scene connects.
    // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
}


- (void)sceneDidBecomeActive:(UIScene *)scene {
    if (self.appRemote.connectionParameters.accessToken) {
        [self.appRemote connect];
    }
}


- (void)sceneWillResignActive:(UIScene *)scene {
    if (self.appRemote.isConnected) {
      [self.appRemote disconnect];
    }
}


- (void)sceneWillEnterForeground:(UIScene *)scene {
    // Called as the scene transitions from the background to the foreground.
    // Use this method to undo the changes made on entering the background.
}


- (void)sceneDidEnterBackground:(UIScene *)scene {
    // Called as the scene transitions from the foreground to the background.
    // Use this method to save data, release shared resources, and store enough scene-specific state information
    // to restore the scene back to its current state.
}


@end
