//
//  GBAmatorkaFilter.m
//  GBFancyCamera
//
//  Created by Luka Mirosevic on 06/09/2013.
//  Copyright (c) 2013 Goonbee. All rights reserved.
//

#import "GBAmatorkaFilter.h"

#import "GPUImagePicture.h"
#import "GPUImageLookupFilter.h"

@interface GBAmatorkaFilter () {
    GPUImagePicture *lookupImageSource;
}

@end

@implementation GBAmatorkaFilter

- (id)init;
{
    if (!(self = [super init]))
    {
		return nil;
    }
    
#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
    UIImage *image = [UIImage imageNamed:BundledResource(@"lookup_amatorka.png")];
#else
    NSImage *image = [NSImage imageNamed:BundledResource(@"lookup_amatorka.png")];
#endif
    
    NSAssert(image, @"To use GPUImageAmatorkaFilter you need to add lookup_amatorka.png from GPUImage/framework/Resources to your application bundle.");
    
    lookupImageSource = [[GPUImagePicture alloc] initWithImage:image];
    GPUImageLookupFilter *lookupFilter = [[GPUImageLookupFilter alloc] init];
    [self addFilter:lookupFilter];
    
    [lookupImageSource addTarget:lookupFilter atTextureLocation:1];
    [lookupImageSource processImage];
    
    self.initialFilters = [NSArray arrayWithObjects:lookupFilter, nil];
    self.terminalFilter = lookupFilter;
    
    return self;
}

-(void)prepareForImageCapture {
    [lookupImageSource processImage];
    [super prepareForImageCapture];
}

#pragma mark - GBFancyCameraFilterProtocol

-(NSString *)localisedName {
    return NSLocalizedStringFromTableInBundle(@"Amatorka", @"GBFancyCameraLocalizations", [[GBFancyCamera class] resourcesBundle], @"filter name");
}

@end
