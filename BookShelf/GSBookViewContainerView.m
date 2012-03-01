//
//  BookViewContainerView.m
//  BookShelf
//
//  Created by 鑫容 郭 on 12-2-24.
//  Copyright (c) 2012年 FoOTOo. All rights reserved.
//

#import "GSBookViewContainerView.h"
#import "GSBookShelfView.h"
#import "GSBookView.h"

#define kRatio_width_spacing 2.2f
#define kRatio_height_width 1.414f

#define kGrow_animation_duration 0.15
#define kSrink_animation_duration 0.15

@interface GSBookViewContainerView (Private)

// Animation
- (void)growAnimationAtPoint:(CGPoint)point forView:(UIView *)view;
@end

@implementation GSBookViewContainerView

@synthesize parentBookShelfView = _parentBookShelfView;
@synthesize booksArray = _booksArray;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _booksArray = [[NSMutableArray alloc] initWithCapacity:0];
        _reuseableBookViews = [[NSMutableSet alloc] initWithCapacity:0];
        
        _firstVisibleRow = NSIntegerMax;
        _lastVisibleRow = NSIntegerMin;
        
        // dragAndDrop
        _isDragViewPickedUp = NO;
        
        // GestureRecognizer
        UILongPressGestureRecognizer *longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPressGesture:)];
        [self addGestureRecognizer:longPressGestureRecognizer];
        
    }
    return self;
}

- (void)setParentBookShelfView:(GSBookShelfView *)parentBookShelfView {
    _parentBookShelfView = parentBookShelfView;
    
    // calculate bookview's size and spacing
    
    CGFloat cellWidth = _parentBookShelfView.frame.size.width;
    CGFloat cellMarginWidth = _parentBookShelfView.cellMarginWidth;
    NSInteger numOfBooksInCell = _parentBookShelfView.numberOfBooksInCell;
    
    _bookViewSpacingWidth = (cellWidth - 2 * cellMarginWidth) / (numOfBooksInCell * kRatio_width_spacing + (numOfBooksInCell - 1));
    
    _bookViewWidth = _bookViewSpacingWidth * kRatio_width_spacing;
    _bookViewHeight = _bookViewWidth * kRatio_height_width;
}

- (void)layoutSubviews {
    //NSLog(@"bookViewContainer layout");
    CGRect visibleRect = [self bounds];
    //NSLog(@"visibleRect %@", NSStringFromCGRect(visibleRect));
    
    NSInteger numberOfBooksInCell = _parentBookShelfView.numberOfBooksInCell;
    
    NSInteger numberOfBooks = [_parentBookShelfView.dataSource numberOfBooksInBookShelfView:_parentBookShelfView];
    
    NSInteger numberOfCells = ceilf((float)numberOfBooks / (float)numberOfBooksInCell);
    
    
    NSInteger firstNeededRow = MAX(0, floorf(CGRectGetMinY(visibleRect) / _parentBookShelfView.cellHeight));
    NSInteger lastNeededRow = MIN(numberOfCells - 1, floorf(CGRectGetMaxY(visibleRect) / _parentBookShelfView.cellHeight));
    
    //NSLog(@"\n------------\nfirstNeededRow:%d firstVisibleRow:%d\nlastNeededRow: %d lastVisibleRow: %d\n************", firstNeededRow, _firstVisibleRow, lastNeededRow, _lastVisibleRow);
    
    CGFloat cellHeight = _parentBookShelfView.cellHeight;
    CGFloat bookViewBottomOffset = _parentBookShelfView.bookViewBottomOffset;
    CGFloat cellMarginWidth = _parentBookShelfView.cellMarginWidth;
    
    // Discussion: Use the visible rect to remove invisible bookView currently. Also can use the row to remove
    for (GSBookView *bookView in [self subviews]) {
        // the bookView's frame is not unified with the row, but the cell's frame is. So use the cellFrame to see if it's needed to remove the bookView
        CGRect cellFrame = CGRectMake(0, CGRectGetMaxY(bookView.frame) - bookViewBottomOffset, visibleRect.size.width, cellHeight);
        if (!CGRectIntersectsRect(cellFrame, visibleRect)) {
            [_reuseableBookViews addObject:bookView];
            [bookView removeFromSuperview];
        }
    }
    
    for (int row = firstNeededRow; row <= lastNeededRow; row++) {
        BOOL isRowMissing = (_firstVisibleRow > row || _lastVisibleRow < row);
        if (isRowMissing) {
            for (int col = 0; col < numberOfBooksInCell; col++) {
                NSInteger index = row * numberOfBooksInCell + col;
                if (index >= numberOfBooks) {
                    break;
                }
                
                GSBookView *bookView = [_parentBookShelfView.dataSource bookShelfView:_parentBookShelfView bookViewAtIndex:index];
                
                bookView.tag = index; // set the tag as the index
                
                CGFloat originX = cellMarginWidth + col * (_bookViewWidth + _bookViewSpacingWidth);
                CGFloat originY = row * cellHeight + bookViewBottomOffset - _bookViewHeight;
                
                [bookView setFrame:CGRectMake(originX, originY, _bookViewWidth, _bookViewHeight)];
                
                //NSLog(@"bookView Frame:%@", NSStringFromCGRect(bookView.frame));
                
                [self addSubview:bookView];
                
            }
        }
        
    }
    
    _firstVisibleRow = firstNeededRow;
    _lastVisibleRow = lastNeededRow;
}

#pragma mark - View For Point

- (UIView *)bookViewAtPoint:(CGPoint)point {
    CGRect visibleRect = [self bounds];
    
    return nil;
}

#pragma mark - Gesture Recognizer

- (void)handleLongPressGesture:(UILongPressGestureRecognizer *)gestureRecognizer {
    
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        CGPoint touchPoint = [gestureRecognizer locationInView:self];
        BOOL dragAndDropEnable = _parentBookShelfView.dragAndDropEnabled;
        UIView *view = [self hitTest:touchPoint withEvent:nil];
        
        NSLog(@"viewClass:%@", NSStringFromClass([view class]));
        if (dragAndDropEnable && view != self) {
            _dragView = view;
            [self growAnimationAtPoint:touchPoint forView:_dragView];
            _isDragViewPickedUp = YES;
        }
    }
    else if (gestureRecognizer.state == UIGestureRecognizerStateChanged) {
        if (_isDragViewPickedUp) {
            CGPoint touchPoint = [gestureRecognizer locationInView:self];
            _dragView.center = touchPoint;
        }
    }
    else if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {
        if (_isDragViewPickedUp) {
            
        }
    }
}

#pragma mark - Animation 

- (void)growAnimationAtPoint:(CGPoint)point forView:(UIView *)view {
    [UIView animateWithDuration:kGrow_animation_duration animations:^{
        view.transform = CGAffineTransformMakeScale(1.2, 1.2);
        view.center = point;
    }];
}

- (void)shrinkAnimationToPoint:(CGPoint)point forView:(UIView *)view {
    
}

@end