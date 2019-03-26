//
//  RBTagCollectionViewCell.h
//  ResourceBooking
//
//  Created by Anbita Siregar on 6/24/15.
//  Copyright (c) 2015 Intrepid Pursuits. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PARTag.h"

@class PARTagCollectionViewCell, PARBackspaceTextField, PARTagColorReference;

@protocol PARTagCollectionViewCellDelegate <NSObject>

@optional

- (void)editingDidChangeInTagCollectionViewCell:(PARTagCollectionViewCell *)cell;

@end

@interface PARTagCollectionViewCell : UICollectionViewCell <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UILabel *tagLabel;
@property (weak, nonatomic) IBOutlet PARBackspaceTextField *phantomTextField;
@property (weak, nonatomic) id<PARTagCollectionViewCellDelegate> delegate;

@property (strong, nonatomic) PARTag *tagObject;


- (void)showAsChosen:(BOOL)chosen;
- (void)configure:(PARTag *)tag chosen:(BOOL)chosen;

@end
