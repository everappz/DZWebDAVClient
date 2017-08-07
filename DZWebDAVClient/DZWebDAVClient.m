//
//  DZWebDAVClient.m
//  DZWebDAVClient
//

#import "DZWebDAVClient.h"
#import "NSDate+DZRFC1123.h"
#import "DZISO8601DateFormatter.h"
#import "DZWebDAVLock.h"
#import "DZWebDAVMultiStatusResponseSerializer.h"
#import "DZWebDAVMultiStatusResponse.h"
#import "DZWebDAVRequestSerializer.h"
#import "NSString+DZAdditions.h"



NSString const *DZWebDAVContentTypeKey      = @"getcontenttype";
NSString const *DZWebDAVETagKey             = @"getetag";
NSString const *DZWebDAVCTagKey             = @"getctag";
NSString const *DZWebDAVCreationDateKey     = @"creationdate";
NSString const *DZWebDAVModificationDateKey = @"modificationdate";
NSString const *DZWebDAVContentLengthKey    = @"getcontentlength";
NSString const *DZWebDAVHrefKey             = @"href";
NSString const *DZWebDAVCollectionKey       = @"collection";
NSString const *DZWebDAVTextNodeKey         = @"text";


const NSTimeInterval DZWebDAVClientRequestTimeout = 30.0;



@interface DZWebDAVClient()

- (NSURLSessionDataTask *)mr_listPath:(NSString *)path depth:(NSUInteger)depth success:(DZWebDAVClientDataTaskSuccessBlock)success failure:(DZWebDAVClientDataTaskErrorBlock)failure;

@end

@implementation DZWebDAVClient

- (instancetype)initWithBaseURL:(NSURL *)url{
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    configuration.requestCachePolicy = NSURLRequestReloadIgnoringCacheData;
    configuration.allowsCellularAccess = YES;
    configuration.timeoutIntervalForRequest = DZWebDAVClientRequestTimeout;
    return [self initWithBaseURL:url sessionConfiguration:configuration];
}

- (instancetype)initWithBaseURL:(NSURL *)url
           sessionConfiguration:(NSURLSessionConfiguration *)configuration
{
    self = [super initWithBaseURL:url sessionConfiguration:configuration];
    if (self) {
        self.requestSerializer = [DZWebDAVRequestSerializer serializer];
        self.requestSerializer.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
        self.responseSerializer = [AFCompoundResponseSerializer compoundSerializerWithResponseSerializers:@[[DZWebDAVMultiStatusResponseSerializer serializer], [AFHTTPResponseSerializer serializer]]];
        
        //FIXME
        //self.securityPolicy.allowInvalidCertificates = YES;
        
        dispatch_queue_t callBackQueue = dispatch_queue_create("com.dizzytechnology.networking.client.callback", NULL);
        self.completionQueue = callBackQueue;
        
        __weak typeof (self) weakSelf = self;
        
        [self setSessionDidReceiveAuthenticationChallengeBlock:^NSURLSessionAuthChallengeDisposition(NSURLSession * _Nonnull session, NSURLAuthenticationChallenge * _Nonnull challenge, NSURLCredential *__autoreleasing  _Nullable * _Nullable cred) {
            
            NSURLSessionAuthChallengeDisposition disposition = NSURLSessionAuthChallengePerformDefaultHandling;
            NSURLCredential *credential = nil;
            
            if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
                if ([weakSelf.securityPolicy evaluateServerTrust:challenge.protectionSpace.serverTrust forDomain:challenge.protectionSpace.host]) {
                    credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
                    if (credential) {
                        disposition = NSURLSessionAuthChallengeUseCredential;
                    } else {
                        disposition = NSURLSessionAuthChallengePerformDefaultHandling;
                    }
                } else {
                    disposition = NSURLSessionAuthChallengeCancelAuthenticationChallenge;
                }
            } else {
                if (weakSelf.credential) {
                    credential = weakSelf.credential;
                    disposition = NSURLSessionAuthChallengeUseCredential;
                } else {
                    disposition = NSURLSessionAuthChallengePerformDefaultHandling;
                }
            }
            
            if(cred){
                *cred = credential;
            }
            
            return disposition;
            
        }];
        
        
        [self setTaskDidReceiveAuthenticationChallengeBlock:^NSURLSessionAuthChallengeDisposition(NSURLSession * _Nonnull session, NSURLSessionTask * _Nonnull task, NSURLAuthenticationChallenge * _Nonnull challenge, NSURLCredential *__autoreleasing  _Nullable * _Nullable cred) {
            
            NSURLSessionAuthChallengeDisposition disposition = NSURLSessionAuthChallengePerformDefaultHandling;
            NSURLCredential *credential = nil;
            
            if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
                if ([weakSelf.securityPolicy evaluateServerTrust:challenge.protectionSpace.serverTrust forDomain:challenge.protectionSpace.host]) {
                    disposition = NSURLSessionAuthChallengeUseCredential;
                    credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
                } else {
                    disposition = NSURLSessionAuthChallengeCancelAuthenticationChallenge;
                }
            } else {
                if (weakSelf.credential) {
                    credential = weakSelf.credential;
                    disposition = NSURLSessionAuthChallengeUseCredential;
                } else {
                    disposition = NSURLSessionAuthChallengePerformDefaultHandling;
                }
            }
            
            if(cred){
                *cred = credential;
            }
            
            return disposition;
        }];
        
        
        [self setDataTaskDidReceiveDataBlock:^(NSURLSession * _Nonnull session, NSURLSessionDataTask * _Nonnull dataTask, NSData * _Nonnull data) {
            
        }];
        
        [self setDataTaskDidReceiveResponseBlock:^NSURLSessionResponseDisposition(NSURLSession * _Nonnull session, NSURLSessionDataTask * _Nonnull dataTask, NSURLResponse * _Nonnull response) {
            return NSURLSessionResponseAllow;
        }];
        
        
    }
    return self;
}

- (NSURLSessionDataTask *)mr_dataTaskWithRequest:(NSURLRequest *)request success:(DZWebDAVClientDataTaskSuccessBlock)success failure:(DZWebDAVClientDataTaskErrorBlock)failure {
    __weak typeof (self) weakSelf = self;
    NSURLSessionDataTask *task = [self dataTaskWithRequest:request uploadProgress:nil downloadProgress:nil completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
        [weakSelf dataTaskDidCompleteWithResponse:response responseObject:responseObject error:error success:success failure:failure];
    }];
    [task resume];
    return task;
}

- (void)dataTaskDidCompleteWithResponse:(NSURLResponse *)response responseObject:(id _Nullable )responseObject error:(NSError * _Nullable )error success:(DZWebDAVClientDataTaskSuccessBlock)success failure:(DZWebDAVClientDataTaskErrorBlock)failure {
    NSInteger statusCode = 200;
    if([response isKindOfClass:[NSHTTPURLResponse class]]){
        statusCode = [(NSHTTPURLResponse *)response statusCode];
    }
    if(statusCode<300){
        if(success){
            success(responseObject);
        }
    }
    else{
        if(failure){
            failure(error);
        }
    }
}


- (NSMutableURLRequest *)requestWithMethod:(NSString *)method path:(NSString *)path parameters:(NSDictionary *)parameters {
    
    NSString *absoluteURLString = [[self.baseURL absoluteString] dzstringByDeletingLastPathSlash];
    NSString *pathNormalized = [path dzstringByDeletingFirstPathSlash];
    NSString *resultURLString = [[[NSURL URLWithString:absoluteURLString] URLByAppendingPathComponent:pathNormalized] absoluteString];
    
    NSMutableURLRequest *request = [self.requestSerializer requestWithMethod:method URLString:resultURLString parameters:parameters error:nil];
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
        
        if (responseObject && ![responseObject isKindOfClass:[NSArray class]]) {
            if (failure){
                failure([NSError errorWithDomain:AFURLResponseSerializationErrorDomain code:NSURLErrorCannotParseResponse userInfo:nil]);
            }
            return;
        }
        
        NSArray<DZWebDAVMultiStatusResponse *> *statusResponseArray = (NSArray <DZWebDAVMultiStatusResponse*> *)responseObject;
        NSMutableArray<NSDictionary *> *resultArray = [[NSMutableArray<NSDictionary *> alloc] initWithCapacity:statusResponseArray.count];
        
        [statusResponseArray enumerateObjectsUsingBlock:^(DZWebDAVMultiStatusResponse * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            

            BOOL isCollection = obj.isCollection;
            NSUInteger contentLength = obj.contentLength;
            NSDate *creationDate = obj.creationDate;
            NSDate *lastModifiedDate = obj.lastModifiedDate;
            NSString *etag = obj.etag;
            NSString *ctag = obj.ctag;
            NSString *href = obj.href;
            NSString *contentType = obj.contentType;

            
            // filter out Finder thumbnail files (._filename), they get us screwed up.
            if ( href.length>0 &&
                [href.lastPathComponent hasPrefix: @"._"]==NO &&
                [href.lastPathComponent hasPrefix:@".DS_Store"]==NO ){
                
                // Replace an absolute path with a relative one
                href = [href stringByReplacingOccurrencesOfString:self.baseURL.path withString:@""];
                
                //if ([[key substringToIndex:1] isEqualToString:@"/"] && key.length>1){
                //    key = [key substringFromIndex:1];
                //}
                
                // reformat the response dictionaries into usable values
                NSMutableDictionary *object = [[NSMutableDictionary alloc] init];

                if (creationDate) {
                    [object setObject: creationDate forKey: DZWebDAVCreationDateKey];
                }
                
                if (etag) {
                    [object setObject: etag forKey: DZWebDAVETagKey];
                }
                
                if (ctag) {
                    [object setObject: ctag forKey: DZWebDAVCTagKey];
                }
                
                if (contentType) {
                    [object setObject: contentType forKey: DZWebDAVContentTypeKey];
                }
                
                if (isCollection) {
                    [object setObject: @(isCollection) forKey: DZWebDAVCollectionKey];
                }
                
                if (lastModifiedDate) {
                    [object setObject: lastModifiedDate forKey: DZWebDAVModificationDateKey];
                }
                
                if (contentLength){
                    [object setObject: @(contentLength) forKey: DZWebDAVContentLengthKey];
                }
                
                if (href){
                    [object setObject: href forKey: DZWebDAVHrefKey];
                    
                }
                
                [resultArray addObject:object];
                
            }
            
        }];
        
        if (success){
            success(resultArray);
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
    
    [[NSFileManager defaultManager] createDirectoryAtPath:[localDestination.path stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:nil];
    
	NSMutableURLRequest *request = [self requestWithMethod:@"GET" path:remoteSource parameters:nil];

    NSURLSessionDownloadTask *downloadTask = [self downloadTaskWithRequest:request progress:progress destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
       return localDestination;
    } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
        if(filePath){
            if(success){
                success(filePath);
            }
        }
        else{
            if(failure){
                failure(error);
            }
        }
    }];
    [downloadTask resume];
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
        if(responseObject==nil){
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
    [uploadTask resume];
    return uploadTask;
}

+ (NSString*)MIMETypeForExtension:(NSString*)extension
{
    CFStringRef fileExtension = (__bridge  CFStringRef)extension;
    CFStringRef type = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, fileExtension, NULL);
    NSString *mimeType = (__bridge_transfer NSString *)UTTypeCopyPreferredTagWithClass(type, kUTTagClassMIMEType);
    if (type != NULL){
        CFRelease(type);
    }
    if(!mimeType){
        mimeType = @"application/octet-stream";
    }
    return mimeType;
}


- (NSURLSessionUploadTask *)uploadURL:(NSURL *)localSource
                                 path:(NSString *)remoteDestination
                              success:(DZWebDAVClientDataTaskSuccessBlock)success
                             progress:(DZWebDAVClientDataTaskProgressBlock)progress
                              failure:(DZWebDAVClientDataTaskErrorBlock)failure{
    __weak typeof (self) weakSelf = self;
    NSMutableURLRequest *request = [self requestWithMethod:@"PUT" path:remoteDestination parameters:nil];
    
    BOOL isDir = NO;
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:localSource.path isDirectory:&isDir];
    NSDictionary *fileAttrs =
    [[NSFileManager defaultManager] attributesOfItemAtPath:localSource.path error:nil];
    if (!fileExists || isDir || !fileAttrs) {
        NSAssert(NO, @"Invalid condition");
    }
    NSString* contentLength = [NSString stringWithFormat: @"%qu", [fileAttrs fileSize]];
    [request setValue:[[self class] MIMETypeForExtension:localSource.pathExtension] forHTTPHeaderField:@"Content-Type"];
    [request setValue:contentLength forHTTPHeaderField:@"Content-Length"];
    
    NSURLSessionUploadTask *uploadTask = [self uploadTaskWithRequest:request fromFile:localSource progress:progress completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
        [weakSelf dataTaskDidCompleteWithResponse:response responseObject:responseObject error:error success:success failure:failure];
    }];
    [uploadTask resume];
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


- (NSURLSessionDataTask *)makeRequestWithMethodName:(NSString *)methodName
                                             atPath:(NSString *)path
                                         parameters:(NSDictionary *)params
                                            success:(DZWebDAVClientDataTaskSuccessBlock)success
                                            failure:(DZWebDAVClientDataTaskErrorBlock)failure{
    NSURLRequest *request = [self requestWithMethod:methodName path:path parameters:params];
    NSURLSessionDataTask *task = [self mr_dataTaskWithRequest:request success:success failure:failure];
    return task;
    
}


#ifdef DZ_RANGE_REQUEST_SUPPORT

- (NSURLSessionDataTask *)makeGETRequestAtPath:(NSString *)path
                                         parameters:(NSDictionary *)params
                                  additionalHeaders:(NSDictionary *)additionalHeaders
                                            success:(DZWebDAVClientDataTaskSuccessBlock)success
                                     didReceiveData:(DZWebDAVClientDataTaskDidReceiveDataBlock)didReceiveData
                                didReceiveResponse:(DZWebDAVClientDataTaskDidReceiveResponseBlock)didReceiveResponse
                                            failure:(DZWebDAVClientDataTaskErrorBlock)failure{
    __weak typeof (self) weakSelf = self;
    NSMutableURLRequest *request = [self requestWithMethod:@"GET" path:path parameters:params];
    [additionalHeaders enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        [request setValue:obj forHTTPHeaderField:key];
    }];
    NSURLSessionDataTask *task = [self dataTaskWithRequest:request
                                            didReceiveData:didReceiveData
                                        didReceiveResponse:didReceiveResponse
                                         completionHandler:^(NSURLResponse *response, id _Nullable responseObject,  NSError * _Nullable error){
                                             [weakSelf dataTaskDidCompleteWithResponse:response responseObject:responseObject error:error success:success failure:failure];
                                         }];
    [task resume];
    return task;
}

#endif

@end
