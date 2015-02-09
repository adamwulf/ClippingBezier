//
//  MMBackwardCompatible.h
//  LooseLeaf
//
//  Created by Adam Wulf on 8/7/13.
//  Copyright (c) 2013 Milestone Made, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (MMBackwardCompatible)

+ (BOOL)mm_defineMethod:(SEL)origSel withMethod:(SEL)altSel error:(NSError**)error;

+ (BOOL)mm_defineOrSwizzleMethod:(SEL)origSel withMethod:(SEL)altSel error:(NSError**)error;

@end
