//
//  NSString+DZAdditions.m
//  MyApp
//
//  Created by Artem Meleshko on 2/27/17.
//  Copyright © 2017 My Company. All rights reserved.
//

#import "NSString+DZAdditions.h"

@implementation NSString (DZAdditions)

    
    
- (NSString*)dzstringByDeletingLastPathSlash {
    if ([self length] > 1 && [self hasSuffix:@"/"]) {
        return [self substringToIndex:[self length] - 1];
    }
    return self;
}
    
- (NSString*)dzstringByDeletingFirstPathSlash {
    if ([self length] > 1 && [self hasPrefix:@"/"]) {
        return [self substringFromIndex:1];
    }
    return self;
}
    
- (NSString*)dzstringByNormalizingFileName{
    NSCharacterSet *charactersToRemove = [[NSCharacterSet alphanumericCharacterSet] invertedSet];
    NSString *strippedReplacement = [[self componentsSeparatedByCharactersInSet:charactersToRemove] componentsJoinedByString:@"_"];
    return strippedReplacement;
}
    
- (NSString*)dzstringByAppendingLastPathSlash{
    if (self.length == 0) {
        return @"/";
    }
    if ([self characterAtIndex:self.length - 1] != '/') {
        return [self stringByAppendingString:@"/"];
    }
    return self;
}
  
    
@end
