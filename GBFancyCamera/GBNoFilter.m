//
//  GBNoFilter.m
//  GBFancyCamera
//
//  Created by Luka Mirosevic on 06/09/2013.
//  Copyright (c) 2013 Goonbee. All rights reserved.
//

#import "GBNoFilter.h"

@implementation GBNoFilter

#pragma mark - GBFancyCameraFilterProtocol

-(NSString *)localisedName {
    return NSLocalizedStringFromTableInBundle(@"No filter", @"GBFancyCameraLocalizations", [[GBFancyCamera class] resourcesBundle], @"filter name");
}

@end
