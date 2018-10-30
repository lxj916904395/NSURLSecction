//
//  ZFDownloadNetwork.m
//  NSURLSecction
//
//  Created by zhongding on 2018/10/29.
//

#import "ZFDownloadNetwork.h"

#define weakSelf __weak typeof(self)weakself = self;

@interface ZFDownloadNetwork()<NSURLSessionDelegate>
@property(strong ,nonatomic) NSURLSession *session;

//下载任务
@property(strong ,nonatomic) NSMutableDictionary *taskDict;
//下载任务状态
@property(strong ,nonatomic) NSMutableDictionary *taskStatueDict;

@end
@implementation ZFDownloadNetwork

+ (instancetype)sharedManager{
    static id instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [ZFDownloadNetwork new];
    });
    return instance;
}

- (NSURLSession*)session{
    if (!_session) {
        
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:[self currentDateStr]];
        //超时时间
        config.timeoutIntervalForRequest = 20;
        //是否允许使用蜂窝网络
        config.allowsCellularAccess = YES;
        
        _session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:[NSOperationQueue mainQueue]];
        
    }
    return _session;
}

- (NSURLSessionDownloadTask *)downloadWithUrl:(NSString*)urlstring{
    if (!urlstring || urlstring.length==0) {
        NSLog(@"url为空");
        return nil;
    }
    
  //无断点续传数据
    NSFileManager *fm   = [NSFileManager defaultManager];
    NSData *datas       = [fm contentsAtPath:[self getFileUrl:urlstring temp:YES]];
    NSData* resumeData  = datas;
    
    
    //存在断点续传数据
    if (resumeData) {
        NSURLSessionDownloadTask *task = [self.session downloadTaskWithResumeData:resumeData];
        [task resume];
         self.taskDict[urlstring] = task;
        self.taskStatueDict[urlstring] = [NSNumber numberWithBool:NO];
        return task;
    }
    
    
    //已经存在下载
    NSURLSessionDownloadTask *exitTask = self.taskDict[urlstring];
    if (exitTask) {
        [exitTask resume];
        self.taskStatueDict[urlstring] = [NSNumber numberWithBool:NO];
        return exitTask;
    }
    
    //创建新的下载任务
    NSURL *url = [NSURL URLWithString:urlstring];
    
    NSURLSessionDownloadTask *task = [self.session downloadTaskWithURL:url];
    [task resume];
    //存储下载任务
    self.taskDict[urlstring] = task;
    
    return task;
//    [NSTimer scheduledTimerWithTimeInterval:3 repeats:YES block:^(NSTimer * _Nonnull timer) {
//        [self downloadWithUrl:urlstring];
//    }];
}

#pragma mark ***************** method
//杀掉app后 不至于下载的部分文件全部丢失
- (void)saveTmpFile:(NSString *)urlstring pause:(BOOL)pause{
    __block NSURLSessionDownloadTask *task= self.taskDict[urlstring];
    if (task) {
        weakSelf;
        [task cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
            [resumeData writeToFile:[weakself getFileUrl:urlstring temp:YES] atomically:NO];
            
            task =  [self.session downloadTaskWithResumeData:resumeData];
           if(pause)
               [task suspend];
            else
               [task resume];
            
            //存储下载任务
            self.taskDict[urlstring] = task;
        }];
    }
}


//取消下载
- (void)cancelDownload:(NSString*)urlstring{
    weakSelf;
    NSURLSessionDownloadTask *task= self.taskDict[urlstring];
    if(task)[task cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
        //数据写入沙盒,下次下载之间从当前位置开始
        [resumeData writeToFile:[weakself getFileUrl:urlstring temp:YES] atomically:NO];
    }];
}


//暂停、继续
- (void)pauseOrContinune:(NSString*)urlstring{

    BOOL supend = [self.taskStatueDict[urlstring] boolValue];
   __block NSURLSessionDownloadTask *task= self.taskDict[urlstring];
    if(!task)task = [self downloadWithUrl:urlstring];
    if (supend) {
        //继续下载
        [task resume];
    }else{
        //暂停下载
        [task suspend];
        
        //保存临时文件
        weakSelf;
        //只有调用任务的取消方法才能拿到resumeData，同时把task置为空
        [task cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
            [resumeData writeToFile:[weakself getFileUrl:urlstring temp:YES] atomically:NO];
            task = nil;
            self.taskDict[urlstring] = nil;
        }];
    }
    supend = !supend;
    self.taskStatueDict[urlstring] = [NSNumber numberWithBool:supend];

}



#pragma mark ***************** NSURLSessionDelegate
-(void)URLSession:(nonnull NSURLSession *)session downloadTask:(nonnull NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite{
    
    //下载进度
    float progress = 1.0 * totalBytesWritten / totalBytesExpectedToWrite;
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(downloadProgress:identifier:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
              [self.delegate downloadProgress:progress identifier:downloadTask.response.URL.absoluteString];
        });
    }
}


/*
 2.下载完成之后调用该方法
 */
-(void)URLSession:(nonnull NSURLSession *)session downloadTask:(nonnull NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(nonnull NSURL *)location{
   
    NSString *urlstring = downloadTask.response.URL.absoluteString;
    NSLog(@"location == %@",location.path);
    
    //拼接Doc 更换的路径
    NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES) lastObject];
    NSString *file = [documentsPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.mp4",[self fileName:urlstring]]];
    
    //创建文件管理器
    NSFileManager *manager = [NSFileManager defaultManager];
    if ([manager fileExistsAtPath: file]) {
        //如果文件夹下有同名文件  则将其删除
        [manager removeItemAtPath:file error:nil];
    }
    NSError *saveError;
    [manager moveItemAtURL:location toURL:[NSURL URLWithString:file] error:&saveError];
    
    //将视频资源从原有路径移动到自己指定的路径
    BOOL success = [manager copyItemAtPath:location.path toPath:file error:nil];
    if (success) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSURL *url = [[NSURL alloc]initFileURLWithPath:file];
            if(self.delegate && [self.delegate respondsToSelector:@selector(downloadSuccess:identifier:)])
                [self.delegate downloadSuccess:url identifier:urlstring];
        });
    }
    //已经拷贝 删除缓存文件
    [manager removeItemAtPath:location.path error:nil];
    
    [manager removeItemAtPath:[self getFileUrl:urlstring temp:YES] error:nil];
    
}

//下载失败调用
-(void)URLSession:(nonnull NSURLSession *)session task:(nonnull NSURLSessionTask *)task didCompleteWithError:(nullable NSError *)error{
    if (self.delegate && [self.delegate respondsToSelector:@selector(downloadError:identifier:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate downloadError:error identifier:task.response.URL.absoluteString];
        });
    }
}

- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session{
    NSLog(@"所有后台任务已经完成: %@",session.configuration.identifier);
}

#pragma mark ***************** tools

//未下载完的临时文件url地址
-(NSString*)getFileUrl:(NSString*)urlstring temp:(BOOL)temp{
  
    NSString *docPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    
    NSString *fileType = @"mp4";
    if(temp)fileType = @"tmp";
    
    NSString *filePath = [docPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.%@",[self fileName:urlstring],fileType]];
    
    NSLog(@"%@",filePath);
    return filePath;
}

- (NSString*)fileName:(NSString*)urlstring{
    NSArray*array = [urlstring componentsSeparatedByString:@"/"];
    
    NSArray*array1 = [[array lastObject] componentsSeparatedByString:@"."];
    NSString*filename = array1[0];
    return filename;
}


//获取当前时间 下载id标识用
- (NSString *)currentDateStr{
    return [NSString stringWithFormat:@"%.f",[self nowTimeInterval]];
}

- (NSTimeInterval)nowTimeInterval{
    NSDate *currentDate = [NSDate date];//获取当前时间，日期
    NSTimeInterval timeInterval = [currentDate timeIntervalSince1970];
    return timeInterval;
}


#pragma mark ***************** setter\getter
- (NSMutableDictionary*)taskDict{
    if (!_taskDict) {
        _taskDict = [NSMutableDictionary new];
    }
    return _taskDict;
}

- (NSMutableDictionary*)taskStatueDict{
    if (!_taskStatueDict) {
        _taskStatueDict = [NSMutableDictionary new];
    }
    return _taskStatueDict;
}


@end
