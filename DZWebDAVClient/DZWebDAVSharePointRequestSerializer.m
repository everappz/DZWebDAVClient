//
//  DZWebDAVSharePointRequestSerializer.m
//  MyApp
//
//  Created by Artem Meleshko on 2/27/17.
//  Copyright © 2017 My Company. All rights reserved.
//

#import "DZWebDAVSharePointRequestSerializer.h"

@implementation DZWebDAVSharePointRequestSerializer

- (NSURLRequest *)requestBySerializingRequest:(NSURLRequest *)request
                               withParameters:(id)parameters
                                        error:(NSError *__autoreleasing *)error
{
    NSMutableURLRequest *mutableRequest = [[super requestBySerializingRequest:request withParameters:parameters error:error] mutableCopy];
    NSString *unescapedURLString = CFBridgingRelease(CFURLCreateStringByReplacingPercentEscapesUsingEncoding(kCFAllocatorDefault, (__bridge CFStringRef)([[request URL] absoluteString]), NULL, kCFStringEncodingASCII));
    mutableRequest.URL = [NSURL URLWithString:unescapedURLString];
    
    return mutableRequest;
}

@end
