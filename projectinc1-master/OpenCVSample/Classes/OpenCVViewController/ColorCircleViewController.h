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

@interface ColorCircleViewController : AbstractOCVViewController<AVCaptureVideoDataOutputSampleBufferDelegate,UINavigationControllerDelegate, UIImagePickerControllerDelegate,MFMessageComposeViewControllerDelegate>
{
    double _min, _max;
    AVCaptureSession *_session2;
   
}



@property (weak, nonatomic) IBOutlet UITextView *outputTextView;

@property (weak, nonatomic) IBOutlet UILabel *edgeLabel;
@property (weak, nonatomic) IBOutlet UILabel *chest20cmLabel;
@property (weak, nonatomic) IBOutlet UILabel *chest50cmLabel;
@property (weak, nonatomic) IBOutlet UILabel *cheat100cmLabel;

- (UIImage*)getUIImageFromIplImage:(IplImage *)iplImage;
- (void)didCaptureIplImage:(IplImage *)iplImage;
- (void)didFinishProcessingImage:(IplImage *)iplImage;









@end