//
//  PARTag.h
//  PARTagPicker
//
//  Created by Pei on 2019/3/25.
//  Copyright © 2019 Paul Rolfe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PARTagColorReference.h"

NS_ASSUME_NONNULL_BEGIN

@interface PARTag : NSObject

- (instancetype)initWith:(NSString *)label;
- (instancetype)initWith:(NSString *)label color:(PARTagColorReference *)colorReference;

- (PARTag *)similarTagFromArray:(NSArray *)tags;

@property (nonatomic, strong) NSString *label;
@property (nonatomic, strong) PARTagColorReference *colorReference;

@end

NS_ASSUME_NONNULL_END
