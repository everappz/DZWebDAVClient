//
//  DZXMLReader.m
//  DZWebDAVClient
//

#import "DZXMLReader.h"

#import "XMLDictionary.h"

#import "RegexKitLite.h"

NSString *const kXMLReaderTextNodeKey = @"text";

@interface DZXMLReader () <NSXMLParserDelegate>

@property (nonatomic, strong) NSXMLParser *parser;
@property (nonatomic, strong) NSMutableArray *dictionaryStack;
@property (nonatomic, strong) NSMutableString *textInProgress;

@end

@implementation DZXMLReader

@synthesize parser = _parser, dictionaryStack = _dictionaryStack, textInProgress = _textInProgress, error = _error, dictionary = _dictionary;

#pragma mark - Public methods

+ (XMLDictionaryParser *)XMLParser
{
    XMLDictionaryParser *parser = [[XMLDictionaryParser alloc] init];
    parser.attributesMode = XMLDictionaryAttributesModeDiscard;
    parser.wrapRootNode = YES;
    return parser;
}

+ (NSDictionary *)prefixStrippedDictionaryWithDictionary:(NSDictionary *)dictionary
{
    return [self prefixStrippedDictionaryWithDictionary:dictionary containingDictionary:nil];
}

+ (NSDictionary *)prefixStrippedDictionaryWithDictionary:(NSDictionary *)dictionary containingDictionary:(NSMutableDictionary *)mutatedDict
{
    if (!mutatedDict)
        mutatedDict = [NSMutableDictionary dictionaryWithCapacity:dictionary.count];
    
    for (id k in dictionary)
    {
        NSParameterAssert([k isKindOfClass:NSString.class]);
        
        // strip away prefix to the first ':' character
        id modK = [k stringByReplacingOccurrencesOfRegex:@"^.*:" withString:@""];
        
        if ([dictionary[k] isKindOfClass:NSDictionary.class])
        {
            mutatedDict[modK] = [NSMutableDictionary dictionary];
            [self prefixStrippedDictionaryWithDictionary:dictionary[k] containingDictionary:mutatedDict[modK]];
        }
        if ([dictionary[k] isKindOfClass:NSArray.class])
        {
            mutatedDict[modK] = [NSMutableArray array];
            [self prefixStrippedArrayWithArray:dictionary[k] containingArray:mutatedDict[modK]];
        }
        else
        {
            mutatedDict[modK] = dictionary[k];
        }
    }
    
    return mutatedDict;
}

+ (NSDictionary *)dictionaryForXMLData:(NSData *)data error:(NSError **)error {
	//NSXMLParser *parser = [[NSXMLParser alloc] initWithData:data];
	//return [self dictionaryForXMLParser: parser error: error];
    
    return [self prefixStrippedDictionaryWithDictionary:[[self XMLParser] dictionaryWithData:data]];
}

+ (NSDictionary *)dictionaryForXMLString:(NSString *)string error:(NSError **)error {
    //NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    //return [DZXMLReader dictionaryForXMLData:data error:error];
    
    return [self prefixStrippedDictionaryWithDictionary:[[self XMLParser] dictionaryWithString:string]];
}

+ (NSDictionary *)dictionaryForXMLFileAtPath:(NSString *)path error:(NSError **)error {
    //NSData *data = [NSData dataWithContentsOfFile:path options:0 error:error];
    //return [DZXMLReader dictionaryForXMLData:data error:error];
    
    return [self prefixStrippedDictionaryWithDictionary:[[self XMLParser] dictionaryWithFile:path]];
}

+ (NSDictionary *)dictionaryForXMLFileAtURL:(NSURL *)URL error:(NSError **)error {
	//NSData *data = [NSData dataWithContentsOfURL:URL options:0 error:error];
    //return [DZXMLReader dictionaryForXMLData:data error:error];
    
    return [self prefixStrippedDictionaryWithDictionary:[[self XMLParser]
                                                         dictionaryWithString:[NSString stringWithContentsOfURL:URL
                                                                                                       encoding:NSUTF8StringEncoding
                                                                                                          error:error]]];
}

+ (NSArray *)prefixStrippedArrayWithArray:(NSArray *)array
{
    return [self prefixStrippedArrayWithArray:array containingArray:nil];
}


+ (NSArray *)prefixStrippedArrayWithArray:(NSArray *)array containingArray:(NSMutableArray *)mutatedArray
{
    if (!mutatedArray)
        mutatedArray = [NSMutableArray arrayWithCapacity:array.count];
    
    for (id k in array)
    {
        
        // strip away prefix to the first ':' character
        
        if ([k isKindOfClass:NSDictionary.class])
        {
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            [mutatedArray addObject:dict];
            [self prefixStrippedDictionaryWithDictionary:k containingDictionary:dict];
        }
        else if ([k isKindOfClass:NSArray.class])
        {
            NSMutableArray *modK = [NSMutableArray array];
            [self prefixStrippedArrayWithArray:k containingArray:modK];
        }
        else
        {
            id modK = [k stringByReplacingOccurrencesOfRegex:@"^.*:" withString:@""];
            [mutatedArray addObject:modK];
        }
    }
    
    return mutatedArray;
}





/*
+ (NSDictionary *)dictionaryForXMLParser:(NSXMLParser *)parser error:(NSError **)error {
    DZXMLReader *reader = [[DZXMLReader alloc] initWithParser: parser];
	BOOL success = [reader parse];
	if (success)
		return reader.dictionary;
	else if (error)
		*error = reader.error;
	return nil;
}*/

#pragma mark - Parsing

- (id)initWithParser:(NSXMLParser *)parser {
	if ((self = [super init])) {
		self.dictionaryStack = [NSMutableArray arrayWithObject: [NSMutableDictionary dictionary]];
		self.textInProgress = [NSMutableString string];
		parser.delegate = self;
		self.parser = parser;
	}
	return self;
}

- (BOOL)parse {
	BOOL success = [self.parser parse];
    
    // Return the stack's root dictionary on success
    if (success)
        _dictionary = [self.dictionaryStack objectAtIndex: 0];
    else
		_error = self.parser.parserError;
	
	return success;
}

#pragma mark - NSXMLParserDelegate

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
    NSRange prefixRange = [elementName rangeOfString:@":"];
    if (prefixRange.location < 3)
        elementName = [elementName substringFromIndex:NSMaxRange(prefixRange)];
    
    // Get the dictionary for the current level in the stack
    NSMutableDictionary *parentDict = self.dictionaryStack.lastObject;

    // Create the child dictionary for the new element, and initilaize it with the attributes
    NSMutableDictionary *childDict = [attributeDict mutableCopy];
    
    // If there's already an item for this key, it means we need to create an array
    id existingValue = [parentDict objectForKey:elementName];
    if (existingValue)
    {
        NSMutableArray *array = nil;
        if ([existingValue isKindOfClass:[NSMutableArray class]])
        {
            // The array exists, so use it
            array = (NSMutableArray *) existingValue;
        }
        else
        {
            // Create an array if it doesn't exist
            array = [NSMutableArray array];
            [array addObject:existingValue];

            // Replace the child dictionary with an array of children dictionaries
            [parentDict setObject:array forKey:elementName];
        }
        
        // Add the new child dictionary to the array
        [array addObject:childDict];
    }
    else
    {
        // No existing value, so update the dictionary
        [parentDict setObject:childDict forKey:elementName];
    }
    
    // Update the stack
    [self.dictionaryStack addObject:childDict];
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
    // Update the parent dict with text info
    NSMutableDictionary *dictInProgress = self.dictionaryStack.lastObject;
    
    self.textInProgress.string = [self.textInProgress stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    [self.textInProgress replaceOccurrencesOfString:@"\"" withString:@"" options:0 range:NSMakeRange(0, self.textInProgress.length)];
    
    NSPredicate *xmlnsPred = [NSPredicate predicateWithFormat:@"SELF contains 'xmlns'"];
    NSArray *xmlnsKeys = [dictInProgress.allKeys filteredArrayUsingPredicate:xmlnsPred];
    [dictInProgress removeObjectsForKeys:xmlnsKeys];
    
    NSRange prefixRange = [elementName rangeOfString:@":"];
    if (prefixRange.location < 3)
        elementName = [elementName substringFromIndex:NSMaxRange(prefixRange)];
    
    NSMutableDictionary *secondToLast = [self.dictionaryStack objectAtIndex:self.dictionaryStack.count-2];
    
    if (!dictInProgress.count && self.textInProgress.length) {
        [secondToLast setObject:self.textInProgress forKey:elementName];
        self.textInProgress = [NSMutableString string];
    } else if (self.textInProgress.length) {
        [dictInProgress setObject:self.textInProgress forKey:kXMLReaderTextNodeKey];
        self.textInProgress = [NSMutableString string];
    } else if (!dictInProgress.count) {
        if (secondToLast.count > 1) {
            [secondToLast setObject:[NSNull null] forKey:elementName];
        } else {
            NSMutableDictionary *thirdToLast = [self.dictionaryStack objectAtIndex:self.dictionaryStack.count-3];
            NSString *key = [[thirdToLast allKeysForObject:secondToLast] lastObject];
            if (key.length)
                [thirdToLast setObject:elementName forKey:key];
        }
    }
    
    // Pop the current dict
    [self.dictionaryStack removeLastObject];
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    [self.textInProgress appendString:string];
}

@end
