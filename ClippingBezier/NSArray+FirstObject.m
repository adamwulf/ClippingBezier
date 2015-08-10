//
//  NSArray+FirstObject.m
//  ClippingBezier
//
//  Created by Adam Wulf on 2/3/14.
//  Copyright (c) 2014 Adam Wulf. All rights reserved.
//

#import "NSArray+FirstObject.h"
#import <objc/runtime.h>

#pragma clang diagnostic ignored "-Wincomplete-implementation"

@implementation NSArray (FirstObject)

id dynamicFirstObject(id self, SEL _cmd)
{
    if([self count]){
        return [self objectAtIndex:0];
    }
    return nil;
}


+ (BOOL) resolveInstanceMethod:(SEL)aSEL
{
    if (aSEL == @selector(firstObject))
    {
        class_addMethod([self class], aSEL, (IMP) dynamicFirstObject, "v@:");
        return YES;
    }
    return [super resolveInstanceMethod:aSEL];
}


@end
