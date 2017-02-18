//
//  GEScheduleItem+GE.h
//  GoEuroTask
//
//  Created by Roman Sinelnikov on 18/02/17.
//  Copyright © 2017 Roman Sinelnikov. All rights reserved.
//

#import "GEScheduleItem+CoreDataClass.h"
typedef NS_ENUM(int16_t, GEScheduleItemType) {
    GEScheduleItemTypeUnknown,
    GEScheduleItemTypeBus,
    GEScheduleItemTypeTrain,
    GEScheduleItemTypeFlight
};

@interface GEScheduleItem (GE)

@end
