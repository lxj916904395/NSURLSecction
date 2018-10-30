//
//  ViewController.m
//  NSURLSecction
//
//  Created by zhongding on 2018/10/29.
//

#import "ViewController.h"
#import "ZFNetwork.h"
#import "ZFDownloadNetwork.h"

#import <AVKit/AVKit.h>

@interface ViewController ()<ZFDownloadNetworkDelegate>
@property (weak, nonatomic) IBOutlet UILabel *progressLabel;
@property(strong ,nonatomic) NSString *urlstring;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
//    NSString *url = @"http://api.tzyj91.com/article";
//    [[ZFNetwork sharedManager] postWithUrl:url params:nil handle:^(id response) {
//
//    }];
    self.urlstring = @"https://pic.ibaotu.com/00/48/71/79a888piCk9g.mp4";
    
}

//开始下载
- (IBAction)startDownload:(id)sender {
    ZFDownloadNetwork *downloadNetwork =  [ZFDownloadNetwork sharedManager];
    downloadNetwork.delegate = self;
    [downloadNetwork downloadWithUrl:self.urlstring];
}

//暂停、继续下载
- (IBAction)pauseOrContinune:(id)sender {
    [[ZFDownloadNetwork sharedManager] pauseOrContinune:self.urlstring];
}

//取消下载
- (IBAction)cancelDownload:(id)sender {
    [[ZFDownloadNetwork sharedManager] cancelDownload:self.urlstring];

}

#pragma mark ***************** ZFDownloadNetworkDelegate

- (void)downloadProgress:(float)progress identifier:(NSString*)taskIdentifier{
    
    self.progressLabel.text = [NSString stringWithFormat:@"%.f%%",progress*100];
}

- (void)downloadSuccess:(NSURL*)url identifier:(NSString*)identifier{
    [self paly:url];
}

//传入本地url 进行视频播放
-(void)paly:(NSURL*)playUrl{
    
    //系统的视频播放器
    AVPlayerViewController *controller = [[AVPlayerViewController alloc]init];
    //播放器的播放类
    AVPlayer * player = [[AVPlayer alloc]initWithURL:playUrl];
    controller.player = player;
    //自动开始播放
    [controller.player play];
    //推出视屏播放器
    [self  presentViewController:controller animated:YES completion:nil];
}
@end
