//
//  RBTagPickerViewController.m
//  ResourceBooking
//
//  Created by Paul Rolfe on 7/9/15.
//  Copyright (c) 2015 Intrepid Pursuits. All rights reserved.
//

#import "PARTagPickerViewController.h"
#import "PARTagCollectionViewCell.h"
#import "PARTextFieldCollectionViewCell.h"
#import "PARBackspaceTextField.h"
#import "NSString+PARStrings.h"
#import "PARTagColorReference.h"
#import "UIView+NibInitable.h"

CGFloat const COLLECTION_VIEW_HEIGHT = 39.0;
static CGFloat const TAGCOLLECTION_CELL_HEIGHT = 27.0;
static CGFloat const TAG_TEXTFIELD_MAXWIDTH = 150;
static NSString * const PARTagCollectionViewCellIdentifier = @"PARTagCollectionViewCellIdentifier";
static NSString * const PARTextFieldCollectionViewCellIdentifier = @"PARTextFieldCollectionViewCellIdentifier";

@interface PARTagPickerViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, PARBackspaceTextFieldDelegate, PARTagCollectionViewCellDelegate, PARTextFieldCollectionViewCellDelegate>

@property (nonatomic, strong) NSMutableArray *availableTags;
@property (nonatomic, strong) NSArray *filteredAvailableTags;

@property (weak, nonatomic) IBOutlet UICollectionView *chosenTagCollectionView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *chosenTagCollectionViewHeightConstraint;
@property (nonatomic, weak) IBOutlet UICollectionView *availableTagCollectionView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *availableTagCollectionViewHeightConstraint;
@property (weak, nonatomic) PARBackspaceTextField *cellTextField;
@property (nonatomic, copy) NSString *searchString; //storing a reference for refresh of collection views after selecting an item.

@end

@implementation PARTagPickerViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    NSString *bundlePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"PARTagPicker" ofType:@"bundle"];
    NSBundle *assetBundle = [NSBundle bundleWithPath:bundlePath];
    self = [super initWithNibName:nibNameOrNil bundle:assetBundle];
    if (self) {
        self.tapToEraseTags = YES;
        self.textfieldEnabled = YES;
        self.shouldAutomaticallyChangeVisibilityState = YES;
        self.placeholderText = @"Add a tag";
        self.placeholderTextForAvailable = @"Available tags go here";
        self.placeholderTextColorForAvailable = [UIColor whiteColor];
        self.textfieldPlaceholderTextColor = [UIColor grayColor];
        self.textfieldRegularTextColor = [UIColor whiteColor];
    }
    return self;
}

- (instancetype)init {
    return [self initWithNibName:nil bundle:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupCollectionViews];
    self.chosenTags = [NSMutableArray array];
    self.visibilityState = PARTagPickerVisibilityStateTopOnly;
}

#pragma mark - Forced Updates

- (void)becomeFirstResponder {
    if (self.textfieldEnabled) {
        [self.cellTextField becomeFirstResponder];
    }
}

- (void)reloadCollectionViews {
    [self.availableTagCollectionView reloadData];
    [self.chosenTagCollectionView reloadData];
}

#pragma mark - Setters

- (void)setAllTags:(NSArray *)allTags {
    _allTags = allTags;
    self.availableTags = [allTags mutableCopy];
    [self transferChosenTagsWithNewAllTags];
    NSMutableArray *tagsToDiscard = [NSMutableArray array];
    for (PARTag *tag in self.availableTags) {
        if ([self.chosenTags filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self == %@", tag]].count > 0) {
            [tagsToDiscard addObject:tag];
        }
    }
    [self.availableTags removeObjectsInArray:tagsToDiscard];
    [self filterTagsFromSearchString];
}

- (void)setChosenTags:(NSMutableArray *)chosenTags {
    NSMutableArray *oldSelectedTags = [NSMutableArray array];
    if (_chosenTags != nil && _chosenTags.count > 0) {
        for (NSIndexPath *indexPath in self.chosenTagCollectionView.indexPathsForSelectedItems) {
            PARTag *tag = [_chosenTags objectAtIndex:indexPath.row];
            [oldSelectedTags addObject:tag];
        }
    }
    
    _chosenTags = chosenTags;

    [self.chosenTagCollectionView reloadData];
    for (PARTag *tag in oldSelectedTags) {
        PARTag *newTag = [self tagSimilarToStringFromChosen:tag.label];
        if (newTag != nil) {
            NSUInteger index = [self.chosenTags indexOfObject:newTag];
            [self.chosenTagCollectionView selectItemAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0] animated:NO scrollPosition:UICollectionViewScrollPositionNone];
        }
    }

    self.availableTags = [self.allTags mutableCopy];
    NSMutableArray *tagsToDiscard = [NSMutableArray array];
    for (PARTag *tag in self.availableTags) {
        if ([self.chosenTags filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self == %@", tag]].count > 0) {
            [tagsToDiscard addObject:tag];
        }
    }
    [self.availableTags removeObjectsInArray:tagsToDiscard];
    [self filterTagsFromSearchString];
}

- (void)transferChosenTagsWithNewAllTags {
    //have to loop through like this, because enumeration is clashing with mutating the array.
    if (!self.chosenTags) {
        self.chosenTags = [NSMutableArray array];
    }
    for (int i = 0; i < self.chosenTags.count; i++) {
        PARTag *tag = self.chosenTags[i];
        [self.chosenTags removeObject:tag];
        PARTag *similarTag = [tag similarTagFromArray:self.allTags];
        if (similarTag) {
            [self.chosenTags insertObject:similarTag atIndex:i];
        }
    }
}

- (void)setVisibilityState:(PARTagPickerVisibilityState)visibilityState {
    if (_visibilityState != visibilityState) {
        _visibilityState = visibilityState;
        switch (visibilityState) {
            case PARTagPickerVisibilityStateHidden: {
                [self setChosenTagCollectionViewHidden:YES];
                [self setAvailableTagsCollectionViewHidden:YES];
                break;
            }
            case PARTagPickerVisibilityStateTopAndBottom: {
                [self setChosenTagCollectionViewHidden:NO];
                [self setAvailableTagsCollectionViewHidden:NO];
                break;
            }
            case PARTagPickerVisibilityStateTopOnly: {
                [self setChosenTagCollectionViewHidden:NO];
                [self setAvailableTagsCollectionViewHidden:YES];
                break;
            }
            default: {
                break;
            }
        }
        [self.delegate tagPicker:self visibilityChangedToState:visibilityState];
        
    }
}

- (void)setTextfieldEnabled:(BOOL)textfieldEnabled {
    _textfieldEnabled = textfieldEnabled;
    self.cellTextField.userInteractionEnabled = textfieldEnabled;
    [self reloadCollectionViews]; // In order to fix the phontom text fields.
}

#pragma mark - Tag Filtering

- (void)filterTagsFromSearchString {
    NSSortDescriptor * sortDesc = [NSSortDescriptor sortDescriptorWithKey:@"self.label" ascending:NO];
    [self.availableTags sortUsingDescriptors:@[sortDesc]];
    
    if (!self.searchString || [self.searchString isEqualToString:@""]){
        self.filteredAvailableTags = self.availableTags;
        [self.availableTagCollectionView reloadData];
        return;
    }
    
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"self.label contains[cd] %@",self.searchString];
    self.filteredAvailableTags = [self.availableTags filteredArrayUsingPredicate:pred];
    
    [self.availableTagCollectionView reloadData];
}

- (PARTag *)tagSimilarToStringFromAvailable:(NSString *)tag {
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"self.label LIKE %@", tag];
    NSArray *similarTags = [self.availableTags filteredArrayUsingPredicate:pred];
    return similarTags.firstObject;
}

- (PARTag *)tagSimilarToStringFromChosen:(NSString *)tag {
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"self.label LIKE %@", tag];
    NSArray *similarTags = [self.chosenTags filteredArrayUsingPredicate:pred];
    return similarTags.firstObject;
}

#pragma mark - Appearance and constraints

- (void)setupCollectionViews {
    NSString *bundlePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"PARTagPicker" ofType:@"bundle"];
    NSBundle *assetBundle = [NSBundle bundleWithPath:bundlePath];
    [self.chosenTagCollectionView registerNib:[UINib nibWithNibName:NSStringFromClass([PARTagCollectionViewCell class]) bundle:assetBundle] forCellWithReuseIdentifier:PARTagCollectionViewCellIdentifier];
    [self.chosenTagCollectionView registerNib:[UINib nibWithNibName:NSStringFromClass([PARTextFieldCollectionViewCell class]) bundle:assetBundle] forCellWithReuseIdentifier:PARTextFieldCollectionViewCellIdentifier];
    [self.availableTagCollectionView registerNib:[UINib nibWithNibName:NSStringFromClass([PARTagCollectionViewCell class]) bundle:assetBundle] forCellWithReuseIdentifier:PARTagCollectionViewCellIdentifier];
}

- (void)animateBottomRowCellToTopFromIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell * cell = [self.availableTagCollectionView cellForItemAtIndexPath:indexPath];
    [UIView animateWithDuration:.3 animations:^{
        cell.transform = CGAffineTransformMakeTranslation(0, -COLLECTION_VIEW_HEIGHT);
        cell.alpha = 0;
    } completion:^(BOOL finished) {
        [self filterTagsFromSearchString];
        cell.alpha = 1;
        cell.transform = CGAffineTransformIdentity;
    }];
}

- (void)setChosenTagCollectionViewHidden:(BOOL)hidden {
    if (hidden) {
        self.chosenTagCollectionViewHeightConstraint.constant = 0;
        //scroll to beginning and unhighlight everything.
        [self.chosenTagCollectionView reloadData];
        [self.chosenTagCollectionView setContentOffset:CGPointZero animated:YES];
    } else {
        self.chosenTagCollectionViewHeightConstraint.constant = COLLECTION_VIEW_HEIGHT;
    }
    [UIView animateWithDuration:.5 animations:^{
        [self.chosenTagCollectionView.collectionViewLayout invalidateLayout];
        [self.view layoutIfNeeded];
    }];
}

- (void)setAvailableTagsCollectionViewHidden:(BOOL)hidden {
    if (hidden) {
        self.availableTagCollectionViewHeightConstraint.constant = 0;
        //scroll to beginning and unhighlight everything.
        [self.chosenTagCollectionView reloadData];
        [self.chosenTagCollectionView setContentOffset:CGPointZero animated:YES];
    } else {
        self.availableTagCollectionViewHeightConstraint.constant = COLLECTION_VIEW_HEIGHT;
    }
    [UIView animateWithDuration:.5 animations:^{
        [self.availableTagCollectionView.collectionViewLayout invalidateLayout];
        [self.view layoutIfNeeded];
    }];
}

- (void)scrollChosenTagsToEnd {
    [self.chosenTagCollectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:self.chosenTags.count inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
}

- (void)addPlaceholderTextToCellTextField {
    UIColor *textColor = [UIColor colorWithWhite:0.7 alpha:0.7];
    if (self.textfieldPlaceholderTextColor) {
        textColor = self.textfieldPlaceholderTextColor;
    }
    self.cellTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:self.placeholderText attributes:@{NSForegroundColorAttributeName: textColor}];
}

- (void)removeChosenTagFromIndexPath:(NSIndexPath *)indexPath {
    if ([self.chosenTags count] > indexPath.row) {
        PARTag *selectedTag = [self.chosenTags objectAtIndex:indexPath.row];
        if ([self.allTags containsObject:selectedTag]) {
            [self.availableTags addObject:selectedTag];
            [self.availableTagCollectionView reloadData];
        }
        [self.chosenTags removeObjectAtIndex:indexPath.row];
        [self.chosenTagCollectionView deleteItemsAtIndexPaths:@[indexPath]];
        if ([self.delegate respondsToSelector:@selector(chosenTagsWereUpdatedInTagPicker:added:removed:)]) {
            [self.delegate chosenTagsWereUpdatedInTagPicker:self
                                                      added:nil
                                                    removed:[NSArray arrayWithObject:selectedTag]];
        }
        if (self.chosenTags.count == 0) {
            [self addPlaceholderTextToCellTextField];
        }
    }
}

- (void)addChosenTagFromIndexPath:(NSIndexPath *)indexPath {
    PARTag *selectedTag = self.filteredAvailableTags[indexPath.row];
    NSIndexPath *addedPath = [NSIndexPath indexPathForItem:self.chosenTags.count inSection:0];
    [self.chosenTags addObject:selectedTag];
    [self.availableTags removeObject:selectedTag];
    [self.chosenTagCollectionView insertItemsAtIndexPaths:@[addedPath]];
    [self.chosenTagCollectionView scrollToItemAtIndexPath:addedPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
    [self animateBottomRowCellToTopFromIndexPath:indexPath];
    if ([self.delegate respondsToSelector:@selector(chosenTagsWereUpdatedInTagPicker:added:removed:)]) {
        [self.delegate chosenTagsWereUpdatedInTagPicker:self
                                                  added:[NSArray arrayWithObject:selectedTag]
                                                removed:nil];
    }
}

#pragma mark - UICollectionViewDelegate

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (collectionView == self.availableTagCollectionView) {
        NSInteger count = self.filteredAvailableTags.count;
        if (count == 0) {
            UILabel *messageLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.availableTagCollectionView.bounds.size.width, self.availableTagCollectionView.bounds.size.height)];
            messageLabel.text = self.placeholderTextForAvailable;
            messageLabel.textColor = self.placeholderTextColorForAvailable;
            messageLabel.textAlignment = NSTextAlignmentCenter;
            messageLabel.font = [messageLabel.font fontWithSize:12.0];
            messageLabel.numberOfLines = 0;
            [messageLabel sizeToFit];
            
            self.availableTagCollectionView.backgroundView = messageLabel;
        } else {
            self.availableTagCollectionView.backgroundView = nil;
        }
        return count;
    } else if (collectionView == self.chosenTagCollectionView) {
        return self.chosenTags.count + 1;
    } else {
        return 0;
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (collectionView == self.chosenTagCollectionView && indexPath.row == self.chosenTags.count) {
        PARTextFieldCollectionViewCell *textFieldCell = [collectionView dequeueReusableCellWithReuseIdentifier:PARTextFieldCollectionViewCellIdentifier forIndexPath:indexPath];
        self.cellTextField = textFieldCell.tagTextField;
        textFieldCell.useFilteringColors = !self.allowsNewTags;
        textFieldCell.delegate = self;
        textFieldCell.tagTextField.backspaceDelegate = self;
        textFieldCell.tagTextField.text = @"";
        textFieldCell.tagTextField.textColor = self.textfieldRegularTextColor;
        if (self.textfieldCursorColor) {
            textFieldCell.tagTextField.tintColor = self.textfieldCursorColor;
        }
        if (self.font) {
            textFieldCell.tagTextField.font = self.font;
        }
        
        [self addPlaceholderTextToCellTextField];

        return textFieldCell;
    } else {
        PARTagCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:PARTagCollectionViewCellIdentifier forIndexPath:indexPath];
        PARTag *tag;
        if (collectionView == self.availableTagCollectionView) {
            tag = self.filteredAvailableTags[indexPath.row];
            [cell configure:tag chosen:NO];
        } else if (collectionView == self.chosenTagCollectionView) {
            tag = self.chosenTags[indexPath.row];
            [cell configure:tag chosen:YES];
        }
        if (self.font) {
            cell.tagLabel.font = self.font;
        }
        cell.delegate = self;
        cell.phantomTextField.backspaceDelegate = self;
        cell.phantomTextField.userInteractionEnabled = self.textfieldEnabled;
        return cell;
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (collectionView == self.chosenTagCollectionView && self.chosenTags.count == indexPath.row) {
        return CGSizeMake(TAG_TEXTFIELD_MAXWIDTH, TAGCOLLECTION_CELL_HEIGHT);
    } else {
        PARTagCollectionViewCell *sizingCell = nil;
        if (!sizingCell) {
            sizingCell = [[PARTagCollectionViewCell alloc] initWithNibNamed:nil];
        }
        PARTag *tag;
        if (collectionView == self.availableTagCollectionView && indexPath.row < self.filteredAvailableTags.count) {
            tag = self.filteredAvailableTags[indexPath.row];
        } else if (collectionView == self.chosenTagCollectionView && indexPath.row < self.chosenTags.count) {
            tag = self.chosenTags[indexPath.row];
        }
        sizingCell.tagLabel.text = tag.label;
        sizingCell.tagLabel.font = self.font;
        [sizingCell setNeedsLayout];
        [sizingCell layoutIfNeeded];

        CGSize size = [sizingCell systemLayoutSizeFittingSize:CGSizeMake(collectionView.contentSize.width, TAGCOLLECTION_CELL_HEIGHT) withHorizontalFittingPriority:UILayoutPriorityDefaultLow verticalFittingPriority:UILayoutPriorityDefaultHigh];
        return size;
    }
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (collectionView == self.chosenTagCollectionView){
        //if it's the chosen tags AND we are editing tags remove it.
        //else just expand to editing mode
        if (indexPath.row <= self.chosenTags.count && self.visibilityState == PARTagPickerVisibilityStateTopAndBottom) {
            if (self.tapToEraseTags) {
                [self removeChosenTagFromIndexPath:indexPath];
            } else {
                return YES;
            }
        } else if (self.shouldAutomaticallyChangeVisibilityState) {
            self.visibilityState = PARTagPickerVisibilityStateTopAndBottom;
        }
    } else if (collectionView == self.availableTagCollectionView){
        //if it's the available tags
        //then add that tag to the chose tags and remove it from the available ones.
        self.searchString = nil;
        self.cellTextField.text = @"";
        self.cellTextField.placeholder = self.placeholderText;
        [self addChosenTagFromIndexPath:indexPath];
    }
    return NO;
}

#pragma mark - RBTagCollectionViewCellDelegate

- (void)editingDidChangeInTagCollectionViewCell:(PARTagCollectionViewCell *)cell {
    NSIndexPath *selectedIndexPath = [self.chosenTagCollectionView indexPathsForSelectedItems].firstObject;
    if (selectedIndexPath) {
        [self.chosenTagCollectionView deselectItemAtIndexPath:selectedIndexPath animated:YES];
    }
    if (self.textfieldEnabled) {
        [self.cellTextField becomeFirstResponder];
        self.cellTextField.text = cell.phantomTextField.text;
    }
}

#pragma mark - RBTextFieldCollectionViewCellDelegate

- (BOOL)shouldReturnFromTextFieldCollectionViewCell:(PARTextFieldCollectionViewCell *)cell {
    NSString *text = [cell.tagTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if (text.length > 0) {
        self.searchString = nil;
        cell.tagTextField.text = @"";
        cell.tagTextField.placeholder = self.placeholderText;
        
        if (self.allowsNewTags) {
            if ([self tagSimilarToStringFromChosen:text] != nil) {
                [self filterTagsFromSearchString];
                return NO;
            }
            
            PARTag *possibleMatchFromAvailable = [self tagSimilarToStringFromAvailable:text];
            if (possibleMatchFromAvailable) {
                NSInteger whereItIs = [self.filteredAvailableTags indexOfObject:possibleMatchFromAvailable];
                NSIndexPath *pathOfIt = [NSIndexPath indexPathForItem:whereItIs inSection:0];
                [self addChosenTagFromIndexPath:pathOfIt];
            } else {
                PARTag *newTag = nil;
                if ([self.dataSource respondsToSelector:@selector(newTagWithLabel:)]) {
                    newTag = [self.dataSource newTagWithLabel:text];
                } else {
                    newTag = [[PARTag alloc] initWith:text];
                }
                if (newTag == nil) {
                    [self filterTagsFromSearchString];
                    return NO;
                }
                
                [self.chosenTags addObject:newTag];
                NSIndexPath *pathToMake = [NSIndexPath indexPathForItem:self.chosenTags.count - 1 inSection:0];
                [self.chosenTagCollectionView insertItemsAtIndexPaths:@[pathToMake]];
                if ([self.delegate respondsToSelector:@selector(chosenTagsWereUpdatedInTagPicker:added:removed:)]) {
                    [self.delegate chosenTagsWereUpdatedInTagPicker:self
                                                              added:[NSArray arrayWithObject:newTag]
                                                            removed:nil];
                }
            }
        } else {
            PARTag *firstTag = self.filteredAvailableTags.firstObject;
            if (firstTag) {
                NSIndexPath *removedPath = [NSIndexPath indexPathForItem:0 inSection:0];
                [self addChosenTagFromIndexPath:removedPath];
            }
        }
        [self scrollChosenTagsToEnd];
        [self filterTagsFromSearchString];
        return YES;
    }
    return NO;
    
}

- (void)editingDidChangeInTextFieldCollectionViewCell:(PARTextFieldCollectionViewCell *)cell {
    NSIndexPath *selectedPath = (NSIndexPath *)[self.chosenTagCollectionView indexPathsForSelectedItems].firstObject;
    if (selectedPath) {
        [self.chosenTagCollectionView deselectItemAtIndexPath:selectedPath animated:YES];
    }
    self.searchString = cell.tagTextField.text;
    [self filterTagsFromSearchString];
    
    if ([self.delegate respondsToSelector:@selector(searchStringDidChange:)]) {
        [self.delegate searchStringDidChange:self.searchString];
    }
}

- (void)editingInTextFieldCollectionViewCell:(PARTextFieldCollectionViewCell *)cell becameActive:(BOOL)active {
    if (!self.shouldAutomaticallyChangeVisibilityState) {
        return;
    }
    
    if (!active && [self.chosenTagCollectionView indexPathsForSelectedItems].count > 0) {
        return;
    }
    if (!active && self.addNewWhenDismissingKeyboard) {
        [self shouldReturnFromTextFieldCollectionViewCell:cell];
    }
    if (active) {
        [self setVisibilityState:PARTagPickerVisibilityStateTopAndBottom];
    } else if (self.visibilityState != PARTagPickerVisibilityStateHidden) {
        [self setVisibilityState:PARTagPickerVisibilityStateTopOnly];
    }
}

- (BOOL)shouldAllowInTextFieldCollectionViewCell:(PARTextFieldCollectionViewCell *)cell newCharacters:(NSString *)string {
    if (self.allowedCharacters == nil) {
        return YES;
    }
    return [string rangeOfCharacterFromSet:[self.allowedCharacters invertedSet]].location == NSNotFound;
}

#pragma mark - RBBackspaceTextFieldDelegate

- (void)textFieldDidBackspace:(UITextField *)textField {
    if (self.chosenTags.count < 1 || (textField == self.cellTextField && self.cellTextField.text.length > 0)) {
        return;
    }
    NSIndexPath *lastPath = [NSIndexPath indexPathForItem:(self.chosenTags.count - 1) inSection:0];
    NSIndexPath *selectedPath = (NSIndexPath *)[self.chosenTagCollectionView indexPathsForSelectedItems].firstObject;
    if (selectedPath) {
        if (selectedPath != lastPath && textField == self.cellTextField) {
            //Don't delete things if the cursor is visible and the selected cell isn't the last cell.
            [self.chosenTagCollectionView selectItemAtIndexPath:lastPath animated:YES scrollPosition:UICollectionViewScrollPositionNone];
        } else {
            [self removeChosenTagFromIndexPath:selectedPath];
            
            //highlight the next item if it's there.
            NSInteger nextRow = selectedPath.row - 1;
            if (self.chosenTags.count > 0 && nextRow >= 0 && selectedPath.row != self.chosenTags.count) {
                NSIndexPath *nextSelection = [NSIndexPath indexPathForItem:nextRow inSection:0];
                [self.chosenTagCollectionView selectItemAtIndexPath:nextSelection animated:YES scrollPosition:UICollectionViewScrollPositionCenteredHorizontally];
            } else if (self.textfieldEnabled) {
                [self.cellTextField becomeFirstResponder];
            }
            
            self.searchString = nil;
            [self filterTagsFromSearchString];
            
            if (self.chosenTags.count == 0) {
                [self addPlaceholderTextToCellTextField];
            } else {
                self.cellTextField.placeholder = self.placeholderText;
            }
        }
    } else {
        //nothing to delete, just select last cell.
        [self.chosenTagCollectionView selectItemAtIndexPath:lastPath animated:YES scrollPosition:UICollectionViewScrollPositionNone];
    }
}

@end
