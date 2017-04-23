//
//  NSString+DZAdditions.h
//  Everapp
//
//  Created by Artem Meleshko on 2/27/17.
//  Copyright © 2017 Everappz. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (DZAdditions)

    
- (NSString*)dzstringByDeletingLastPathSlash;
    
- (NSString*)dzstringByDeletingFirstPathSlash;
    
- (NSString*)dzstringByNormalizingFileName;
    
- (NSString*)dzstringByAppendingLastPathSlash;
    
@end
