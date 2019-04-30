//
//  RBTextFieldCollectionViewCell.m
//  ResourceBooking
//
//  Created by Anbita Siregar on 6/25/15.
//  Copyright (c) 2015 Intrepid Pursuits. All rights reserved.
//

#import "PARTextFieldCollectionViewCell.h"
#import "PARBackspaceTextField.h"

@interface PARTextFieldCollectionViewCell ()

@end

@implementation PARTextFieldCollectionViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.tagTextField.textColor = [UIColor blackColor];
    self.clipsToBounds = NO;
}

- (void)useTextColor:(UIColor *)textColor tintColor:(UIColor *)tintColor {
    if (textColor) {
        self.tagTextField.textColor = textColor;
    }
    
    if (tintColor) {
        self.tagTextField.tintColor = tintColor;
    }
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (self.delegate) {
        return [self.delegate shouldReturnFromTextFieldCollectionViewCell:self];
    } else {
        return YES;
    }
}

- (IBAction)textFieldEditingDidChange:(UITextField *)sender {
    
    [self.delegate editingDidChangeInTextFieldCollectionViewCell:self];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    if ([self.delegate respondsToSelector:@selector(editingInTextFieldCollectionViewCell:becameActive:)]) {
        [self.delegate editingInTextFieldCollectionViewCell:self becameActive:YES];
    }
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    if ([self.delegate respondsToSelector:@selector(editingInTextFieldCollectionViewCell:becameActive:)]) {
        [self.delegate editingInTextFieldCollectionViewCell:self becameActive:NO];
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if ([self.delegate respondsToSelector:@selector(shouldAllowInTextFieldCollectionViewCell:newCharacters:)]) {
        return [self.delegate shouldAllowInTextFieldCollectionViewCell:self newCharacters:string];
    }
    return YES;
}

@end
