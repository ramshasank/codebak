//
//  ResultTableViewCell.h
//  YelpNearby
//
//  Created by Behera, Subhransu on 8/13/13.
//  Copyright (c) 2013 Behera, Subhransu. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ResultTableViewCell : UITableViewCell

@property (retain, nonatomic) IBOutlet UILabel *nameLabel;
@property (retain, nonatomic) IBOutlet UILabel *addressLabel;

@property (retain, nonatomic) IBOutlet UIImageView *thumbImage;
@property (retain, nonatomic) IBOutlet UIImageView *ratingImage;

@end
