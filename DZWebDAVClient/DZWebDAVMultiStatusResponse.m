//
//  DZWebDAVMultiStatusResponse.m
//  Everapp
//
//  Created by Artem Meleshko on 2/26/17.
//  Copyright © 2017 Everappz. All rights reserved.
//

#import "DZWebDAVMultiStatusResponse.h"
#import "DZISO8601DateFormatter.h"
#import "NSDate+DZRFC1123.h"
#import "Ono.h"



NSString * getcontentlengthCONST = @"getcontentlength";
NSString * creationdateCONST = @"creationdate";
NSString * getlastmodifiedCONST = @"getlastmodified";
NSString * modificationdateCONST  = @"modificationdate";
NSString * getcontenttypeCONST = @"getcontenttype";
NSString * contenttypeCONST = @"contenttype";
NSString * getetagCONST = @"getetag";
NSString * getctagCONST = @"getctag";


NSString * resourcetypeCONST = @"resourcetype";
NSString * notedataCONST = @"notedata";
NSString * getDeletedTimeCONST = @"getDeletedTime";
NSString * getDeletedDataNameCONST = @"getDeletedDataName";
NSString * getDeletedCONST = @"getDeleted";



@interface DZWebDAVMultiStatusResponse ()

@property (nonatomic, assign, getter=isCollection) BOOL collection;
@property (nonatomic, assign) NSUInteger contentLength;
@property (nonatomic, strong) NSDate *creationDate;
@property (nonatomic, strong) NSDate *lastModifiedDate;
@property (nonatomic, copy) NSString *etag;
@property (nonatomic, copy) NSString *ctag;
@property (nonatomic, copy) NSString *contentType;
@property (nonatomic, copy) NSString *href;

@property (nonatomic, strong) ONOXMLElement *element;


@property (nonatomic, strong)NSDictionary<NSString*, NSString*> *customProps;

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *notedata;
@property (nonatomic, copy) NSString *deletedTime;
@property (nonatomic, copy) NSString *deletedDataName;
@property (nonatomic, copy) NSString *deleted;


@end



@implementation DZWebDAVMultiStatusResponse


#pragma mark - init

- (instancetype)initWithResponseElement:(ONOXMLElement *)element {
    
    
    if(element==nil){
        return nil;
    }
    
    NSParameterAssert(element);
    
    /*
     <d:response>
     <d:href>/sync/chatcontacts/f5187830e27a4120bd17107c62011ba5</d:href>
     <d:propstat>
     <d:prop>
     <d:getetag>W/"db3b4d0b9c05509d3967a56b4a0a0353"</d:getetag>
     <x2:chatcontacts-data xmlns:x2="urn:ietf:params:xml:ns:webdav">{"source_id":"f5187830e27a4120bd17107c62011ba5","display_name":"vhs","phone_number":"13716750071#13716750075","is_voip_number":"1","account_phone_number":"13661248236","contact_type":0,"contact_from":0,"device_id":"--866647020047438"}</x2:chatcontacts-data>
     </d:prop>
     <d:status>HTTP/1.1 200 OK</d:status>
     </d:propstat>
     </d:response>
     */
    

    NSString *href = [[element firstChildWithTag:@"href"] stringValue];
    NSInteger status = [[[element firstChildWithTag:@"status"] numberValue] integerValue];
    
    if (status == 0) {//[begin] fix bug: ｀status code｀ not found in firstChild element.
        NSString *statusString = [[[element firstChildWithTag:@"propstat"] firstChildWithTag:@"status"] stringValue];
        statusString = [statusString stringByReplacingOccurrencesOfString:@"HTTP/1.1" withString:@""];
        statusString = [statusString stringByTrimmingCharactersInSet:[[NSCharacterSet alphanumericCharacterSet] invertedSet]];
        statusString = [statusString stringByTrimmingCharactersInSet:[NSCharacterSet letterCharacterSet]];
        statusString = [statusString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (statusString.length > 0) {
            if ([statusString integerValue] > 0) {
                status = [statusString integerValue];
            }
        }
    }//[end] fix bug: ｀status code｀ not found in firstChild element.
    
    
    self = [self initWithURL:[NSURL URLWithString:href] statusCode:status HTTPVersion:@"HTTP/1.1" headerFields:nil];
    
    if(self){
        
        self.href = href;
        self.element = element;
        
        {
            NSDictionary *atts = [element attributes];
            if (atts.count > 0) {
                self.customProps = atts;
            }else{
                
                ONOXMLElement *propElement = [[element firstChildWithTag:@"propstat"] firstChildWithTag:@"prop"];
                
                NSMutableDictionary<NSString*,NSString*> *proDic = [NSMutableDictionary dictionaryWithCapacity:2];
                
                NSArray<ONOXMLElement*> *childrenElements = [propElement children];
                for (int i = 0; i < childrenElements.count; i++) {
                    ONOXMLElement *e = childrenElements[i];
                    NSString *aTag = [e tag];
                    NSString *stringValue = [self valueOfTag: aTag inElement: e];
                    if (aTag.length && stringValue.length) {
                        [proDic setObject:stringValue forKey:aTag];
                    }
                }

                self.customProps = proDic;
            }
        }
    }
    
    if (!self) {
        return nil;
    }
    
    ONOXMLElement *propElement = [[element firstChildWithTag:@"propstat"] firstChildWithTag:@"prop"];
    for (ONOXMLElement *resourcetypeElement in [propElement childrenWithTag:@"resourcetype"]) {
        if ([resourcetypeElement childrenWithTag:@"collection"].count > 0) {
            self.collection = YES;
            break;
        }
    }
    
    for (ONOXMLElement *resourcetypeElement in [propElement childrenWithTag:@"iscollectionString"]) {
        if ([resourcetypeElement childrenWithTag:@"true"].count > 0) {
            self.collection = YES;
            break;
        }
    }
    
    
    /**
     WebDav Response Namespace not always 'D'
     Ref.:  https://github.com/BitSuites/AFWebDAVManager/commit/c25abdb71e07897212b44212e2d854e744a64048
     rocket0423 committed on 10 Jul 2015
     1 parent 45504c7 commit c25abdb71e07897212b44212e2d854e744a64048
     
     self.contentLength = [[[propElement firstChildWithTag:@"getcontentlength" inNamespace:@"D"] numberValue] unsignedIntegerValue];
     self.creationDate = [[propElement firstChildWithTag:@"creationdate" inNamespace:@"D"] dateValue];
     self.lastModifiedDate = [[propElement firstChildWithTag:@"getlastmodified" inNamespace:@"D"] dateValue];
     */
    
    
    
    NSString *ns = [propElement namespace];
    NSMutableArray<NSString*> *beginEndTAGs = [NSMutableArray arrayWithCapacity:2];
    NSArray const * tags = @[getcontentlengthCONST,creationdateCONST,getlastmodifiedCONST,modificationdateCONST,getetagCONST,getctagCONST,getcontenttypeCONST,contenttypeCONST];
    [tags enumerateObjectsUsingBlock:^(id  _Nonnull eachTag, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *beginTAG = [NSString stringWithFormat:@"<%@:%@>", ns,eachTag];
        NSString *endTAG  = [NSString stringWithFormat:@"</%@:%@>", ns,eachTag];
        [beginEndTAGs addObject: beginTAG];
        [beginEndTAGs addObject: endTAG];
    }];
    
    
    {//getcontentlength
        self.contentLength = [[[propElement firstChildWithTag:getcontentlengthCONST]
                               numberValue] unsignedIntegerValue];
        if (self.contentLength==0) {
            NSMutableString *contentLengthSTR = [[[propElement firstChildWithTag:getcontentlengthCONST]
                                                  stringValue] mutableCopy];
            [beginEndTAGs enumerateObjectsUsingBlock:^(id  _Nonnull aTAG, NSUInteger idx, BOOL * _Nonnull stop) {
                [contentLengthSTR replaceOccurrencesOfString:aTAG
                                                  withString:@""
                                                     options:NSLiteralSearch
                                                       range:NSMakeRange(0, contentLengthSTR.length)];
            }];
            
            NSNumber *aContentLength = [propElement.document.numberFormatter numberFromString:contentLengthSTR];
            
            self.contentLength = [aContentLength unsignedIntegerValue];
        }
    }//getcontentlength
    
    {//creationdate

        NSString *origCreationDateString = [[propElement firstChildWithTag:creationdateCONST] stringValue];
        
        self.creationDate = [NSDate dateFromDZRFC1123String: origCreationDateString] ?: [[[DZISO8601DateFormatter alloc] init] dateFromString: origCreationDateString] ?: nil;
        
        if (self.creationDate==nil) {//by OYXJ
            NSMutableString *creationDateSTR = [[[propElement firstChildWithTag:creationdateCONST]
                                                 stringValue] mutableCopy];
            [beginEndTAGs enumerateObjectsUsingBlock:^(id  _Nonnull aTAG, NSUInteger idx, BOOL * _Nonnull stop) {
                [creationDateSTR replaceOccurrencesOfString:aTAG
                                                 withString:@""
                                                    options:NSLiteralSearch
                                                      range:NSMakeRange(0, creationDateSTR.length)];
            }];
            
            self.creationDate = [NSDate dateFromDZRFC1123String: creationDateSTR] ?: [[[DZISO8601DateFormatter alloc] init] dateFromString: creationDateSTR] ?: nil;

        }
    }//creationdate
    
    
    {//getlastmodified
        
        NSString *origModificationDateString = [[propElement firstChildWithTag:getlastmodifiedCONST] stringValue];
        NSDate *modificationDate = [NSDate dateFromDZRFC1123String: origModificationDateString] ?: [[[DZISO8601DateFormatter alloc] init] dateFromString: origModificationDateString] ?: nil;
        self.lastModifiedDate = modificationDate;
        
        if (self.lastModifiedDate==nil) {//by OYXJ
            NSMutableString *lastModifiedDateSTR = [[[propElement firstChildWithTag:getlastmodifiedCONST]
                                                     stringValue] mutableCopy];
            [beginEndTAGs enumerateObjectsUsingBlock:^(id  _Nonnull aTAG, NSUInteger idx, BOOL * _Nonnull stop) {
                [lastModifiedDateSTR replaceOccurrencesOfString:aTAG
                                                     withString:@""
                                                        options:NSLiteralSearch
                                                          range:NSMakeRange(0, lastModifiedDateSTR.length)];
            }];
            
            NSDate *lastModifiedDate = [NSDate dateFromDZRFC1123String: lastModifiedDateSTR] ?: [[[DZISO8601DateFormatter alloc] init] dateFromString: lastModifiedDateSTR] ?: nil;
            
            self.lastModifiedDate = lastModifiedDate;
        }
    }//getlastmodified
    
    
    if(self.lastModifiedDate==nil){//modificationdate
        
        NSString *origModificationDateString = [[propElement firstChildWithTag:modificationdateCONST] stringValue];
        NSDate *modificationDate = [NSDate dateFromDZRFC1123String: origModificationDateString] ?: [[[DZISO8601DateFormatter alloc] init] dateFromString: origModificationDateString] ?: nil;
        self.lastModifiedDate = modificationDate;
        
        if (self.lastModifiedDate==nil) {//by OYXJ
            NSMutableString *lastModifiedDateSTR = [[[propElement firstChildWithTag:modificationdateCONST]
                                                     stringValue] mutableCopy];
            [beginEndTAGs enumerateObjectsUsingBlock:^(id  _Nonnull aTAG, NSUInteger idx, BOOL * _Nonnull stop) {
                [lastModifiedDateSTR replaceOccurrencesOfString:aTAG
                                                     withString:@""
                                                        options:NSLiteralSearch
                                                          range:NSMakeRange(0, lastModifiedDateSTR.length)];
            }];
            
            NSDate *lastModifiedDate = [NSDate dateFromDZRFC1123String: lastModifiedDateSTR] ?: [[[DZISO8601DateFormatter alloc] init] dateFromString: lastModifiedDateSTR] ?: nil;
            
            self.lastModifiedDate = lastModifiedDate;
        }
    }//modificationdate
    
    
    {//getetag
        NSMutableString *aEtagSTR = [[[propElement firstChildWithTag:getetagCONST]
                                      stringValue] mutableCopy];
        [beginEndTAGs enumerateObjectsUsingBlock:^(id  _Nonnull aTAG, NSUInteger idx, BOOL * _Nonnull stop) {
            [aEtagSTR replaceOccurrencesOfString:aTAG
                                      withString:@""
                                         options:NSLiteralSearch
                                           range:NSMakeRange(0, aEtagSTR.length)];
        }];
        
        self.etag = [aEtagSTR copy];
    }//getetag
    
    {//getctag
        NSMutableString *aCtagSTR = [[[propElement firstChildWithTag:getctagCONST]
                                      stringValue] mutableCopy];
        [beginEndTAGs enumerateObjectsUsingBlock:^(id  _Nonnull aTAG, NSUInteger idx, BOOL * _Nonnull stop) {
            [aCtagSTR replaceOccurrencesOfString:aTAG
                                      withString:@""
                                         options:NSLiteralSearch
                                           range:NSMakeRange(0, aCtagSTR.length)];
        }];
        
        self.ctag = [aCtagSTR copy];
    }//getctag

    {//getcontenttype
        NSMutableString *aGetcontenttypeSTR = [[[propElement firstChildWithTag:getcontenttypeCONST]
                                      stringValue] mutableCopy];
        [beginEndTAGs enumerateObjectsUsingBlock:^(id  _Nonnull aTAG, NSUInteger idx, BOOL * _Nonnull stop) {
            [aGetcontenttypeSTR replaceOccurrencesOfString:aTAG
                                      withString:@""
                                         options:NSLiteralSearch
                                           range:NSMakeRange(0, aGetcontenttypeSTR.length)];
        }];
        
        self.contentType = [aGetcontenttypeSTR copy];
    }//getcontenttype
    
    
    if(self.contentType==nil){//contenttype
        NSMutableString *aContenttypeSTR = [[[propElement firstChildWithTag:contenttypeCONST]
                                                stringValue] mutableCopy];
        [beginEndTAGs enumerateObjectsUsingBlock:^(id  _Nonnull aTAG, NSUInteger idx, BOOL * _Nonnull stop) {
            [aContenttypeSTR replaceOccurrencesOfString:aTAG
                                                withString:@""
                                                   options:NSLiteralSearch
                                                     range:NSMakeRange(0, aContenttypeSTR.length)];
        }];
        
        self.contentType = [aContenttypeSTR copy];
    }//contenttype
    
    
    return self;
}


#pragma mark - private


- (NSString *)valueOfTag:(NSString *)aTagNameCONST inElement:(ONOXMLElement *)anElement
{
    if (aTagNameCONST.length <= 0) {
        return nil;
    }
    if (anElement == nil) {
        return nil;
    }
    
    NSString *returnStr = nil;
    @try {

        NSMutableString *aTagValueSTR = [[anElement stringValue] mutableCopy];
        
        if ([aTagValueSTR rangeOfString:aTagNameCONST].location == NSNotFound) {

        }else{
            
            NSString *ns = [anElement namespace];
            NSMutableArray *beginEndTAGs = [NSMutableArray arrayWithCapacity:1];
            [@[aTagNameCONST] enumerateObjectsUsingBlock:^(id  _Nonnull eachTag, NSUInteger idx, BOOL * _Nonnull stop) {
                NSString *beginTAG = [NSString stringWithFormat:@"<%@:%@>", ns,eachTag];
                NSString *endTAG  = [NSString stringWithFormat:@"</%@:%@>", ns,eachTag];
                [beginEndTAGs addObject: beginTAG];
                [beginEndTAGs addObject: endTAG];
            }];
            
            [beginEndTAGs enumerateObjectsUsingBlock:^(id  _Nonnull aTAG, NSUInteger idx, BOOL * _Nonnull stop) {
                [aTagValueSTR replaceOccurrencesOfString:aTAG
                                              withString:@""
                                                 options:NSLiteralSearch
                                                   range:NSMakeRange(0, aTagValueSTR.length)];
            }];
        }
        
        returnStr = [aTagValueSTR copy];
        
    } @catch (NSException *exception) {

        NSLog(@"%@", exception);
        
    } @finally {
        
        return returnStr;
    }
    
}


#pragma mark - getters

- (NSString *)name{
    if (nil==_name) {
        _name = self.URL.absoluteString.lastPathComponent ?: self.URL.absoluteString;
    }
    return _name;
}

- (NSString *)notedata{
    if (nil==_notedata) {
        ONOXMLElement *propElement = [[self.element firstChildWithTag:@"propstat"] firstChildWithTag:@"prop"];
        _notedata = [self valueOfTag: notedataCONST
                           inElement: [propElement firstChildWithTag:notedataCONST]];
    }
    
    return _notedata;
}

- (NSString *)deletedTime{
    if (nil==_deletedTime) {
        ONOXMLElement *propElement = [[self.element firstChildWithTag:@"propstat"] firstChildWithTag:@"prop"];
        _deletedTime = [self valueOfTag: getDeletedTimeCONST
                              inElement: [propElement firstChildWithTag:getDeletedTimeCONST]];
    }
    
    return _deletedTime;
}

- (NSString *)deletedDataName{
    if (nil==_deletedDataName) {
        ONOXMLElement *propElement = [[self.element firstChildWithTag:@"propstat"] firstChildWithTag:@"prop"];
        _deletedDataName = [self valueOfTag: getDeletedDataNameCONST
                                  inElement: [propElement firstChildWithTag:getDeletedDataNameCONST]];
    }
    return _deletedDataName;
}

- (NSString *)deleted{
    if (nil==_deleted) {
        ONOXMLElement *propElement = [[self.element firstChildWithTag:@"propstat"] firstChildWithTag:@"prop"];
        _deleted = [self valueOfTag: getDeletedCONST
                          inElement: [propElement firstChildWithTag:getDeletedCONST]];
    }
    return _deleted;
}

@end
