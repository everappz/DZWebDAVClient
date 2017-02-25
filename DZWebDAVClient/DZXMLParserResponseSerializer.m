//
//  DZXMLParserResponseSerializer.m
//  MyApp
//
//  Created by Artem Meleshko on 2/25/17.
//  Copyright © 2017 My Company. All rights reserved.
//

#import "DZXMLParserResponseSerializer.h"
#import "DZXMLReader.h"

static BOOL DZAFErrorOrUnderlyingErrorHasCodeInDomain(NSError *error, NSInteger code, NSString *domain) {
    if ([error.domain isEqualToString:domain] && error.code == code) {
        return YES;
    } else if (error.userInfo[NSUnderlyingErrorKey]) {
        return DZAFErrorOrUnderlyingErrorHasCodeInDomain(error.userInfo[NSUnderlyingErrorKey], code, domain);
    }
    return NO;
}

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
                          error:(NSError *__autoreleasing *)error{
    if (![self validateResponse:(NSHTTPURLResponse *)response data:data error:error]) {
        if (!error || DZAFErrorOrUnderlyingErrorHasCodeInDomain(*error, NSURLErrorCannotDecodeContentData, AFURLResponseSerializationErrorDomain)) {
            return nil;
        }
    }
    NSDictionary *responseDictionary = [DZXMLReader dictionaryForXMLData:data error:error];
    return responseDictionary;
}

@end
