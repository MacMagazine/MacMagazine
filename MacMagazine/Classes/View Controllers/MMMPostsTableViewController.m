#import <PureLayout/PureLayout.h>
#import <TSMessages/TSMessage.h>

#import "MMMPostsTableViewController.h"
#import "MMMFeaturedPostTableViewCell.h"
#import "MMMLabel.h"
#import "MMMLogoImageView.h"
#import "MMMPost.h"
#import "MMMPostDetailViewController.h"
#import "MMMPostPresenter.h"
#import "MMMPostTableViewCell.h"
#import "MMMTableViewHeaderView.h"
#import "NSDate+Formatters.h"
#import "SUNCoreDataStore.h"
#import "UIViewController+ShareActivity.h"

@interface MMMPostsTableViewController ()

@property (nonatomic, weak) NSIndexPath *selectedIndexPath;

@end

#pragma mark MMMPostsTableViewController

@implementation MMMPostsTableViewController

#pragma mark - Class Methods

#pragma mark - Getters/Setters

@synthesize fetchedResultsController = _fetchedResultsController;

- (NSFetchedResultsController *)fetchedResultsController {
    if (_fetchedResultsController) {
        return _fetchedResultsController;
    }
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:[MMMPost entityName]];
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"date" ascending:NO],
                                     [NSSortDescriptor sortDescriptorWithKey:@"pubDate" ascending:NO],
                                     [NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)]];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"visible = %@", @YES];
    fetchRequest.returnsObjectsAsFaults = NO;
    
    _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:[SUNCoreDataStore defaultStore].mainQueueContext sectionNameKeyPath:@"date" cacheName:nil];
    _fetchedResultsController.delegate = self;
    
    NSError *error = nil;
    if (![_fetchedResultsController performFetch:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }

    return _fetchedResultsController;
}

#pragma mark - Actions

- (IBAction)settingsAction:(id)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
}

#pragma mark - Instance Methods

- (BOOL)canFetchMoreData {
    if (self.activityIndicatorView.isAnimating) {
        return NO;
    }
    
    if (self.nextPage <= 1) {
        return NO;
    }
    
    return YES;
}

- (void)configureCell:(__kindof MMMTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    MMMPost *post = [self.fetchedResultsController objectAtIndexPath:indexPath];
    cell.layoutMargins = self.tableView.layoutMargins;
    cell.layoutWidth = CGRectGetWidth(self.tableView.bounds);
    
    NSUInteger numberOfRows = [self.tableView numberOfRowsInSection:indexPath.section];
    cell.separatorView.hidden = (indexPath.row + 1 == numberOfRows);

    MMMPostPresenter *presenter = [[MMMPostPresenter alloc] initWithObject:post];
    [presenter setupView:cell];
}

- (void)fetchMoreData {
    if (!self.canFetchMoreData) {
        return;
    }
    
    [self.activityIndicatorView startAnimating];
    [MMMPost getWithPage:self.nextPage success:^(id response) {
        [self.activityIndicatorView stopAnimating];
        self.nextPage += 1;
    } failure:^(NSError *error) {
        [self handleError:error];
        [self.activityIndicatorView stopAnimating];
    }];
}

- (void)handleError:(NSError *)error {
    [TSMessage showNotificationWithTitle:error.localizedDescription
                                subtitle:error.localizedFailureReason
                                    type:TSMessageNotificationTypeError];
}

- (void)reloadData {
    if (!self.refreshControl.isRefreshing && self.fetchedResultsController.fetchedObjects.count == 0) {
        [self.refreshControl beginRefreshing];
    }
    
    [MMMPost getWithPage:1 success:^(NSArray *response) {
        self.numberOfResponseObjectsPerRequest = response.count;
        self.nextPage = 2;
        [self.refreshControl endRefreshing];
    } failure:^(NSError *error) {
        [self handleError:error];
        [self.refreshControl endRefreshing];
    }];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	UINavigationController *navigationController = segue.destinationViewController;
	MMMPostDetailViewController *detailViewController = (MMMPostDetailViewController *) navigationController.topViewController;

	if (self.postID) {
		detailViewController.postURL = [NSURL URLWithString:self.postID];

	} else {
		NSIndexPath *selectedIndexPath = self.tableView.indexPathForSelectedRow;
		if (selectedIndexPath) {
			detailViewController.post = [self.fetchedResultsController objectAtIndexPath:selectedIndexPath];
		}
    }

    [super prepareForSegue:segue sender:sender];
}

- (void)applyRefreshControlFix {
    if (!self.refreshControl.isRefreshing) {
        [self.tableView sendSubviewToBack:self.refreshControl];
    }
}

- (void)selectFirstTableViewCell {
	// check if the device is an iPad
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad && self.fetchedResultsController.fetchedObjects.count > 0) {
		
		NSUInteger row = 0;
		NSUInteger section = 0;

		NSDictionary *dict = [[NSUserDefaults standardUserDefaults] objectForKey:@"lastSelection"];
		if (dict) {
			NSDate *date = dict[@"date"];
			// Verify if the last selected post is greater than 12 hours
			NSTimeInterval secondsBetween = [[NSDate date] timeIntervalSinceDate:date];
			int numberOfHours = secondsBetween / 3600;
			if (numberOfHours < 12) {
				row = [dict[@"selectedCellIndexPathRow"] integerValue];
				section = [dict[@"selectedCellIndexPathSection"] integerValue];
			}
		}

		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^(void){
			NSIndexPath *selectedCellIndexPath = [NSIndexPath indexPathForRow:row inSection:section];
			[self.tableView selectRowAtIndexPath:selectedCellIndexPath animated:YES scrollPosition:UITableViewScrollPositionBottom];
			[self tableView:self.tableView didSelectRowAtIndexPath:selectedCellIndexPath];
		});

    }
}

#pragma mark - Protocols

#pragma mark - UITableView data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.fetchedResultsController.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    id <NSFetchedResultsSectionInfo> sectionInfo = self.fetchedResultsController.sections[section];
    return [sectionInfo numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    MMMPost *post = [self.fetchedResultsController objectAtIndexPath:indexPath];
    NSString *identifier = [MMMPostTableViewCell identifier];
    if (post.featuredValue) {
        identifier = [MMMFeaturedPostTableViewCell identifier];
    }
    
    __kindof MMMTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];
    [self configureCell:cell atIndexPath:indexPath];
    
    [cell layoutIfNeeded];
    
    if (CGRectGetWidth(cell.frame) != CGRectGetWidth(tableView.frame)) {
        cell.frame = CGRectMake(0, 0, CGRectGetWidth(tableView.frame), CGRectGetHeight(cell.frame));
        [cell layoutIfNeeded];
        [cell layoutSubviews];
    }

    UIView *selectedBackgroundView = [[UIView alloc] init];
    selectedBackgroundView.backgroundColor = [UIColor colorWithRed:0.13 green:0.79 blue:0.83 alpha:0.18];
    cell.selectedBackgroundView = selectedBackgroundView;

    return cell;
}

#pragma mark - UITableView delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // check if the cell is already selected
    if (self.selectedIndexPath != indexPath) {
        [[NSUserDefaults standardUserDefaults] setObject:@{@"selectedCellIndexPathRow": @(indexPath.row), @"selectedCellIndexPathSection": @(indexPath.section), @"date": [NSDate date]} forKey:@"lastSelection"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        NSString *segueIdentifier = NSStringFromClass([MMMPostDetailViewController class]);
        [self performSegueWithIdentifier:segueIdentifier sender:nil];
    }
    self.selectedIndexPath = indexPath;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    NSUInteger numberOfSections = [tableView numberOfSections];
    if (indexPath.section + 1 != numberOfSections) {
        return;
    }
    
    NSUInteger numberOfRemainingCells = labs(indexPath.row - [tableView numberOfRowsInSection:indexPath.section]);
    if (numberOfRemainingCells <= 10) {
        [self fetchMoreData];
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    MMMTableViewHeaderView *headerView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:[MMMTableViewHeaderView identifier]];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:section];

    MMMPost *post = [self.fetchedResultsController objectAtIndexPath:indexPath];
    MMMPostPresenter *presenter = [[MMMPostPresenter alloc] initWithObject:post];
    headerView.titleLabel.text = presenter.sectionTitle;
    
    return headerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:section];
    MMMPost *post = [self.fetchedResultsController objectAtIndexPath:indexPath];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    if ([calendar isDateInToday:post.pubDate]) {
        return 0;
    }
    
    return [MMMTableViewHeaderView height];
}

#pragma mark - UISplitViewDelegate delegate

- (BOOL)splitViewController:(UISplitViewController *)splitViewController collapseSecondaryViewController:(UIViewController *)secondaryViewController ontoPrimaryViewController:(UIViewController *)primaryViewController {
    return YES;
}

- (UIViewController *)previewingContext:(id )previewingContext viewControllerForLocation:(CGPoint)location {
    // check if viewController is not already displayed in the preview controller
    if ([self.presentedViewController isKindOfClass:[MMMPostDetailViewController class]]) {
        return nil;
    }
    
    CGPoint cellPosition = [self.tableView convertPoint:location fromView:self.view];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:cellPosition];
    
    if (indexPath) {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        MMMPostDetailViewController *previewViewController = [storyboard instantiateViewControllerWithIdentifier:NSStringFromClass([MMMPostDetailViewController class])];
        
        // send data to previewViewController
        previewViewController.post = [self.fetchedResultsController objectAtIndexPath:indexPath];
        return previewViewController;
    }
    return nil;
}

- (void)previewingContext:(id )previewingContext commitViewController: (UIViewController *)viewControllerToCommit {
    [self.navigationController showViewController:viewControllerToCommit sender:nil];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    if ([self isForceTouchAvailable]) {
        if (!self.previewingContext) {
            self.previewingContext = [self registerForPreviewingWithDelegate:self sourceView:self.view];
        }
    } else {
        if (self.previewingContext) {
            [self unregisterForPreviewingWithContext:self.previewingContext];
        }
    }
}

#pragma mark - Long press gesture

- (void)enableLongPressGesture {
	// check if the device is an iPhone
	if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone && self.fetchedResultsController.fetchedObjects.count > 0) {
		SEL selector = @selector(handleLongPress:);
		UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:selector];
		[self.tableView addGestureRecognizer:longPressGesture];
	}
}

- (void)handleLongPress:(UILongPressGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        CGPoint gesturePoint = [gestureRecognizer locationInView:self.tableView];
        NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:gesturePoint];
        if (indexPath == nil) return;

        [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
        MMMPost *post = [self.fetchedResultsController objectAtIndexPath:indexPath];
        NSURL *postURL = [NSURL URLWithString:post.link];
        if (!postURL) {
            return;
        }

        NSMutableArray *activityItems = [[NSMutableArray alloc] init];
        if (post) {
            [activityItems addObject:post.title];
        }
        [activityItems addObject:postURL];

        [self mmm_shareActivityItems:activityItems completion:^(NSString * _Nullable activityType, BOOL completed, NSArray * _Nullable returnedItems, NSError * _Nullable activityError) {
            [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
        }];
    }
}

#pragma mark - NSFetchedResultsController delegate

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView reloadData];
	[self selectFirstTableViewCell];
}

#pragma mark - UIViewControllerPreviewingDelegate delegate

- (BOOL)isForceTouchAvailable {
    BOOL isForceTouchAvailable = NO;
    if ([self.traitCollection respondsToSelector:@selector(forceTouchCapability)]) {
        isForceTouchAvailable = self.traitCollection.forceTouchCapability == UIForceTouchCapabilityAvailable;
    }
    return isForceTouchAvailable;
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if ([self isForceTouchAvailable]) {
        self.previewingContext = [self registerForPreviewingWithDelegate:self sourceView:self.view];
    }

    self.splitViewController.delegate = self;
    self.splitViewController.preferredDisplayMode = UISplitViewControllerDisplayModeAllVisible;

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applyRefreshControlFix)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reloadData)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self.tableView
                                             selector:@selector(reloadData)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];

	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(pushReceived:)
												 name:@"pushReceived"
											   object:nil];

    [self.tableView registerNib:[MMMPostTableViewCell nib] forCellReuseIdentifier:[MMMPostTableViewCell identifier]];
    [self.tableView registerNib:[MMMFeaturedPostTableViewCell nib] forCellReuseIdentifier:[MMMFeaturedPostTableViewCell identifier]];
    [self.tableView registerClass:[MMMTableViewHeaderView class] forHeaderFooterViewReuseIdentifier:[MMMTableViewHeaderView identifier]];
    
    self.tableView.estimatedRowHeight = 100;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;

    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.tableView.bounds), 60)];
    UIActivityIndicatorView *activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [footerView addSubview:activityIndicatorView];
    [activityIndicatorView autoCenterInSuperviewMargins];
    self.activityIndicatorView = activityIndicatorView;
    self.tableView.tableFooterView = footerView;

    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(reloadData) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refreshControl;

    self.navigationItem.titleView = [[MMMLogoImageView alloc] init];

    [self enableLongPressGesture];

    [self reloadData];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

	self.splitViewController.preferredPrimaryColumnWidthFraction = 0.33f;

    NSIndexPath *selectedIndexPath = self.tableView.indexPathForSelectedRow;
    if (selectedIndexPath) {
        [self.tableView deselectRowAtIndexPath:selectedIndexPath animated:animated];
    }

    [self.navigationController setToolbarHidden:YES animated:animated];
    self.navigationController.hidesBarsOnSwipe = NO;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)pushReceived:(NSNotification *)notification {
	self.postID = [notification object];

	NSString *segueIdentifier = NSStringFromClass([MMMPostDetailViewController class]);
	[self performSegueWithIdentifier:segueIdentifier sender:nil];
}

@end
