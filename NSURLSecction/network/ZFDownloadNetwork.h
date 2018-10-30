//
//  ZFDownloadNetwork.h
//  NSURLSecction
//
//  Created by zhongding on 2018/10/29.
//

#import <Foundation/Foundation.h>

@protocol ZFDownloadNetworkDelegate;
@interface ZFDownloadNetwork : NSObject

@property(weak ,nonatomic) id<ZFDownloadNetworkDelegate> delegate;

+ (instancetype)sharedManager;

- (NSURLSessionDownloadTask*)downloadWithUrl:(NSString*)urlstring;

- (void)pauseOrContinune:(NSString*)urlstring;

- (void)cancelDownload:(NSString*)urlstring;
@end

@protocol ZFDownloadNetworkDelegate <NSObject>
@optional

//下载成功
- (void)downloadSuccess:(NSURL*)url identifier:(NSString*)identifier;

//下载进度回调
- (void)downloadProgress:(float)progress identifier:(NSString*)taskIdentifier;

//下载出错
- (void)downloadError:(NSError*)error identifier:(NSString*)taskIdentifier;

@end
