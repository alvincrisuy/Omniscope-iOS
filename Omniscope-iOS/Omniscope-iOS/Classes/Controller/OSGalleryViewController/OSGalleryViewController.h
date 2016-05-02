//
//  OSGalleryViewController.h
//  Omniscope-iOS
//
//  Created by Cris Uy on 30/04/2016.
//  Copyright © 2016 Pancake Unlimited. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OSGalleryViewController : UIViewController <UICollectionViewDataSource>

@property (nonatomic, retain) IBOutlet UICollectionView *collectionView;
@property (nonatomic, retain) IBOutlet UIButton *closeButton;

@end
