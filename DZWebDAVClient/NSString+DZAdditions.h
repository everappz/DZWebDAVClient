//
//  NSString+DZAdditions.h
//  MyApp
//
//  Created by Artem Meleshko on 2/27/17.
//  Copyright © 2017 My Company. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (DZAdditions)

    
- (NSString*)dzstringByDeletingLastPathSlash;
    
- (NSString*)dzstringByDeletingFirstPathSlash;
    
- (NSString*)dzstringByNormalizingFileName;
    
- (NSString*)dzstringByAppendingLastPathSlash;
    
@end
