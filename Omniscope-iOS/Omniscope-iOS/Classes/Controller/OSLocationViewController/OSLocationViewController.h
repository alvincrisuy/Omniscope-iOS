//
//  OSLocationViewController.h
//  Omniscope-iOS
//
//  Created by Cris Uy on 16/06/2016.
//  Copyright © 2016 Pancake Unlimited. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "MyLocation.h"

@interface OSLocationViewController : UIViewController <MKMapViewDelegate>

@property (nonatomic, retain) IBOutlet UIButton *closeButton;

@end
