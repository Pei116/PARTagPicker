//
//  RBTagCollectionViewCell.m
//  ResourceBooking
//
//  Created by Anbita Siregar on 6/24/15.
//  Copyright (c) 2015 Intrepid Pursuits. All rights reserved.
//

#import "PARTagCollectionViewCell.h"
#import "PARBackspaceTextField.h"
#import "PARTagColorReference.h"

@interface PARTagCollectionViewCell ()

@end

@implementation PARTagCollectionViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.layer.cornerRadius = CGRectGetHeight(self.bounds) / 2;
    self.layer.borderWidth = 2;
    self.selected = NO;
}

- (IBAction)textFieldEditingDidChange:(UITextField *)sender {
    [self.delegate editingDidChangeInTagCollectionViewCell:self];
    sender.text = @"";
}

- (void)showAsChosen:(BOOL)chosen {
    if (chosen) {
        self.tagLabel.textColor = self.tagObject.colorReference.chosenTagTextColor;
        self.backgroundColor = self.tagObject.colorReference.chosenTagBackgroundColor;
        self.layer.borderColor = self.tagObject.colorReference.chosenTagBorderColor.CGColor;
    } else {
        self.tagLabel.textColor = self.tagObject.colorReference.defaultTagTextColor;
        self.backgroundColor = self.tagObject.colorReference.defaultTagBackgroundColor;
        self.layer.borderColor = self.tagObject.colorReference.defaultTagBorderColor.CGColor;
    }
}

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    if (selected) {
        self.tagLabel.textColor = self.tagObject.colorReference.highlightedTagTextColor;
        self.backgroundColor = self.tagObject.colorReference.highlightedTagBackgroundColor;
        self.layer.borderColor = self.tagObject.colorReference.highlightedTagBorderColor.CGColor;
        [self.phantomTextField becomeFirstResponder];
    } else {
        [self showAsChosen:YES];
        [self.phantomTextField resignFirstResponder];
    }
}

- (void)prepareForReuse {
    [super prepareForReuse];
    
    self.tagLabel.textColor = UIColor.blackColor;
    self.backgroundColor = UIColor.grayColor;
    self.layer.borderColor = UIColor.grayColor.CGColor;
}

- (void)configure:(PARTag *)tag chosen:(BOOL)chosen {
    self.tagObject = tag;
    self.tagLabel.text = tag.label;
    [self showAsChosen:chosen];
}

@end
