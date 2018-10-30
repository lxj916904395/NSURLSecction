//
//  ZFNetwork.h
//  NSURLSecction
//
//  Created by zhongding on 2018/10/29.
//

#import <Foundation/Foundation.h>

typedef void(^ZFNetworkHandle)(id response);


@interface ZFNetwork : NSObject

+ (instancetype)sharedManager;

- (void)postWithUrl:(NSString*)urlstring params:(NSDictionary *)params handle:(ZFNetworkHandle)handle;

@end

