//
//  PARTag.m
//  PARTagPicker
//
//  Created by Pei on 2019/3/25.
//  Copyright © 2019 Paul Rolfe. All rights reserved.
//

#import "PARTag.h"

@implementation PARTag

- (instancetype)initWith:(NSString *)label {
    self = [self initWith:label color:[[PARTagColorReference alloc] initWithDefaultColors]];
    return self;
}

- (instancetype)initWith:(NSString *)label color:(PARTagColorReference *)colorReference {
    self = [super init];
    self.label = label;
    self.colorReference = colorReference;
    return self;
}

- (PARTag *)similarTagFromArray:(NSArray *)tags {
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"self.label LIKE %@", self.label];
    NSArray *similarTags = [tags filteredArrayUsingPredicate:pred];
    return similarTags.firstObject;
}

@end
