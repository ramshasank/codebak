#import "AbstractOCVViewController.h"
#import <RoboMe/RoboMe.h>
#import <opencv2/imgproc/imgproc_c.h>
#import <AVFoundation/AVFoundation.h>
#import <RoboMe/RoboMe.h>
#import <MediaPlayer/MediaPlayer.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <UIKit/UINavigationController.h>
#import <UIKit/UIKit.h>
#import <MessageUI/MFMessageComposeViewController.h>
#import "TTSEasyAPI.h"
#import "Restaurant.h"
#import "ResultTableViewCell.h"
#import "AppDelegate.h"
#import <CoreLocation/CoreLocation.h>
#import "YelpAPIService.h"

@interface ColorCircleViewController : AbstractOCVViewController<AVCaptureVideoDataOutputSampleBufferDelegate,UINavigationControllerDelegate, UIImagePickerControllerDelegate,MFMessageComposeViewControllerDelegate,UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource>
{
    double _min, _max;
    AVCaptureSession *_session2;
   
}


@property (weak, nonatomic) IBOutlet UITableView *resultTableView;

@property (strong, nonatomic) AppDelegate *appDelegate;
@property (strong, nonatomic) NSMutableArray *tableViewDisplayDataArray;

@property (weak, nonatomic) IBOutlet UITextView *outputTextView;
@property (strong, nonatomic) NSString* searchCriteria;
@property (strong, nonatomic) YelpAPIService *yelpService;
@property (strong, nonatomic) TTSEasyAPI * easyAccess;
@property (weak, nonatomic) IBOutlet UILabel *edgeLabel;
@property (weak, nonatomic) IBOutlet UILabel *chest20cmLabel;
@property (weak, nonatomic) IBOutlet UILabel *chest50cmLabel;
@property (weak, nonatomic) IBOutlet UILabel *cheat100cmLabel;

- (UIImage*)getUIImageFromIplImage:(IplImage *)iplImage;
- (void)didCaptureIplImage:(IplImage *)iplImage;
- (void)didFinishProcessingImage:(IplImage *)iplImage;
- (void)findNearByRestaurantsFromYelpbyCategory:(NSString *)categoryFilter;









@end