//
//  MyLocation.h
//  Omniscope-iOS
//
//  Created by Cris Uy on 16/06/2016.
//  Copyright © 2016 Pancake Unlimited. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface MyLocation : NSObject <MKAnnotation>

- (id)initWithName:(NSString*)name address:(NSString*)address coordinate:(CLLocationCoordinate2D)coordinate;
- (MKMapItem*)mapItem;

@end
