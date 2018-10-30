//
//  ZFNetwork.m
//  NSURLSecction
//
//  Created by zhongding on 2018/10/29.
//

#import "ZFNetwork.h"
@interface ZFNetwork()<NSURLSessionDelegate>
//@property(strong ,nonatomic) NSURLSession *session;

@end
@implementation ZFNetwork

+ (instancetype)sharedManager{
    static id instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [ZFNetwork new];
    });
    return instance;
}


- (void)postWithUrl:(NSString*)urlstring params:(NSDictionary *)params handle:(ZFNetworkHandle)handle{
    
    NSURL *url = [NSURL URLWithString:urlstring];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    
    //是否允许使用蜂窝网络
    request.allowsCellularAccess = YES;
    //超时时间
    request.timeoutInterval = 20;
    
    //接受数据格式
    [request setValue:@"application/json/text" forHTTPHeaderField:@"Content-Type"];
    
    //post或者get
    request.HTTPMethod = @"POST";
    
    //请求体
    request.HTTPBody =  [[self convertToJSONData:params] dataUsingEncoding:NSUTF8StringEncoding];;
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request];
    
    [task resume];
}



#pragma mark ***************** NSURLSessionDelegate
// 1.接收到服务器的响应
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
    completionHandler(NSURLSessionResponseAllow);
}

// 返回body 多次返回 为什么 MTU限制  TCP 包按照顺序返回
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    
    NSLog(@"%@",[self converToDict:data]);
}

// 任务完成时调用或者失败
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    
    if(error == nil){
       
    }else{

    }
}

- (NSDictionary*)converToDict:(NSData*)data{

    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    return dict;
}

- (NSString*)convertToJSONData:(id)infoDict{
    if (!infoDict ) {
        return @"";
    }
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:infoDict
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:&error];
    NSString *jsonString = @"";
    if (!jsonData){
        NSLog(@"json 序列化错误: %@", error);
    }else{
        jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
    
    jsonString = [jsonString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    //去除掉首尾的空白字符和换行字符
    [jsonString stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    return jsonString;
}



@end
