//
//  AFWebDAVMultiStatusResponseSerializer.m
//  MyApp
//
//  Created by Artem Meleshko on 2/26/17.
//  Copyright © 2017 My Company. All rights reserved.
//

#import "DZWebDAVMultiStatusResponseSerializer.h"
#import "Ono.h"
#import "DZWebDAVMultiStatusResponse.h"

@implementation DZWebDAVMultiStatusResponseSerializer

- (id)init {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    self.acceptableContentTypes = [[NSSet alloc] initWithObjects:@"application/xml", @"text/xml", nil];
    self.acceptableStatusCodes = [NSIndexSet indexSetWithIndex:207];
    
    return self;
}

#pragma mark - AFURLResponseSerializer

- (id)responseObjectForResponse:(NSURLResponse *)response
                           data:(NSData *)data
                          error:(NSError *__autoreleasing *)error
{
    
    NSLog(@"responseData=%@",data.length>0?[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]:@"");
    
    if (![self validateResponse:(NSHTTPURLResponse *)response data:data error:error]) {
        return nil;
    }
    
    NSMutableArray *mutableResponses = [NSMutableArray array];
    
    ONOXMLDocument *XMLDocument = [ONOXMLDocument XMLDocumentWithData:data error:error];
    for (ONOXMLElement *element in [XMLDocument.rootElement childrenWithTag:@"response"]) {
        DZWebDAVMultiStatusResponse *memberResponse = [[DZWebDAVMultiStatusResponse alloc] initWithResponseElement:element];
        if (memberResponse) {
            [mutableResponses addObject:memberResponse];
        }
    }
    
    return [NSArray arrayWithArray:mutableResponses];
}



@end
