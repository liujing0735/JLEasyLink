//
//  ViewController.m
//  JLEasyLink
//
//  Created by JasonLiu on 2018/8/28.
//  Copyright © 2018年 trudian. All rights reserved.
//

#import "ViewController.h"
#import "EasyLinkSDK/EasyLink.h"

@interface ViewController () <EasyLinkFTCDelegate>

@property (weak, nonatomic) IBOutlet UITextField *ssidTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UITextField *extraDataTextField;
@property (weak, nonatomic) IBOutlet UITextField *intervalTextField;
@property (weak, nonatomic) IBOutlet UIButton *configButton;
@property (weak, nonatomic) IBOutlet UITextView *logTextView;

@property (strong, nonatomic) EASYLINK *easyLink;
@property (strong, nonatomic) NSMutableDictionary *wifiConfig;
@end

@implementation ViewController

- (EASYLINK *)easyLink {
    if (!_easyLink) {
        _easyLink = [[EASYLINK alloc] initForDebug:YES WithDelegate:self];
    }
    return _easyLink;
}

- (NSMutableDictionary *)wifiConfig {
    if (!_wifiConfig) {
        _wifiConfig = [[NSMutableDictionary alloc] init];
    }
    return _wifiConfig;
}

- (IBAction)touchUpInsideForBtn:(UIButton *)sender {
    if (sender == _configButton) {
        [_configButton setSelected:!_configButton.selected];
        if (_configButton.selected) {
            [self.wifiConfig removeAllObjects];
            
            [self.wifiConfig setObject:[_ssidTextField.text dataUsingEncoding:NSUTF8StringEncoding] forKey:KEY_SSID];
            [self.wifiConfig setObject:_passwordTextField.text forKey:KEY_PASSWORD];
            
            [self.wifiConfig setObject:@YES forKey:@"DHCP"];
            [self.wifiConfig setObject:[EASYLINK getIPAddress] forKey:KEY_IP];
            [self.wifiConfig setObject:[EASYLINK getNetMask] forKey:KEY_NETMASK];
            [self.wifiConfig setObject:[EASYLINK getGatewayAddress] forKey:KEY_GATEWAY];
            [self.wifiConfig setObject:[EASYLINK getGatewayAddress] forKey:KEY_DNS1];
            
            [self.easyLink prepareEasyLink:self.wifiConfig info:nil mode:EASYLINK_V2_PLUS encrypt:nil];
            NSLog(@"transmitSettings 开始广播");
            [self.easyLink transmitSettings];
        }else {
            NSLog(@"stopTransmitting 停止广播");
            [self.easyLink stopTransmitting];
        }
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    //[self redirectSTD:STDIN_FILENO];
    [self redirectSTD:STDOUT_FILENO];
    [self redirectSTD:STDERR_FILENO];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (![[EASYLINK ssidForConnectedNetwork] isEqualToString:@""]) {
        [_ssidTextField setText:[EASYLINK ssidForConnectedNetwork]];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self.easyLink unInit];
    self.easyLink = nil;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}

- (void)onFound:(NSNumber *)client withName:(NSString *)name mataData: (NSDictionary *)mataDataDict {
    NSLog(@"onFound:withName:mataData: 配置成功");
    NSLog(@"%@", mataDataDict);
}

- (void)onFoundByFTC:(NSNumber *)client withConfiguration:(NSDictionary *)configDict {
    NSLog(@"onFoundByFTC:withConfiguration: 配置成功");
    NSLog(@"%@", configDict);
}

- (void)onDisconnectFromFTC:(NSNumber *)client withError:(bool)err {
    NSLog(@"onDisconnectFromFTC:withError: 连接断开");
}

- (void)redirectNotificationHandle:(NSNotification *)nf{
    NSData *data = [[nf userInfo] objectForKey:NSFileHandleNotificationDataItem];
    NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    self.logTextView.text = [NSString stringWithFormat:@"%@\n%@",self.logTextView.text, str];
    NSRange range;
    range.location = [self.logTextView.text length] - 1;
    range.length = 0;
    [self.logTextView scrollRangeToVisible:range];
    
    [[nf object] readInBackgroundAndNotify];
}

- (void)redirectSTD:(int )fd{
    NSPipe * pipe = [NSPipe pipe] ;
    NSFileHandle *pipeReadHandle = [pipe fileHandleForReading] ;
    dup2([[pipe fileHandleForWriting] fileDescriptor], fd) ;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(redirectNotificationHandle:)
                                                 name:NSFileHandleReadCompletionNotification
                                               object:pipeReadHandle] ;
    [pipeReadHandle readInBackgroundAndNotify];
}

@end
