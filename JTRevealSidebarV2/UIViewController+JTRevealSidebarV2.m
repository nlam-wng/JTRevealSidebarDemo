/*
 * This file is part of the JTRevealSidebar package.
 * (c) James Tang <mystcolor@gmail.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "UIViewController+JTRevealSidebarV2.h"
#import "UINavigationItem+JTRevealSidebarV2.h"
#import "JTRevealSidebarV2Delegate.h"
#import <objc/runtime.h>

#define SIDEBAR_VIEW_TAG 10000

@interface UIViewController (JTRevealSidebarV2Private)

- (UIViewController *)selectedViewController;
- (void)revealLeftSidebar:(BOOL)showLeftSidebar;
- (void)revealRightSidebar:(BOOL)showRightSidebar;
- (void) styleSelectedViewController: (BOOL) enabled;

@end

@implementation UIViewController (JTRevealSidebarV2)

static char *revealedStateKey;

- (void)setRevealedState:(JTRevealedState)revealedState {
    JTRevealedState currentState = self.revealedState;

    if (revealedState == currentState) {
        return;
    }

    id <JTRevealSidebarV2Delegate> delegate = [self selectedViewController].navigationItem.revealSidebarDelegate;
    // notify delegate for controller will change state
    if ([delegate respondsToSelector:@selector(willChangeRevealedStateForViewController:)]) {
        [delegate willChangeRevealedStateForViewController:self];
    }

    objc_setAssociatedObject(self, &revealedStateKey, [NSNumber numberWithInt:revealedState], OBJC_ASSOCIATION_RETAIN);

    switch (currentState) {
        case JTRevealedStateNo:
            if (revealedState == JTRevealedStateLeft) {
                [self revealLeftSidebar:YES];
            } else if (revealedState == JTRevealedStateRight) {
                [self revealRightSidebar:YES];
            } else {
                // Do Nothing
            }
            break;
        case JTRevealedStateLeft:
            if (revealedState == JTRevealedStateNo) {
                [self revealLeftSidebar:NO];
            } else if (revealedState == JTRevealedStateRight) {
                [self revealLeftSidebar:NO];
                [self revealRightSidebar:YES];
            } else {
                [self revealLeftSidebar:YES];
            }
            break;
        case JTRevealedStateRight:
            if (revealedState == JTRevealedStateNo) {
                [self revealRightSidebar:NO];
            } else if (revealedState == JTRevealedStateLeft) {
                [self revealRightSidebar:NO];
                [self revealLeftSidebar:YES];
            } else {
                [self revealRightSidebar:YES];
            }
        default:
            break;
    }
}

- (JTRevealedState)revealedState {
    return (JTRevealedState)[objc_getAssociatedObject(self, &revealedStateKey) intValue];
}


- (CGAffineTransform)baseTransform {
    CGAffineTransform baseTransform;
    
    return self.view.transform;
    switch (self.interfaceOrientation) {
        case UIInterfaceOrientationPortrait:
            baseTransform = CGAffineTransformIdentity;
            break;
        case UIInterfaceOrientationLandscapeLeft:
            baseTransform = CGAffineTransformMakeRotation(-M_PI/2);
            break;
        case UIInterfaceOrientationLandscapeRight:
            baseTransform = CGAffineTransformMakeRotation(M_PI/2);
            break;
        default:
            baseTransform = CGAffineTransformMakeRotation(M_PI);
            break;
    }
    return baseTransform;
}

// Converting the applicationFrame from UIWindow is founded to be always correct
- (CGRect)applicationViewFrame {
    CGRect appFrame = [[UIScreen mainScreen] applicationFrame];
    CGRect expectedFrame = [self.view convertRect:appFrame fromView:nil];
    return expectedFrame;
}

- (void)toggleRevealState:(JTRevealedState)openingState {
    JTRevealedState state = openingState;
    if (self.revealedState == openingState) {
        state = JTRevealedStateNo;
    }
    [self setRevealedState:state];
}
- (void) resetRevealedStateView {
    id <JTRevealSidebarV2Delegate> delegate = [self selectedViewController].navigationItem.revealSidebarDelegate;
    
    if (! [delegate respondsToSelector:@selector(viewForLeftSidebar)]) {
        return;
    }
    
    UIView *revealedView = [delegate viewForLeftSidebar];
    CGFloat width = CGRectGetWidth(revealedView.frame);
    
    if (self.revealedState == JTRevealedStateLeft) {
        [self styleSelectedViewController:NO];
        [UIView beginAnimations:@"styleSelectedViewController" context:nil];
        //        self.view.transform = CGAffineTransformTranslate([self baseTransform], width, 0);
        self.view.frame = (CGRect) {CGPointMake(width, 0), self.view.frame.size};
        [UIView setAnimationDidStopSelector:@selector(resetAnimationDidStop:finished:context:)];
        
        
    } else if (self.revealedState == JTRevealedStateNo) {
        [self styleSelectedViewController:NO];
        [UIView beginAnimations:@"" context:nil];
        //        self.view.transform = CGAffineTransformTranslate([self baseTransform], -width, 0);
        self.view.frame = (CGRect){CGPointZero, self.view.frame.size};
    } else {
        // Not supported
        return;
    }
    [UIView setAnimationDuration:0.1f];
    [UIView setAnimationCurve:UIViewAnimationCurveLinear];
    [UIView setAnimationDelegate:self];
    
    //NSLog(@"%@", NSStringFromCGAffineTransform(self.view.transform));
    
    
    [UIView commitAnimations];
}
- (void) setupRevealedState: (JTRevealedState) state {
    if (self.revealedState != JTRevealedStateNo) {
        // not supported
        return;
    }
    switch (state) {
        case JTRevealedStateLeft: 
        {
            id <JTRevealSidebarV2Delegate> delegate = [self selectedViewController].navigationItem.revealSidebarDelegate;
            
            if ( ! [delegate respondsToSelector:@selector(viewForLeftSidebar)]) {
                return;
            }
            
            UIView *revealedView = [delegate viewForLeftSidebar];
            revealedView.tag = SIDEBAR_VIEW_TAG;
            
            [self.view.superview insertSubview:revealedView belowSubview:self.view];
            [self styleSelectedViewController:YES];
            
            break;
        }
        default:
            // not supported
            break;
    }
}

@end


@implementation UIViewController (JTRevealSidebarV2Private)

- (UIViewController *)selectedViewController {
    return self;
}
- (void)animationDidStop2:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context {
    if ([animationID isEqualToString:@"hideSidebarView"]) {
        [self styleSelectedViewController:YES];
    } 
    
    // notify delegate for controller changed state
    id <JTRevealSidebarV2Delegate> delegate = 
        [self selectedViewController].navigationItem.revealSidebarDelegate;
    if ([delegate respondsToSelector:@selector(didChangeRevealedStateForViewController:)]) {
        [delegate didChangeRevealedStateForViewController:self];
    }
}

- (void)resetAnimationDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context {
    [self styleSelectedViewController:YES];
//    [self performSelectorOnMainThread:@selector(styleSelectedViewController:) withObject:[NSNumber numberWithBool:YES] waitUntilDone:NO];
}

// Add styling to the selected view controller
- (void) styleSelectedViewController: (BOOL) revealed {
    id <JTRevealSidebarV2Delegate> delegate =
    [self selectedViewController].navigationItem.revealSidebarDelegate;
    if ([delegate respondsToSelector:@selector(styleViewController:revealed:)]) {
        [delegate styleViewController:self revealed: revealed];
    }
}

- (void)revealLeftSidebar:(BOOL)showLeftSidebar {
//    NSLog(@"revealLeftSidebar: reveal = %d", showLeftSidebar);

    id <JTRevealSidebarV2Delegate> delegate = [self selectedViewController].navigationItem.revealSidebarDelegate;

    if (! [delegate respondsToSelector:@selector(viewForLeftSidebar)]) {
        return;
    }
    UIView *revealedView = [delegate viewForLeftSidebar];
    revealedView.tag = SIDEBAR_VIEW_TAG;
    CGFloat width = CGRectGetWidth(revealedView.frame);

    if (showLeftSidebar) {
        [self.view.superview insertSubview:revealedView belowSubview:self.view];
        
        [UIView beginAnimations:@"" context:nil];
//        self.view.transform = CGAffineTransformTranslate([self baseTransform], width, 0);
        
//        self.view.frame = CGRectOffset(self.view.frame, width, 0);
        self.view.frame = (CGRect) {CGPointMake(width, 0), self.view.frame.size};

        [self styleSelectedViewController:YES];
        
    } else {
        [self styleSelectedViewController:NO];
        [UIView beginAnimations:@"hideSidebarView" context:(void *)SIDEBAR_VIEW_TAG];
//        self.view.transform = CGAffineTransformTranslate([self baseTransform], -width, 0);
        
        self.view.frame = (CGRect){CGPointZero, self.view.frame.size};
    }
    [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
    [UIView setAnimationDidStopSelector:@selector(animationDidStop2:finished:context:)];
    [UIView setAnimationDelegate:self];
    
    //NSLog(@"%@", NSStringFromCGAffineTransform(self.view.transform));


    [UIView commitAnimations];
}

- (void)revealRightSidebar:(BOOL)showRightSidebar {

    id <JTRevealSidebarV2Delegate> delegate = [self selectedViewController].navigationItem.revealSidebarDelegate;
    
    if ( ! [delegate respondsToSelector:@selector(viewForRightSidebar)]) {
        return;
    }

    UIView *revealedView = [delegate viewForRightSidebar];
    revealedView.tag = SIDEBAR_VIEW_TAG;
    CGFloat width = CGRectGetWidth(revealedView.frame);
    revealedView.frame = (CGRect){self.view.frame.size.width - width, revealedView.frame.origin.y, revealedView.frame.size};

    if (showRightSidebar) {
        [self.view.superview insertSubview:revealedView belowSubview:self.view];

        [UIView beginAnimations:@"" context:nil];
//        self.view.transform = CGAffineTransformTranslate([self baseTransform], -width, 0);
        
        self.view.frame = CGRectOffset(self.view.frame, -width, 0);
    } else {
        [UIView beginAnimations:@"hideSidebarView" context:(void *)SIDEBAR_VIEW_TAG];
//        self.view.transform = CGAffineTransformTranslate([self baseTransform], width, 0);
        self.view.frame = (CGRect){CGPointZero, self.view.frame.size};        
    }
    
    [UIView setAnimationDidStopSelector:@selector(animationDidStop2:finished:context:)];
    [UIView setAnimationDelegate:self];

//    NSLog(@"%@", NSStringFromCGAffineTransform(self.view.transform));
    
    [UIView commitAnimations];
}

@end


@implementation UINavigationController (JTRevealSidebarV2)

- (UIViewController *)selectedViewController {
    return self.topViewController;
}

@end