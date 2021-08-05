//
//  SharingViewController.m
//  Nostalgia
//
//  Created by Pranitha Reddy Kona on 7/14/21.
//

#import "ShareViewController.h"
#import "ShareCell.h"
#import <Parse/Parse.h>

@interface ShareViewController () <UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate>

@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UIView *sharedWithView;
@property (weak, nonatomic) IBOutlet UILabel *sharedUsersLabel;

@property (strong, nonatomic) NSArray<PFUser *> *arrayOfUsers;
@property (strong, nonatomic) NSArray<PFUser *> *filteredArrayOfUsers;

@end

@implementation ShareViewController
static const NSString *nameKey = @"name";
static const NSString *cellName = @"ShareCell";

- (void)viewDidLoad {
    [super viewDidLoad];
   
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.searchBar.delegate = self;
    [self.activityIndicator startAnimating];
    [self fetchUsers];
    
    self.filteredArrayOfUsers = self.arrayOfUsers;
    if (self.arrayOfSharedUsers.count != 0){
        NSString *sharedUsers = @"";
        for (PFUser *user in self.arrayOfSharedUsers){
            sharedUsers = [sharedUsers stringByAppendingString:[NSString stringWithFormat:@"%@, ",user[nameKey]]];
        }
        self.sharedUsersLabel.text = [sharedUsers substringToIndex:sharedUsers.length-2];
    } else {
        self.sharedWithView.hidden = true;
    }
}

- (void)fetchUsers {
    PFQuery *query = [PFQuery queryWithClassName:@"_User"];
    query.limit = 20;
    [query includeKey:@"username"];
    [query includeKey:@"name"];
    [query includeKey:@"trips"];
    [query includeKey:@"photo"];
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *users, NSError *error) {
        if (users != nil) {
            self.arrayOfUsers = users;
            self.filteredArrayOfUsers = self.arrayOfUsers;
            [self.tableView reloadData];
            [self.activityIndicator stopAnimating];
        }
    }];
}

- (IBAction)didCancel:(id)sender {
    [self dismissViewControllerAnimated:true completion:nil];
}

- (IBAction)didDone:(id)sender {
    [self.delegate didAddUsers:self.arrayOfSharedUsers];
    [self dismissViewControllerAnimated:true completion:nil];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    if (searchText) {
        if (searchText.length != 0) {
            NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(PFUser *evaluatedObject, NSDictionary *bindings) {
                return [evaluatedObject.username containsString:searchText] || [evaluatedObject[nameKey] containsString:searchText];
            }];
            self.filteredArrayOfUsers = [self.arrayOfUsers filteredArrayUsingPredicate:predicate];
        } else {
            self.filteredArrayOfUsers = self.arrayOfUsers;
        }
        [self.tableView reloadData];
    }
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    searchBar.showsCancelButton = YES;
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    searchBar.showsCancelButton = NO;
    searchBar.text = @"";
    [searchBar resignFirstResponder];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.filteredArrayOfUsers.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ShareCell *cell = [tableView dequeueReusableCellWithIdentifier:cellName];
    PFUser *user = self.filteredArrayOfUsers[indexPath.row];
    cell.nameLabel.text = user[nameKey];
    cell.userNameLabel.text = user.username;
    if (user[@"photo"]) {
        cell.profileImageView.file = user[@"photo"];
        [cell.profileImageView loadInBackground];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    PFUser *user = self.filteredArrayOfUsers[indexPath.row];
    [self.arrayOfSharedUsers addObject:user];
    self.sharedWithView.hidden = false;
    if ([self.sharedUsersLabel.text isEqualToString:@""]){
        self.sharedUsersLabel.text = [self.sharedUsersLabel.text stringByAppendingString: user[nameKey]];
    } else {
        self.sharedUsersLabel.text = [self.sharedUsersLabel.text stringByAppendingString:[NSString stringWithFormat:@", %@", user[nameKey]]];
    }
}

@end
