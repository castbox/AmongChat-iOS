//
//  UIButton+WSFlexibleTouch.h
//  WSFlexibleTouch_Example
//
//  Created by Wilson on 2018/7/23.
//  Copyright © 2018 devSC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIButton (WSFlexibleTouch)

/// default is false
@property (nonatomic) BOOL ws_disableFlexibleTouch NS_SWIFT_NAME(disableFlexibleTouch);

/// default is 0.25s. must large than 0.00s
@property (nonatomic) NSTimeInterval ws_flexibleTouchAnimationDuration NS_SWIFT_NAME(flexibleTouchAnimationDuration);

@end
