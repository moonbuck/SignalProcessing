//
//  MoonKit.h
//  MoonKit
//
//  Created by Jason Cardwell on 12/21/17.
//  Copyright © 2017 Moondeer Studios. All rights reserved.
//

#if TARGET_OS_IOS
#import <UIKit/UIKit.h>

//! Project version number for SignalProcessing_iOS.
FOUNDATION_EXPORT double MoonKit_iOSVersionNumber;

//! Project version string for SignalProcessing_iOS.
FOUNDATION_EXPORT const unsigned char MoonKit_iOSVersionString[];

#elif TARGET_OS_OSX
#import <AppKit/AppKit.h>

//! Project version number for SignalProcessing_iOS.
FOUNDATION_EXPORT double MoonKit_MacVersionNumber;

//! Project version string for SignalProcessing_iOS.
FOUNDATION_EXPORT const unsigned char MoonKit_MacVersionString[];
#endif

// In this header, you should import all the public headers of your framework using statements like #import <MoonKit/PublicHeader.h>


