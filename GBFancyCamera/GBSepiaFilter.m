//
//  GBSepiaFilter.m
//  GBFancyCamera
//
//  Created by Luka Mirosevic on 06/09/2013.
//  Copyright (c) 2013 Goonbee. All rights reserved.
//

#import "GBSepiaFilter.h"

@implementation GBSepiaFilter

#pragma mark - GBFancyCameraFilterProtocol

-(NSString *)localisedName {
    return NSLocalizedStringFromTableInBundle(@"Sepia", @"GBFancyCameraLocalizations", [[GBFancyCamera class] resourcesBundle], @"filter name");
}

@end
