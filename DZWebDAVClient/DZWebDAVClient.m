//
//  DZWebDAVClient.m
//  DZWebDAVClient
//

#import "DZWebDAVClient.h"
#import "NSDate+DZRFC1123.h"
#import "DZISO8601DateFormatter.h"
#import "DZWebDAVLock.h"
#import "DZXMLParserResponseSerializer.h"




NSString const *DZWebDAVContentTypeKey      = @"getcontenttype";
NSString const *DZWebDAVETagKey             = @"getetag";
NSString const *DZWebDAVCTagKey             = @"getctag";
NSString const *DZWebDAVCreationDateKey     = @"creationdate";
NSString const *DZWebDAVModificationDateKey = @"modificationdate";


const NSTimeInterval DZWebDAVClientRequestTimeout = 30.0;



@interface DZWebDAVClient()

- (NSURLSessionDataTask *)mr_listPath:(NSString *)path depth:(NSUInteger)depth success:(DZWebDAVClientDataTaskSuccessBlock)success failure:(DZWebDAVClientDataTaskErrorBlock)failure;

@property (nonatomic, strong) NSFileManager *fileManager;

@end

@implementation DZWebDAVClient

@synthesize fileManager = _fileManager;

- (instancetype)initWithBaseURL:(NSURL *)url{
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    configuration.HTTPMaximumConnectionsPerHost = 5;
    configuration.requestCachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
    configuration.allowsCellularAccess = YES;
    configuration.timeoutIntervalForRequest = DZWebDAVClientRequestTimeout;
    return [self initWithBaseURL:url sessionConfiguration:configuration];
}

- (instancetype)initWithBaseURL:(NSURL *)url
           sessionConfiguration:(NSURLSessionConfiguration *)configuration
{
    self = [super initWithBaseURL:url sessionConfiguration:configuration];
    if (self) {
        self.requestSerializer = [AFHTTPRequestSerializer serializer];
        self.requestSerializer.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
        self.responseSerializer = [DZXMLParserResponseSerializer serializer];
        dispatch_queue_t callBackQueue = dispatch_queue_create("com.dizzytechnology.networking.client.callback", NULL);
        self.completionQueue = callBackQueue;
        self.fileManager = [NSFileManager new];
    }
    return self;
}

- (NSURLSessionDataTask *)mr_dataTaskWithRequest:(NSURLRequest *)request success:(DZWebDAVClientDataTaskSuccessBlock)success failure:(DZWebDAVClientDataTaskErrorBlock)failure {
   
    NSURLSessionDataTask *task = [self dataTaskWithRequest:request uploadProgress:nil downloadProgress:nil completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
        if(error!=nil){
            if(failure){
                failure(error);
            }
        }
        else{
            if(success){
                success(responseObject);
            }
        }
    }];
    return task;
    
}

- (NSMutableURLRequest *)requestWithMethod:(NSString *)method path:(NSString *)path parameters:(NSDictionary *)parameters {
    NSMutableURLRequest *request = [self.requestSerializer requestWithMethod:method URLString:[[self.baseURL URLByAppendingPathComponent:path] absoluteString] parameters:parameters error:nil];
    NSParameterAssert([request valueForHTTPHeaderField:@"User-Agent"].length>0);
    [request setValue:[UIDevice currentDevice].name forHTTPHeaderField:@"X-Device-Name"];
    [request setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
    [request setTimeoutInterval: DZWebDAVClientRequestTimeout];
    return request;
}

- (NSURLSessionDataTask *)copyPath:(NSString *)source
          toPath:(NSString *)destination
         success:(DZWebDAVClientDataTaskSuccessBlock)success
         failure:(DZWebDAVClientDataTaskErrorBlock)failure{
    NSString *destinationPath = [[self.baseURL URLByAppendingPathComponent:destination] absoluteString];
    NSMutableURLRequest *request = [self requestWithMethod:@"COPY" path:source parameters:nil];
    [request setValue:destinationPath forHTTPHeaderField:@"Destination"];
	[request setValue:@"T" forHTTPHeaderField:@"Overwrite"];
    NSURLSessionDataTask *task = [self mr_dataTaskWithRequest:request success:success failure:failure];
    return task;
}

- (NSURLSessionDataTask *)movePath:(NSString *)source
                            toPath:(NSString *)destination
                           success:(DZWebDAVClientDataTaskSuccessBlock)success
                           failure:(DZWebDAVClientDataTaskErrorBlock)failure{
    NSString *destinationPath = [[self.baseURL URLByAppendingPathComponent:destination] absoluteString];
    NSMutableURLRequest *request = [self requestWithMethod:@"MOVE" path:source parameters:nil];
    [request setValue:destinationPath forHTTPHeaderField:@"Destination"];
	[request setValue:@"T" forHTTPHeaderField:@"Overwrite"];
    NSURLSessionDataTask *task = [self mr_dataTaskWithRequest:request success:success failure:failure];
    return task;
}

- (NSURLSessionDataTask *)deletePath:(NSString *)path
                             success:(DZWebDAVClientDataTaskSuccessBlock)success
                             failure:(DZWebDAVClientDataTaskErrorBlock)failure{
    NSMutableURLRequest *request = [self requestWithMethod:@"DELETE" path:path parameters:nil];
    NSURLSessionDataTask *task = [self mr_dataTaskWithRequest:request success:success failure:failure];
    return task;
}

- (NSURLSessionDataTask *)mr_listPath:(NSString *)path depth:(NSUInteger)depth success:(DZWebDAVClientDataTaskSuccessBlock)success failure:(DZWebDAVClientDataTaskErrorBlock)failure{
	NSParameterAssert(success);
	NSMutableURLRequest *request = [self requestWithMethod:@"PROPFIND" path:path parameters:nil];
	NSString *depthHeader = nil;
	if (depth <= 0)
		depthHeader = @"0";
	else if (depth == 1)
		depthHeader = @"1";
	else
		depthHeader = @"infinity";
    [request setValue: depthHeader forHTTPHeaderField: @"Depth"];
    [request setHTTPBody:[@"<?xml version=\"1.0\" encoding=\"utf-8\" ?><D:propfind xmlns:D=\"DAV:\"><D:allprop/></D:propfind>" dataUsingEncoding:NSUTF8StringEncoding]];
    [request setValue:@"application/xml" forHTTPHeaderField:@"Content-Type"];
    
    NSURLSessionDataTask *task = [self mr_dataTaskWithRequest:request success:^(id responseObject) {
        
        if (responseObject && ![responseObject isKindOfClass:[NSDictionary class]]) {
            if (failure){
                failure([NSError errorWithDomain:AFURLResponseSerializationErrorDomain code:NSURLErrorCannotParseResponse userInfo:nil]);
            }
            return;
        }
        
        id checkItems = [responseObject valueForKeyPath:@"multistatus.response.propstat.prop"];
        id checkHrefs = [responseObject valueForKeyPath:@"multistatus.response.href"];
        
        NSArray *objects = nil;
        if ([checkItems isKindOfClass:[NSArray class]]) {
            objects = checkItems;
        }
        else if (checkItems) {
            objects = @[ checkItems ];
        }
        
        NSArray *keys = nil;
        if ([checkHrefs isKindOfClass:[NSArray class]]) {
            keys = checkHrefs;
        }
        else if (checkHrefs) {
            keys = @[ checkHrefs ];
        }
        
        NSDictionary *unformattedDict = [NSDictionary dictionaryWithObjects: objects forKeys: keys];
        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity: unformattedDict.count];
        
        [unformattedDict enumerateKeysAndObjectsUsingBlock:^(NSString *absoluteKey, NSDictionary *unformatted, BOOL *stop) {
            // filter out Finder thumbnail files (._filename), they get us screwed up.
            if ([absoluteKey.lastPathComponent hasPrefix: @"._"])
                return;
            
            // Replace an absolute path with a relative one
            NSString *key = [absoluteKey stringByReplacingOccurrencesOfString:self.baseURL.path withString:@""];
            if ([[key substringToIndex:1] isEqualToString:@"/"])
                key = [key substringFromIndex:1];
            
            // reformat the response dictionaries into usable values
            NSMutableDictionary *object = [NSMutableDictionary dictionaryWithCapacity: 5];
            
            NSString *origCreationDate = [unformatted objectForKey: DZWebDAVCreationDateKey];
            NSDate *creationDate = [NSDate dateFromDZRFC1123String: origCreationDate] ?: [[[DZISO8601DateFormatter alloc] init] dateFromString: origCreationDate] ?: nil;
            
            NSString *origModificationDate = [unformatted objectForKey: DZWebDAVModificationDateKey] ?: [unformatted objectForKey: @"getlastmodified"];
            NSDate *modificationDate = [NSDate dateFromDZRFC1123String: origModificationDate] ?: [[[DZISO8601DateFormatter alloc] init] dateFromString: origModificationDate] ?: nil;
            
            [object setObject: [unformatted objectForKey: DZWebDAVETagKey] forKey: DZWebDAVETagKey];
            [object setObject: [unformatted objectForKey: DZWebDAVCTagKey] forKey: DZWebDAVCTagKey];
            [object setObject: [unformatted objectForKey: DZWebDAVContentTypeKey] ?: [unformatted objectForKey: @"contenttype"] forKey: DZWebDAVContentTypeKey];
            if (creationDate) {
                [object setObject: creationDate forKey: DZWebDAVCreationDateKey];
            }
            if (modificationDate) {
                [object setObject: modificationDate forKey: DZWebDAVModificationDateKey];
            }
            
            [dict setObject: object forKey: key];
        }];
        
        if (success){
            success(dict);
        }
        
    } failure:failure];
    
    return task;
}

- (NSURLSessionDataTask *)propertiesOfPath:(NSString *)path success:(DZWebDAVClientDataTaskSuccessBlock)success
                                   failure:(DZWebDAVClientDataTaskErrorBlock)failure {
	return [self mr_listPath:path depth:0 success:success failure:failure];
}

- (NSURLSessionDataTask *)listPath:(NSString *)path success:(DZWebDAVClientDataTaskSuccessBlock)success
         failure:(DZWebDAVClientDataTaskErrorBlock)failure{
	return [self mr_listPath:path depth:1 success:success failure:failure];
}

- (NSURLSessionDataTask *)recursiveListPath:(NSString *)path success:(DZWebDAVClientDataTaskSuccessBlock)success
                  failure:(DZWebDAVClientDataTaskErrorBlock)failure {
	return [self mr_listPath:path depth:2 success:success failure:failure];
}

- (NSURLSessionDownloadTask *)downloadPath:(NSString *)remoteSource
               toURL:(NSURL *)localDestination
             success:(DZWebDAVClientDataTaskSuccessBlock)success
            progress:(DZWebDAVClientDataTaskProgressBlock)progress
             failure:(DZWebDAVClientDataTaskErrorBlock)failure{
	if ([self.fileManager respondsToSelector:@selector(createDirectoryAtURL:withIntermediateDirectories:attributes:error:) ]) {
		[self.fileManager createDirectoryAtURL: [localDestination URLByDeletingLastPathComponent] withIntermediateDirectories: YES attributes: nil error: NULL];
	} else {
		[self.fileManager createDirectoryAtPath: [localDestination.path stringByDeletingLastPathComponent] withIntermediateDirectories: YES attributes: nil error: NULL];
	}
	NSMutableURLRequest *request = [self requestWithMethod:@"GET" path:remoteSource parameters:nil];

    NSURLSessionDownloadTask *downloadTask = [self downloadTaskWithRequest:request progress:progress destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
       return localDestination;
    } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
        if(error!=nil){
            if(failure){
                failure(error);
            }
        }
        else{
            if(success){
                success(filePath);
            }
        }
    }];
    return downloadTask;
}


- (NSURLSessionDataTask *)makeCollection:(NSString *)path
                                 success:(DZWebDAVClientDataTaskSuccessBlock)success
                                 failure:(DZWebDAVClientDataTaskErrorBlock)failure{
	NSURLRequest *request = [self requestWithMethod:@"MKCOL" path:path parameters:nil];	
    NSURLSessionDataTask *task = [self mr_dataTaskWithRequest:request success:success failure:failure];
    return task;
}

- (NSURLSessionUploadTask *)uploadData:(NSData *)data
                                  path:(NSString *)remoteDestination
                               success:(DZWebDAVClientDataTaskSuccessBlock)success
                              progress:(DZWebDAVClientDataTaskProgressBlock)progress
                               failure:(DZWebDAVClientDataTaskErrorBlock)failure{
    NSMutableURLRequest *request = [self requestWithMethod:@"PUT" path:remoteDestination parameters:nil];
	[request setValue:@"application/octet-stream" forHTTPHeaderField:@"Content-Type"];
	[request setValue:[NSString stringWithFormat:@"%ld", (long)data.length] forHTTPHeaderField:@"Content-Length"];
    NSURLSessionUploadTask *uploadTask = [self uploadTaskWithRequest:request fromData:data progress:progress completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
        if(error!=nil){
            if(failure){
                failure(error);
            }
        }
        else{
            if(success){
                success(responseObject);
            }
        }
    }];
    return uploadTask;
}

- (NSURLSessionUploadTask *)uploadURL:(NSURL *)localSource
                                 path:(NSString *)remoteDestination
                              success:(DZWebDAVClientDataTaskSuccessBlock)success
                             progress:(DZWebDAVClientDataTaskProgressBlock)progress
                              failure:(DZWebDAVClientDataTaskErrorBlock)failure{
    NSMutableURLRequest *request = [self requestWithMethod:@"PUT" path:remoteDestination parameters:nil];
    NSURLSessionUploadTask *uploadTask = [self uploadTaskWithRequest:request fromFile:localSource progress:progress completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
        if(error!=nil){
            if(failure){
                failure(error);
            }
        }
        else{
            if(success){
                success(responseObject);
            }
        }
    }];
    return uploadTask;
}

- (NSURLSessionDataTask *)lockPath:(NSString *)path
                         exclusive:(BOOL)exclusive
                         recursive:(BOOL)recursive
                           timeout:(NSTimeInterval)timeout
                           success:(DZWebDAVClientDataLockTaskSuccessBlock)success
                           failure:(DZWebDAVClientDataTaskErrorBlock)failure{
    NSParameterAssert(success);
    NSMutableURLRequest *request = [self requestWithMethod: @"LOCK" path: path parameters: nil];
    [request setValue: @"application/xml" forHTTPHeaderField: @"Content-Type"];
    [request setValue: timeout ? [NSString stringWithFormat: @"Second-%f", timeout] : @"Infinite, Second-4100000000" forHTTPHeaderField: @"Timeout"];
	[request setValue: recursive ? @"Infinity" : @"0" forHTTPHeaderField: @"Depth"];
    NSString *bodyData = [NSString stringWithFormat: @"<?xml version=\"1.0\" encoding=\"utf-8\"?><D:lockinfo xmlns:D=\"DAV:\"><D:lockscope><D:%@/></D:lockscope><D:locktype><D:write/></D:locktype></D:lockinfo>", exclusive ? @"exclusive" : @"shared"];
    [request setHTTPBody: [bodyData dataUsingEncoding:NSUTF8StringEncoding]];
    NSURLSessionDataTask *task = [self mr_dataTaskWithRequest:request success:^(id responseObject) {
        DZWebDAVLock *lock = [[DZWebDAVLock alloc] initWithURL:request.URL responseObject: responseObject];
        if(success){
            success(lock);
        }
    } failure:failure];
    return task;
}

- (NSURLSessionDataTask *)refreshLock:(DZWebDAVLock *)lock
                              success:(DZWebDAVClientDataLockTaskSuccessBlock)success
                              failure:(DZWebDAVClientDataTaskErrorBlock)failure{
    NSMutableURLRequest *request = [self requestWithMethod: @"LOCK" path: lock.URL.path parameters: nil];
    [request setValue: [NSString stringWithFormat:@"(<%@>)", lock.token] forHTTPHeaderField: @"If"];
    [request setValue: lock.timeout ? [NSString stringWithFormat: @"Second-%f", lock.timeout] : @"Infinite, Second-4100000000" forHTTPHeaderField: @"Timeout"];
	[request setValue: lock.recursive ? @"Infinity" : @"0" forHTTPHeaderField: @"Depth"];
    NSURLSessionDataTask *task = [self mr_dataTaskWithRequest:request success:^(id responseObject) {
        [lock updateFromResponseObject: responseObject];
        if(success){
            success(lock);
        }
    } failure:failure];
    return task;
}

- (NSURLSessionDataTask *)unlock:(DZWebDAVLock *)lock
                         success:(DZWebDAVClientDataTaskSuccessBlock)success
                         failure:(DZWebDAVClientDataTaskErrorBlock)failure{
    NSMutableURLRequest *request = [self requestWithMethod: @"UNLOCK" path: lock.URL.path parameters: nil];
	[request setValue:@"application/xml" forHTTPHeaderField:@"Content-Type"];
	[request setValue:[NSString stringWithFormat:@"<%@>", lock.token] forHTTPHeaderField:@"Lock-Token"];
    NSURLSessionDataTask *task = [self mr_dataTaskWithRequest:request success:success failure:failure];
    return task;
}

@end
