//
//  DZWebDAVMultiStatusResponse.h
//  MyApp
//
//  Created by Artem Meleshko on 2/26/17.
//  Copyright © 2017 My Company. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ONOXMLElement;


@interface DZWebDAVMultiStatusResponse : NSHTTPURLResponse

- (instancetype)initWithResponseElement:(ONOXMLElement *)element;

@property (nonatomic, assign, readonly, getter=isCollection) BOOL collection;
@property (nonatomic, assign, readonly) NSUInteger contentLength;
@property (nonatomic, strong, readonly) NSDate *creationDate;
@property (nonatomic, strong, readonly) NSDate *lastModifiedDate;
@property (nonatomic, copy, readonly) NSString *etag;
@property (nonatomic, copy, readonly) NSString *ctag;
@property (nonatomic, copy, readonly) NSString *href;
@property (nonatomic, copy, readonly) NSString *contentType;

@property (nonatomic, strong, readonly) ONOXMLElement *element;


@property (nonatomic, strong, readonly)NSDictionary<NSString*, NSString*> *customProps;

@property (nonatomic, copy, readonly) NSString *name;
@property (nonatomic, copy, readonly) NSString *notedata;
@property (nonatomic, copy, readonly) NSString *deletedTime;
@property (nonatomic, copy, readonly) NSString *deletedDataName;
@property (nonatomic, copy, readonly) NSString *deleted;

@end
