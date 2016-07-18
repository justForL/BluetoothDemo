//
//  PeripheralModel.h
//  BluetoothDemo
//
//  Created by James on 16/7/18.
//  Copyright © 2016年 Apple. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PeripheralModel : NSObject
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *identifier;
@property (nonatomic, assign) NSInteger state;
@end
