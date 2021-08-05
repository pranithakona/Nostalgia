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
static const NSString *tokenURLString = @"https://nostalgiafbu.herokuapp.com/api/token";
static const NSString *tokenRefreshURLString = @"https://nostalgiafbu.herokuapp.com/api/refresh_token";
static const NSString *redirectURLString = @"spotify-ios-quick-start://spotify-login-callback";
static const NSString *clientID = @"077bd8cb70884d9b8c1f8d18b316e735";

- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)connectionOptions {
    if (PFUser.currentUser) {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        self.window.rootViewController = [storyboard instantiateViewControllerWithIdentifier:@"HomeNavigationController"];
    }
    
    //spotify
    NSString *spotifyClientID = clientID;
    NSURL *spotifyRedirectURL = [NSURL URLWithString:redirectURLString];
    NSURL *tokenSwapURL = [NSURL URLWithString:tokenURLString];
    NSURL *tokenRefreshURL = [NSURL URLWithString:tokenRefreshURLString];
    
    self.configuration  = [[SPTConfiguration alloc] initWithClientID:spotifyClientID redirectURL:spotifyRedirectURL];
    self.configuration.tokenSwapURL = tokenSwapURL;
    self.configuration.tokenRefreshURL = tokenRefreshURL;
    self.configuration.playURI = @"";

    SPTScope requestedScope = SPTAppRemoteControlScope;
    self.sessionManager = [[SPTSessionManager alloc] initWithConfiguration:self.configuration delegate:self];
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
    if (isCurrentlyRouting && ![songNames containsObject:playerState.track.name]){
        [currentTripSongs addObject:@[playerState.track.name, playerState.track.artist.name]];
        [songNames addObject:playerState.track.name];
    }
}

- (void)sceneDidDisconnect:(UIScene *)scene {
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
}


- (void)sceneDidEnterBackground:(UIScene *)scene {
}


@end
