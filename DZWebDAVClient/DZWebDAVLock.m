//
//  DZWebDAVLock.m
//  Pods
//
//  Created by Zachary Waldowski on 7/17/12.
//
//

#import "DZWebDAVLock.h"


@implementation DZWebDAVLock

@synthesize exclusive = _exclusive, recursive = _recursive, timeout = _timeout, token = _token;

- (id)initWithCoder:(NSCoder *)aDecoder {
    if ((self = [super init])) {
        _URL = [NSURL URLWithString: [aDecoder decodeObjectForKey: @"URL"]];
        _exclusive = [aDecoder decodeBoolForKey: @"exclusive"];
        _recursive = [aDecoder decodeBoolForKey: @"recursive"];
        _timeout = [aDecoder decodeFloatForKey: @"timeout"];
        _token = [[aDecoder decodeObjectForKey: @"token"] copy];
    }
    return self;
}

- (id)initWithURL:(NSURL *)URL responseObject:(id)object {
    if ((self = [super init])) {
        _URL = URL;
        NSParameterAssert([object respondsToSelector:@selector(valueForKey:)]);
        if([object respondsToSelector:@selector(valueForKey:)]){
            _exclusive = !![object valueForKey: @"exclusive"];
            _recursive = [[object valueForKey: @"depth"] isEqualToString: @"Infinity"];
            _timeout = [[[[object valueForKey: @"timeout"] componentsSeparatedByString:@"-"] lastObject] floatValue];
            _token = [[object valueForKey: @"locktoken"] copy];
        }
    }
    return self;
}

- (id)updateFromResponseObject:(id)object {
    NSParameterAssert([object respondsToSelector:@selector(valueForKey:)]);
    if([object respondsToSelector:@selector(valueForKey:)]){

        DZWebDAVLock *updatedLock = [[[self class] alloc] init];
        updatedLock->_URL = [_URL copy];
        
        if ([object valueForKey: @"exclusive"])
            updatedLock->_exclusive = YES;
        if ([object valueForKey: @"depth"])
            updatedLock->_recursive = [[object valueForKey: @"depth"] isEqualToString: @"Infinity"];
        if ([object valueForKey: @"timeout"])
            updatedLock->_timeout = [[[[object valueForKey: @"timeout"] componentsSeparatedByString:@"-"] lastObject] floatValue];
        if ([object valueForKey: @"locktoken"])
            updatedLock->_token = [[object valueForKey: @"locktoken"] copy];
        return updatedLock;
    }
    return nil;
}

- (id)copyWithZone:(NSZone *)zone {
    DZWebDAVLock *new = [[[self class] alloc] init];
    new->_URL = [_URL copy];
    new->_exclusive = _exclusive;
    new->_recursive = _recursive;
    new->_timeout = _timeout;
    new->_token = [_token copy];
    return new;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject: [_URL path] forKey: @"URL"];
    [aCoder encodeBool: _exclusive forKey: @"exclusive"];
    [aCoder encodeBool: _recursive forKey: @"recursive"];
    [aCoder encodeFloat: _timeout forKey: @"timeout"];
    [aCoder encodeObject: _token forKey: @"token"];
}

@end
