//
//  YelpAPIService.h
//  YelpNearby
//
//  Created by Behera, Subhransu on 8/14/13.
//  Copyright (c) 2013 Behera, Subhransu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OAuthConsumer.h"
#import <CoreLocation/CoreLocation.h>
#import <UIKit/UIKit.h>


@protocol YelpAPIServiceDelegate <NSObject>
-(void)loadResultWithDataArray:(NSArray *)resultArray;
@end

@interface YelpAPIService : NSObject <NSURLConnectionDataDelegate,UIAlertViewDelegate>

@property(nonatomic, strong) NSMutableData *urlRespondData;
@property(nonatomic, strong) NSString *responseString;
@property(nonatomic, strong) NSMutableArray *resultArray;

@property (strong, nonatomic) id <YelpAPIServiceDelegate> delegate;

-(void)searchNearByRestaurantsByFilter:(NSString *)categoryFilter atLatitude:(CLLocationDegrees)latitude
                          andLongitude:(CLLocationDegrees)longitude;

@end
