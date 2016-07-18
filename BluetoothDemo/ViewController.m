//
//  ViewController.m
//  BluetoothDemo
//
//  Created by James on 16/7/18.
//  Copyright © 2016年 Apple. All rights reserved.
//

#import "PeripheralModel.h"
#import "ViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>
@interface ViewController () <CBCentralManagerDelegate, CBPeripheralDelegate, UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong) CBCentralManager* centralManager;//管理中心
@property (nonatomic, strong) UITableView* tableView;
@property (nonatomic, strong) NSMutableArray* arrayM;//用于记录扫描到的蓝牙设备
@property (nonatomic, assign) NSInteger selectedItem;//用于记录所选择的设备
@property (nonatomic, strong) CBPeripheral *peripheral;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.view addSubview:self.tableView];
    //生成一个串行队列，队列中的block按照先进先出（FIFO）的顺序去执行，实际上为单线程执行。第一个参数是队列的名称，在调试程序时会非常有用，所有尽量不要重名了。
    dispatch_queue_t centralQueue = dispatch_queue_create("com.manmanlai", DISPATCH_QUEUE_SERIAL);
    self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:centralQueue];
}
#pragma mark - CBCentralManagerDelegate & CBPeripheralDelegate
- (void)centralManagerDidUpdateState:(CBCentralManager*)central
{
    NSLog(@"%ld", central.state);
    //寻找CBPeripheral外设  这里的Service就是对应的UUID，如果为空，这scan所有service。
    [self.centralManager scanForPeripheralsWithServices:@[] options:nil];
}

- (void)centralManager:(CBCentralManager*)central didDiscoverPeripheral:(CBPeripheral*)peripheral advertisementData:(NSDictionary*)advertisementData RSSI:(NSNumber*)RSSI
{
    NSLog(@"name:%@", peripheral);
    //判断是否为空
    if (!peripheral || !peripheral.name || ([peripheral.name isEqualToString:@""])) {
        return;
    }
    //判断状态是否为CBPeripheralStateDisconnected
    if (!peripheral || (peripheral.state == CBPeripheralStateDisconnected)) {
        if (![self.arrayM containsObject:peripheral]) {
            [self.arrayM addObject:peripheral];
        }
        
        peripheral.delegate = self;
        NSLog(@"connectperipheral");
        [self.centralManager connectPeripheral:peripheral options:nil];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        //要把更新UI的操作放到主线程中,否则会报错
        [self.tableView reloadData];
    });
}
#pragma mark - tableViewDelegate
- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.arrayM.count;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cell"];
    }
    cell.textLabel.text = [self.arrayM[indexPath.row] name];
    NSUUID * uuid = (NSUUID *)[self.arrayM[indexPath.row] identifier];
    cell.detailTextLabel.text = uuid.UUIDString;
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    self.selectedItem = indexPath.row;
    [self connectBluetooh:self.arrayM[self.selectedItem]];
}

#pragma mark - connectbluetooh

- (void)connectBluetooh:(CBPeripheral *)peripheral {
    NSLog(@"connect start");
//    _testPeripheral = nil;
    
    [self.centralManager connectPeripheral:peripheral
                       options:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:CBConnectPeripheralOptionNotifyOnDisconnectionKey]];
    
    //开一个定时器监控连接超时的情况
//    connectTimer = [NSTimer scheduledTimerWithTimeInterval:5.0f target:self selector:@selector(connectTimeout:) userInfo:peripheral repeats:NO];
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    [self.centralManager stopScan];
    
    NSLog(@"Did connect to peripheral: %@", peripheral);
    [self alertWithTitle:[NSString stringWithFormat:@"connected %@ success",peripheral.name] finished:nil];
    
    self.peripheral = peripheral;
    
    [peripheral setDelegate:self];
    
    [peripheral discoverServices:nil];
    
    
}


#pragma mark - lazyload
- (NSMutableArray*)arrayM
{
    if (_arrayM == nil) {
        _arrayM =    [NSMutableArray array];
    }
    return _arrayM;
}

- (UITableView*)tableView
{
    if (_tableView == nil) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 20, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height) style:UITableViewStylePlain];
        _tableView.delegate = self;
        _tableView.dataSource = self;
    }
    return _tableView;
}

- (void)alertWithTitle:(NSString *)title finished:(void (^)())finish {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"提示" message:title preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *action = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            
        }];
        [alertVC addAction:action];
        [self presentViewController:alertVC animated:YES completion:^{
            if (finish) {
                finish();
            }
        }];
    });

}
@end
