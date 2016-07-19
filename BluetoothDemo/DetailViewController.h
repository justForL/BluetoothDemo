//
//  DetailViewController.h
//  BluetoothDemo
//
//  Created by James on 16/7/19.
//  Copyright © 2016年 Apple. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DetailViewController;

typedef enum {
    oprationShake,
    oprationStopShake,
    oprationCloseConnected
}Opration;

@protocol DetailViewControllerDelegate <NSObject>

- (void)detailViewController:(DetailViewController *)detailVc opration:(Opration)opration;

@end
@interface DetailViewController : UIViewController
@property (nonatomic, assign) id<DetailViewControllerDelegate> delegate;
@property (nonatomic, copy) NSString *infoStr;
@end
