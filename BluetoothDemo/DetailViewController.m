//
//  DetailViewController.m
//  BluetoothDemo
//
//  Created by James on 16/7/19.
//  Copyright © 2016年 Apple. All rights reserved.
//

#import "DetailViewController.h"

@interface DetailViewController ()
@property (weak, nonatomic) IBOutlet UITextView *infoTF;

@end

@implementation DetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title=@"详细信息页";
//    self.infoTF.text = @"";
}

- (void)setInfoStr:(NSString *)infoStr {
    _infoStr = infoStr;
    self.infoTF.text = infoStr;
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
//震动
- (IBAction)shakeAction:(id)sender {
    if ([self.delegate respondsToSelector:@selector(detailViewController:opration:)]) {
        [self.delegate detailViewController:self opration:oprationShake];
    }
}
//停止震动
- (IBAction)stopShakeAction:(id)sender {
    if ([self.delegate respondsToSelector:@selector(detailViewController:opration:)]) {
        [self.delegate detailViewController:self opration:oprationStopShake];
    }
}
//关闭连接
- (IBAction)closeContectedAction:(id)sender {
    if ([self.delegate respondsToSelector:@selector(detailViewController:opration:)]) {
        [self.delegate detailViewController:self opration:oprationCloseConnected];
    }
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
