//
//  MMBackwardCompatible.m
//  LooseLeaf
//
//  Created by Adam Wulf on 8/7/13.
//  Copyright (c) 2013 Milestone Made, LLC. All rights reserved.
//

#import "MMBackwardCompatible.h"
#import "JRSwizzle.h"
#import <objc/runtime.h>
#import <objc/message.h>

#define SetNSErrorFor(FUNC, ERROR_VAR, FORMAT, ...)                                                                         \
    if (ERROR_VAR) {                                                                                                        \
        NSString *errStr = [NSString stringWithFormat:@"%s: " FORMAT, FUNC, ##__VA_ARGS__];                                 \
        *ERROR_VAR = [NSError errorWithDomain:@"NSCocoaErrorDomain"                                                         \
                                         code:-1                                                                            \
                                     userInfo:[NSDictionary dictionaryWithObject:errStr forKey:NSLocalizedDescriptionKey]]; \
    }
#define SetNSError(ERROR_VAR, FORMAT, ...) SetNSErrorFor(__func__, ERROR_VAR, FORMAT, ##__VA_ARGS__)


@implementation NSObject (MMBackwardCompatible)


/**
 * returns YES if we added a method definition for the input selector,
 * NO otherwise
 */
+ (BOOL)mm_defineMethod:(SEL)origSel_ withMethod:(SEL)altSel_ error:(NSError **)error_
{
    Method altMethod = class_getInstanceMethod(self, altSel_);
    if (!altMethod) {
        SetNSError(error_, @"alternate method %@ not found for class %@", NSStringFromSelector(altSel_), [self class]);
        return NO;
    }
    Method origMethod = class_getInstanceMethod(self, origSel_);
    if (!origMethod) {
        class_addMethod(self,
                        origSel_,
                        class_getMethodImplementation(self, altSel_),
                        method_getTypeEncoding(altMethod));

        return YES;
    }
    return NO;
}


/**
 * returns YES if we added a method definition for the input selector,
 * NO otherwise
 */
+ (BOOL)mm_defineOrSwizzleMethod:(SEL)origSel_ withMethod:(SEL)altSel_ error:(NSError **)error_
{
    Method altMethod = class_getInstanceMethod(self, altSel_);
    if (!altMethod) {
        SetNSError(error_, @"alternate method %@ not found for class %@", NSStringFromSelector(altSel_), [self class]);
        return NO;
    }
    Method origMethod = class_getInstanceMethod(self, origSel_);
    if (!origMethod) {
        class_addMethod(self,
                        origSel_,
                        class_getMethodImplementation(self, altSel_),
                        method_getTypeEncoding(altMethod));

        return YES;
    }

    return [self mmcb_swizzleMethod:origSel_ withMethod:altSel_ error:error_];
}


@end
