//
//  GBMissEtikateFilter.m
//  GBFancyCamera
//
//  Created by Luka Mirosevic on 06/09/2013.
//  Copyright (c) 2013 Goonbee. All rights reserved.
//

#import "GBMissEtikateFilter.h"

@interface GBMissEtikateFilter () {
    GPUImagePicture *lookupImageSource;
}
@end

@implementation GBMissEtikateFilter

- (id)init;
{
    if (!(self = [super init]))
    {
		return nil;
    }
    
#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
    UIImage *image = [UIImage imageNamed:BundledResource(@"lookup_miss_etikate.png")];
#else
    NSImage *image = [NSImage imageNamed:BundledResource(@"lookup_miss_etikate.png")];
#endif
    
    NSAssert(image, @"To use GPUImageMissEtikateFilter you need to add lookup_miss_etikate.png from GPUImage/framework/Resources to your application bundle.");
    
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
    return NSLocalizedStringFromTableInBundle(@"Etikate", @"GBFancyCameraLocalizations", [[GBFancyCamera class] resourcesBundle], @"filter name");
}

@end
