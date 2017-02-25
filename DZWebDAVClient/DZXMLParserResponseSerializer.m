//
//  DZXMLParserResponseSerializer.m
//  MyApp
//
//  Created by Artem Meleshko on 2/25/17.
//  Copyright © 2017 My Company. All rights reserved.
//

#import "DZXMLParserResponseSerializer.h"
#import "DZXMLReader.h"

@implementation DZXMLParserResponseSerializer

+ (instancetype)serializer {
    DZXMLParserResponseSerializer *serializer = [[self alloc] init];
    return serializer;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.acceptableContentTypes = [[NSSet alloc] initWithObjects:@"application/xml", @"text/xml", nil];
    }
    return self;
}

#pragma mark - AFURLResponseSerialization

- (id)responseObjectForResponse:(NSHTTPURLResponse *)response
                           data:(NSData *)data
                          error:(NSError *__autoreleasing *)error
{
    id responseObject = [super responseObjectForResponse:response data:data error:error];
    if([responseObject isKindOfClass:[NSXMLParser class]]){
        NSXMLParser *responseXMLParser = (NSXMLParser *)responseObject;
        NSError *error = nil;
        NSDictionary *responseDictionary = [DZXMLReader dictionaryForXMLParser: responseXMLParser error: &error];
        return responseDictionary;
    }
    else{
        return responseObject;
    }
}

@end
