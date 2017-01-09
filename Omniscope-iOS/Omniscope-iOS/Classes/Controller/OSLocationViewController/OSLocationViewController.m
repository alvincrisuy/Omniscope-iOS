//
//  OSLocationViewController.m
//  Omniscope-iOS
//
//  Created by Cris Uy on 16/06/2016.
//  Copyright © 2016 Pancake Unlimited. All rights reserved.
//

#import "OSLocationViewController.h"
#import "NSString+DeviceType.h"
#import "OSRootViewController.h"

#define METERS_PER_MILE 1609.344

@interface OSLocationViewController () <CLLocationManagerDelegate>

@property (nonatomic, weak) IBOutlet MKMapView *mapView;
//@property (nonatomic, retain) IBOutlet UIBarButtonItem *getAddressButton;
@property (nonatomic, strong) CLLocationManager *locationManager;
//@property (nonatomic, strong) CLGeocoder *geocoder;
@property (nonatomic, strong) MKPlacemark *placemark;

@end

@implementation OSLocationViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    
    if (self = [super initWithNibName:[NSStringFromClass([OSLocationViewController class]) concatenateClassToDeviceType] bundle:nibBundleOrNil]) {
        // Custom initialization
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
//    self.locationManager = [[CLLocationManager alloc] init];
//    self.locationManager.delegate = self;
//    
//    // Gets user permission use location while the app is in the foreground.
//    [self.locationManager requestWhenInUseAuthorization];
//    [self.locationManager requestAlwaysAuthorization];
//    
//    self.geocoder = [[CLGeocoder alloc] init];
    
    // 1
    CLLocationCoordinate2D center;
    center.latitude = 14.642867;
    center.longitude= 121.027254;
    
    MKCoordinateSpan span;
    span.latitudeDelta = 0.5f;
    span.longitudeDelta = 0.5f;
    
    MKCoordinateRegion viewRegion;
    viewRegion.center = center;
    viewRegion.span = span;
    
    // 3
    [self.mapView setRegion:viewRegion animated:YES];
    
    MyLocation *annotation = [[MyLocation alloc] initWithName:@"48 West Avenue" address:@"Quezon City, Philippines" coordinate:center];
    [self.mapView addAnnotation:annotation];
    
//    [self.locationManager startUpdatingLocation];
    
    [self.closeButton addTarget:self action:@selector(closeButtonAction:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [UIView animateWithDuration:0.3f
                     animations: ^{
                         [OSRootViewController sharedController].tabView.alpha = 0.0f;
                         [OSRootViewController sharedController].sideBarTableView.alpha = 0.0f;
                     }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)closeButtonAction:(UIButton *)sender {
    
    [UIView animateWithDuration:0.3f
                     animations: ^{
                         [OSRootViewController sharedController].tabView.alpha = 1.0f;
                         [OSRootViewController sharedController].sideBarTableView.alpha = 1.0f;
                     }];
    
    [[OSRootViewController sharedController] popTransitionAnimated:YES];
}


- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation {
    static NSString *identifier = @"MyLocation";
    if ([annotation isKindOfClass:[MyLocation class]]) {
    
        MKAnnotationView *annotationView = (MKAnnotationView *) [_mapView dequeueReusableAnnotationViewWithIdentifier:identifier];
        if (annotationView == nil) {
            annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:identifier];
            annotationView.enabled = YES;
            annotationView.canShowCallout = YES;
            annotationView.image = [UIImage imageNamed:@"location180Y"];//here we use a nice image instead of the default pins
        } else {
            annotationView.annotation = annotation;
        }
        
        return annotationView;
    }
    
    return nil;
}


//- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
//{
//    NSLog(@"HELLO1");
//    
////    // Center the map the first time we get a real location change.
////    static dispatch_once_t centerMapFirstTime;
////    
////    if ((userLocation.coordinate.latitude != 0.0) && (userLocation.coordinate.longitude != 0.0)) {
////        dispatch_once(&centerMapFirstTime, ^{
////            [self.mapView setCenterCoordinate:userLocation.coordinate animated:YES];
////        });
////    }
//    
////    // Lookup the information for the current location of the user.
////    [self.geocoder reverseGeocodeLocation:self.mapView.userLocation.location completionHandler:^(NSArray *placemarks, NSError *error) {
////        if ((placemarks != nil) && (placemarks.count > 0)) {
////            // If the placemark is not nil then we have at least one placemark. Typically there will only be one.
////            self.placemark = placemarks[0];
////            
////            // we have received our current location, so enable the "Get Current Address" button
////            self.getAddressButton.enabled = YES;
////        }
////        else {
////            // Handle the nil case if necessary.
////        }
////    }];
//}
//
//- (void)mapView:(MKMapView *)mapView didFailToLocateUserWithError:(NSError *)error {
//    
////    self.getAddressButton.enabled = NO;
//    
//    if (!self.presentedViewController) {
//        NSString *message = nil;
//        if (error.code == kCLErrorLocationUnknown) {
//            // If you receive this error while using the iOS Simulator, location simulatiion may not be on.  Choose a location from the Debug > Simulate Location menu in Xcode.
//            message = @"Your location could not be determined.";
//        }
//        else {
//            message = error.localizedDescription;
//        }
//        
//        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error"
//                                                                       message:message
//                                                                preferredStyle:UIAlertControllerStyleAlert];
//        [alert addAction:[UIAlertAction actionWithTitle:@"OK"
//                                                  style:UIAlertActionStyleDefault
//                                                handler:nil]];
//        [self presentViewController:alert animated:YES completion:nil];
//    }
//}
//
//- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
//    if (status == kCLAuthorizationStatusRestricted || status == kCLAuthorizationStatusDenied) {
//        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Location Disabled"
//                                                                       message:@"Please enable location services in the Settings app."
//                                                                preferredStyle:UIAlertControllerStyleAlert];
//        [alert addAction:[UIAlertAction actionWithTitle:@"OK"
//                                                  style:UIAlertActionStyleDefault
//                                                handler:nil]];
//        [self presentViewController:alert animated:YES completion:nil];
//    }
//    else if (status == kCLAuthorizationStatusAuthorizedWhenInUse) {
//        // This will implicitly try to get the user's location, so this can't be set
//        // until we know the user granted this app location access
////        self.mapView.showsUserLocation = YES;
//    }
//}

@end
