//
//  ViewController.m
//  BluetoothDemo
//
//  Created by James on 16/7/18.
//  Copyright © 2016年 Apple. All rights reserved.
//


#import "ViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import "DetailViewController.h"

#define kMI_STEP @"FF06"
#define kMI_BUTERY @"FF0C"
#define kMI_SHAKE @"2A06"
#define kMI_DEVICE @"FF01"

@interface ViewController () <CBCentralManagerDelegate, CBPeripheralDelegate, UITableViewDelegate, UITableViewDataSource,DetailViewControllerDelegate>
@property (nonatomic, strong) CBCentralManager* centralManager;//管理中心
@property (nonatomic, strong) UITableView* tableView;
@property (nonatomic, strong) NSMutableArray* arrayM;//用于记录扫描到的蓝牙设备
@property (nonatomic, assign) NSInteger selectedItem;//用于记录所选择的设备
@property (nonatomic, strong) CBPeripheral *peripheral;
@property (nonatomic, strong) CBCharacteristic *theSakeCC;
@property (nonatomic, copy) NSString *infoStr;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.view addSubview:self.tableView];
    //生成一个串行队列，队列中的block按照先进先出（FIFO）的顺序去执行，实际上为单线程执行。第一个参数是队列的名称，在调试程序时会非常有用，所有尽量不要重名了。
    dispatch_queue_t centralQueue = dispatch_queue_create("james", DISPATCH_QUEUE_SERIAL);
    self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:centralQueue];
    
    self.title = @"选择要连接的蓝牙设备";
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
//连接蓝牙设备
- (void)connectBluetooh:(CBPeripheral *)peripheral {
    NSLog(@"connect start");
    self.peripheral.delegate = self;
   
    [self.centralManager connectPeripheral:peripheral options:nil];
//    [self.centralManager connectPeripheral:peripheral
//                       options:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:CBConnectPeripheralOptionNotifyOnDisconnectionKey]];
}
//连接成功
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    [self.centralManager stopScan];
    self.title = @"连接成功";
    self.peripheral = peripheral;
    
    peripheral.delegate = self;
    [peripheral discoverServices:nil];
    
    NSLog(@"Did connect to peripheral: %@", peripheral);
    [self alertWithTitle:[NSString stringWithFormat:@"connected %@ success",peripheral.name] finished:^{
        DetailViewController *detailVC = [[UIStoryboard storyboardWithName:@"Main" bundle:nil]instantiateViewControllerWithIdentifier:@"DetailViewController"];
        detailVC.infoStr = self.infoStr;
        detailVC.delegate = self;
        [self.navigationController pushViewController:detailVC animated:YES];
    }];
    

    
    
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    for (CBService *server in peripheral.services) {
        [self.peripheral discoverCharacteristics:nil forService:server];
    }
}

//断开连接
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    [self alertWithTitle:@"与外设断开连接" finished:^{
        [self.navigationController popToRootViewControllerAnimated:YES];
        self.title = @"请选择要连接的蓝牙设备";
    }];
    NSLog(@"与外设备断开连接 %@: %@", [peripheral name], [error localizedDescription]);
    self.title = @"连接已断开";
}

//扫描到特征
-(void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error{
    if (error)
    {
        NSLog(@"扫描外设的特征失败！%@->%@-> %@",peripheral.name,service.UUID, [error localizedDescription]);
        self.title = @"find characteristics error.";
        return;
    }
    
    NSLog(@"扫描到外设服务特征有：%@->%@->%@",peripheral.name,service.UUID,service.characteristics);
    //获取Characteristic的值
    for (CBCharacteristic *characteristic in service.characteristics){
        {
            [peripheral setNotifyValue:YES forCharacteristic:characteristic];
            
            //步数
            if ([characteristic.UUID.UUIDString isEqualToString:kMI_STEP])
            {
                [peripheral readValueForCharacteristic:characteristic];
            }
            
            //电池电量
            else if ([characteristic.UUID.UUIDString isEqualToString:kMI_BUTERY])
            {
                [peripheral readValueForCharacteristic:characteristic];
            }
            
            else if ([characteristic.UUID.UUIDString isEqualToString:kMI_SHAKE])
            {
                //震动
                self.theSakeCC = characteristic;
            }
            
            //设备信息
            else if ([characteristic.UUID.UUIDString isEqualToString:kMI_DEVICE])
            {
                [peripheral readValueForCharacteristic:characteristic];
            }
            
            
            
        }
    }
    
    
}
#pragma mark 设备信息处理
//扫描到具体的值
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error
{
    if (error) {
        NSLog(@"扫描外设的特征失败！%@-> %@",peripheral.name, [error localizedDescription]);
        self.title = @"find value error.";
        return;
    }
    NSLog(@"%@ %@",characteristic.UUID.UUIDString,characteristic.value);
    self.infoStr = [NSMutableString string];
    if ([characteristic.UUID.UUIDString isEqualToString:kMI_STEP]) {
        Byte *steBytes = (Byte *)characteristic.value.bytes;
        int steps = TCcbytesValueToInt(steBytes);
        NSLog(@"步数：%d",steps);
        self.infoStr = [NSString stringWithFormat:@"步数：%d\n",steps];
    }
    else if ([characteristic.UUID.UUIDString isEqualToString:kMI_BUTERY])
    {
        Byte *bufferBytes = (Byte *)characteristic.value.bytes;
        int buterys = TCcbytesValueToInt(bufferBytes)&0xff;
        NSLog(@"电池：%d%%",buterys);
        self.infoStr = [self.infoStr stringByAppendingString:[NSString stringWithFormat:@"电量: %d\n]",buterys]];
    }
    else if ([characteristic.UUID.UUIDString isEqualToString:kMI_DEVICE])
    {
        Byte *infoByts = (Byte *)characteristic.value.bytes;
        //这里解析infoByts得到设备信息
        
        
    }
    NSLog(@"-----%@",self.infoStr);
    
}

#pragma mark - detailViewControllerDelegate
- (void)detailViewController:(DetailViewController *)detailVc opration:(Opration)opration {
    switch (opration) {
        case oprationShake:{
            Byte zd[1] = {2};
            NSData *theData = [NSData dataWithBytes:zd length:1];
            [self.peripheral writeValue:theData forCharacteristic:self.theSakeCC type:CBCharacteristicWriteWithoutResponse];
        }
            break;
        case oprationStopShake:{
            Byte zd[1] = {0};
            NSData *theData = [NSData dataWithBytes:zd length:1];
            [self.peripheral writeValue:theData forCharacteristic:self.theSakeCC type:CBCharacteristicWriteWithoutResponse];
            break;
        }
        case oprationCloseConnected:
        {
            [self.centralManager cancelPeripheralConnection:self.peripheral];
            self.theSakeCC = nil;
            self.peripheral = nil;
        }
            break;

    }
}

//4个字节Bytes 转 int
unsigned int  TCcbytesValueToInt(Byte *bytesValue) {
    unsigned int  intV;
    intV = (unsigned int ) ( ((bytesValue[3] & 0xff)<<24)
                            |((bytesValue[2] & 0xff)<<16)
                            |((bytesValue[1] & 0xff)<<8)
                            |(bytesValue[0] & 0xff));
    return intV;
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
            if (finish) {
                finish();
            }
        }];
        [alertVC addAction:action];
        [self presentViewController:alertVC animated:YES completion:^{

        }];
    });

}
@end
