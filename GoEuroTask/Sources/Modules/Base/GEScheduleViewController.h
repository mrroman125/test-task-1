//
//  GEScheduleViewController.h
//  GoEuroTask
//
//  Created by Roman Sinelnikov on 18/02/17.
//  Copyright © 2017 Roman Sinelnikov. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GEScheduleItem+GE.h"

@protocol SchedulesManager;

@interface GEScheduleViewController : UITableViewController
@property (nonatomic, strong) NSManagedObjectContext * managedObjectContext;
@property (nonatomic, assign, readonly) GEScheduleItemType itemType;
- (id)initWithItemType:(GEScheduleItemType)type;
@property (nonatomic, strong) id<SchedulesManager> schedulesManager;

@end
