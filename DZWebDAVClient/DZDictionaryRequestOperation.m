//
//  DZDictionaryRequestOperation.m
//  DZWebDAVClient
//

#import "DZDictionaryRequestOperation.h"
#import "DZXMLReader.h"

static dispatch_queue_t xml_request_operation_processing_queue() {
	static dispatch_queue_t dz_xml_request_operation_processing_queue = NULL;

    if (dz_xml_request_operation_processing_queue == NULL) {
        dz_xml_request_operation_processing_queue = dispatch_queue_create("com.dizzytechnology.networking.xml-request.processing", 0);
    }
    
    return dz_xml_request_operation_processing_queue;
}

@interface DZDictionaryRequestOperation ()
@property (readwrite, nonatomic, strong) NSError *parseError;
@end

@implementation DZDictionaryRequestOperation

@synthesize responseDictionary = _responseDictionary, parseError = _parseError;

- (NSDictionary *)responseDictionary {
	if (!_responseDictionary && self.responseData.length && self.isFinished) {
		NSError *error = nil;
		_responseDictionary = [DZXMLReader dictionaryForXMLData:self.responseData error:&error];
		_parseError = error;
	}
	return _responseDictionary;
}

- (NSError *)error {
    if (_parseError) {
        return _parseError;
    } else {
        return [super error];
    }
}

- (void)setCompletionBlockWithSuccess:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                              failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure {
	__weak DZDictionaryRequestOperation *safeOp = self;
    self.completionBlock = ^ {
        if ([safeOp isCancelled]) {
            return;
        }

        dispatch_async(xml_request_operation_processing_queue(), ^(void) {
            DZDictionaryRequestOperation *strongSelf = safeOp;

            if (strongSelf.error) {
                if (failure) {
                    dispatch_async(strongSelf.failureCallbackQueue ? strongSelf.failureCallbackQueue : dispatch_get_main_queue(), ^{
                        failure(safeOp, safeOp.error);
                    });
                }
            } else {
                if (success) {
                    NSDictionary *XML = safeOp.responseDictionary;

                    dispatch_async(strongSelf.successCallbackQueue ? strongSelf.successCallbackQueue : dispatch_get_main_queue(), ^{
                        if (safeOp.parseError && failure) {
                            failure(safeOp, safeOp.parseError);
                        } else if (!safeOp.parseError && success) {
                            success(safeOp, XML);
                        }
                    });
                }
            }
        });
    };
}

+ (DZDictionaryRequestOperation *)dictionaryRequestOperationWithRequest:(NSURLRequest *)urlRequest
																success:(void (^)(AFHTTPRequestOperation *operation,  NSDictionary *responseObject))success
																failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure {
	DZDictionaryRequestOperation *requestOperation = [[self alloc] initWithRequest:urlRequest];
	[requestOperation setCompletionBlockWithSuccess: success failure: failure];
    return requestOperation;
}

@end
