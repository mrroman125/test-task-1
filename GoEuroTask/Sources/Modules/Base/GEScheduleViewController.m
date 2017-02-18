//
//  GEScheduleViewController.m
//  GoEuroTask
//
//  Created by Roman Sinelnikov on 18/02/17.
//  Copyright © 2017 Roman Sinelnikov. All rights reserved.
//

#import "GEScheduleViewController.h"
#import "GoEuroTask-Swift.h"
#import <CoreData/CoreData.h>
#import "GEScheduleItemTableViewCell.h"
#import "Model+CoreDataModel.h"
#import <objc/runtime.h>
@interface GEScheduleViewController () <NSFetchedResultsControllerDelegate>
@property (nonatomic, strong) NSFetchedResultsController * fetchedController;
@property (nonatomic, strong) NSNumberFormatter * priceFormatter;
@property (nonatomic, strong) NSDateFormatter * timeFormatter;
@end

@implementation GEScheduleViewController

- (id)initWithItemType:(GEScheduleItemType)type {
    if ((self = [super initWithStyle:UITableViewStylePlain])) {
        _itemType = type;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.rightBarButtonItems = @[
        [[UIBarButtonItem alloc] initWithImage:
         [UIImage imageNamed:@"ic_refresh"] style:UIBarButtonItemStylePlain target:self action:@selector(refresh)
         ]
    ];
    self.navigationItem.leftBarButtonItems = @[
        [[UIBarButtonItem alloc] initWithImage:
         [UIImage imageNamed:@"ic_sort"] style:UIBarButtonItemStylePlain target:self action:@selector(sortDidClick)
         ]
    ];
    self.priceFormatter = [[NSNumberFormatter alloc] init];
    self.priceFormatter.numberStyle = NSNumberFormatterCurrencyStyle;
    self.priceFormatter.currencySymbol = @"€";
    
    self.timeFormatter = [[NSDateFormatter alloc] init];
    self.timeFormatter.dateFormat = @"HH:mm";
    
    self.tableView.rowHeight = 83;
    [self.tableView registerNib:[UINib nibWithNibName:@"GEScheduleItemTableViewCell" bundle:nil]
         forCellReuseIdentifier:@"cell"];
    NSFetchRequest * request = [self requestWithSortKey:@"departureTime"];
    self.fetchedController
    = [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                          managedObjectContext:self.managedObjectContext
                                            sectionNameKeyPath:nil
                                                     cacheName:nil];
    self.fetchedController.delegate = self;
    [self.fetchedController performFetch:nil];
    
    self.tabBarItem.title = [NSString stringWithFormat:@"%d", self.itemType];
    
    [self refresh];
}

- (void)refresh {
    [self.schedulesManager refreshScheduleWithType:self.itemType completion:^(NSError * _Nullable error) {
        if (error != nil) {
            [self showAlertWithMessage:error.localizedDescription];
        }
    }];
}

- (NSFetchRequest *)requestWithSortKey:(NSString *)sortKey {
    NSFetchRequest * request = [[NSFetchRequest alloc] initWithEntityName:@"GEScheduleItem"];
    request.predicate = [NSPredicate predicateWithFormat:@"type == %@", @(self.itemType)];
    request.sortDescriptors = @[
        [NSSortDescriptor sortDescriptorWithKey:sortKey ascending:YES],
    ];
    return request;
}

- (void)sortDidClick {
    NSFetchRequest * request = nil;
    
    if ([self.fetchedController.fetchRequest.sortDescriptors.firstObject.key isEqualToString:@"departureTime"]) {
        request = [self requestWithSortKey:@"arrivalTime"];
    } else {
        request = [self requestWithSortKey:@"departureTime"];
    }
    self.fetchedController
    = [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                          managedObjectContext:self.managedObjectContext
                                            sectionNameKeyPath:nil
                                                     cacheName:nil];
    self.fetchedController.delegate = self;
    [self.fetchedController performFetch:nil];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
}

- (void)showAlertWithMessage:(NSString *)message {
    UIAlertController * alertController
    = [UIAlertController alertControllerWithTitle:nil
                                          message:message
                                   preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alertController animated:YES completion:nil];
}
#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.fetchedController.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.fetchedController.sections[section].objects.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    GEScheduleItemTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    GEScheduleItem * item = [self.fetchedController objectAtIndexPath:indexPath];
    cell.priceLabel.text = [self.priceFormatter stringFromNumber:@(item.price)];
    cell.timeLabel.text = [NSString stringWithFormat:@"%@ - %@%@",
                           [self.timeFormatter stringFromDate:item.departureTime],
                           [self.timeFormatter stringFromDate:item.arrivalTime],
                           item.numberOfStops == 0 ? @"" : [NSString stringWithFormat:@" (+%d)", item.numberOfStops]
                           ];
    NSTimeInterval duration = [item.arrivalTime timeIntervalSinceDate:item.departureTime];
    cell.durationLabel.text = [NSString stringWithFormat:@"%dh:%02dm", (int) duration / 3600, ((int) duration % 3600) / 60];
    
    NSURL * imageUrl = [[NSURL alloc] initWithString:[item.providerLogo stringByReplacingOccurrencesOfString:@"{size}" withString:@"63"]];
    NSURLSessionDataTask * task = nil;
    
    static int urlKey = 0;
    objc_setAssociatedObject(cell, &urlKey, imageUrl, OBJC_ASSOCIATION_RETAIN);
    cell.imageView.image = nil;
    if (imageUrl != nil) {
        task =
        [[NSURLSession sharedSession] dataTaskWithURL:imageUrl completionHandler:
         ^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            UIImage * image = [UIImage imageWithData:data];
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([imageUrl isEqual: objc_getAssociatedObject(cell, &urlKey)]) {
                    cell.logoImageView.image = image;
                }
            });
        }];
    }
    [task resume];
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self showAlertWithMessage:@"Offer details are not yet implemented!"];
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        default:
            return;
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    UITableView *tableView = self.tableView;
    
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
            break;
            
        case NSFetchedResultsChangeMove:
            [tableView moveRowAtIndexPath:indexPath toIndexPath:newIndexPath];
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView endUpdates];
}

@end
