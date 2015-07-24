#import "ColorCircleViewController.h"
#import <opencv2/objdetect/objdetect.hpp>
#include <opencv2/core/core.hpp>
#include <opencv2/highgui/highgui.hpp>
#include <opencv2/imgproc/imgproc.hpp>
#import "opencv2/opencv.hpp"
#import "AppDelegate.h"
#import "GCDAsyncSocket.h"
#include <ifaddrs.h>
#include <arpa/inet.h>
#import "AbstractOCVViewController.h"
#import <opencv2/imgproc/imgproc_c.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>
#import <opencv2/objdetect/objdetect.hpp>
#include <opencv2/core/core.hpp>
#include <opencv2/highgui/highgui.hpp>
#include <opencv2/imgproc/imgproc.hpp>
#import "opencv2/opencv.hpp"
#import <MessageUI/MFMessageComposeViewController.h>



#define WELCOME_MSG  0
#define ECHO_MSG     1
#define WARNING_MSG  2

#define READ_TIMEOUT 15.0
#define READ_TIMEOUT_EXTENSION 10.0

#define FORMAT(format, ...) [NSString stringWithFormat:(format), ##__VA_ARGS__]
#define PORT 1234


using namespace std;
using namespace cv;


@interface ColorCircleViewController ()
{
BOOL isRunning;

    dispatch_queue_t socketQueue;
    NSMutableArray *connectedSockets;
    GCDAsyncSocket *listenSocket;

}

@property (nonatomic, strong) RoboMe *roboMe;
@property (nonatomic, weak) IBOutlet UITextView *textView;
@property (nonatomic, strong) AVAudioPlayer* player;
@property (nonatomic,strong) MPMoviePlayerController* mp;


@end



@implementation ColorCircleViewController



- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self tappedOnRed:nil];
    
    
    NSBundle *mainBundle = [NSBundle mainBundle];
    NSString *filePath = [mainBundle pathForResource:@"every" ofType:@"mp3"];
    NSData *fileData = [NSData dataWithContentsOfFile:filePath];
    
    NSError *error = nil;
    
    
    self.player = [[AVAudioPlayer alloc] initWithData:fileData error:&error];

    
    
    // create RoboMe object
    self.roboMe = [[RoboMe alloc] initWithDelegate: self];
    
    // start listening for events from RoboMe
    [self.roboMe startListening];
    isRunning = NO;
    
    // Do any additional setup after loading the view, typically from a nib.
    socketQueue = dispatch_queue_create("socketQueue", NULL);
    
    listenSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:socketQueue];
    
    // Setup an array to store all accepted client connections
    connectedSockets = [[NSMutableArray alloc] initWithCapacity:1];
    
    isRunning = NO;
    
    NSLog(@"%@", [self getIPAddress]);
    
    [self toggleSocketState];   //Statrting the Socket
    
    
    
  //  [self startUpdatesWithSliderValue:1];
    
}

// Event commands received from RoboMe
/*- (void)commandReceived:(IncomingRobotCommand)command {
    // Display incoming robot command in text view
    [self displayText: [NSString stringWithFormat: @"Received: %@" ,[RoboMeCommandHelper incomingRobotCommandToString: command]]];
    
    // To check the type of command from RoboMe is a sensor status use the RoboMeCommandHelper class
    if([RoboMeCommandHelper isSensorStatus: command]){
        // Read the sensor status
        SensorStatus *sensors = [RoboMeCommandHelper readSensorStatus: command];
        
        // Update labels
        [self.edgeLabel setText: (sensors.edge ? @"ON" : @"OFF")];
        [self.chest20cmLabel setText: (sensors.chest_20cm ? @"ON" : @"OFF")];
        [self.chest50cmLabel setText: (sensors.chest_50cm ? @"ON" : @"OFF")];
        [self.cheat100cmLabel setText: (sensors.chest_100cm ? @"ON" : @"OFF")];
    }
}
*/
- (void)volumeChanged:(float)volume {
    if([self.roboMe isRoboMeConnected] && volume < 0.75) {
        //[self displayText: @"Volume needs to be set above 75% to send commands"];
    }
}

// Print out given text to text view
- (void)displayText: (NSString *)text {
    NSString *outputTxt = [NSString stringWithFormat: @"%@\n%@", self.outputTextView.text, text];
    
    // print command to output box
    [self.outputTextView setText: outputTxt];
    
    // scroll to bottom
    [self.outputTextView scrollRangeToVisible:NSMakeRange([self.outputTextView.text length], 0)];
}

#pragma mark - RoboMeConnectionDelegate

// Event commands received from RoboMe
- (void)commandReceived:(IncomingRobotCommand)command {
    // Display incoming robot command in text view
    [self displayText: [NSString stringWithFormat: @"Received: %@" ,[RoboMeCommandHelper incomingRobotCommandToString: command]]];
    
    // To check the type of command from RoboMe is a sensor status use the RoboMeCommandHelper class
    if([RoboMeCommandHelper isSensorStatus: command]){
        // Read the sensor status
        SensorStatus *sensors = [RoboMeCommandHelper readSensorStatus: command];
        
        // Update labels
        [self.edgeLabel setText: (sensors.edge ? @"ON" : @"OFF")];
        [self.chest20cmLabel setText: (sensors.chest_20cm ? @"ON" : @"OFF")];
        [self.chest50cmLabel setText: (sensors.chest_50cm ? @"ON" : @"OFF")];
        [self.cheat100cmLabel setText: (sensors.chest_100cm ? @"ON" : @"OFF")];
    }
}


- (void)roboMeConnected {
    //[self displayText: @"RoboMe Connected!"];
}

- (void)roboMeDisconnected {
    //[self displayText: @"RoboMe Disconnected"];
}


#pragma mark -
#pragma mark User-Defined Robo Movement

- (NSString *)direction:(NSString *)message {
    
    return @"";
}

- (void)perform:(NSString *)command {
    
    NSString *cmd = [command uppercaseString];
    if ([cmd isEqualToString:@"LEFT"]) {
        [self.roboMe sendCommand:kRobot_TurnLeft90Degrees];
    } else if ([cmd isEqualToString:@"RIGHT"]) {
        [self.roboMe sendCommand: kRobot_TurnRight90Degrees];
    } else if ([cmd isEqualToString:@"BACKWARD"]) {
        [self.roboMe sendCommand: kRobot_MoveBackwardFastest];
    } else if ([cmd isEqualToString:@"FORWARD"]) {
        [self.roboMe sendCommand: kRobot_MoveForwardFastest];
    } else if([cmd isEqualToString:@"STOP"]){
        [self.roboMe sendCommand:kRobot_Stop];
    } else if ([cmd isEqualToString:@"UP"]){
        [self.roboMe sendCommand: kRobot_HeadTiltAllUp];
    } else if ([cmd isEqualToString:@"DOWN"]){
        [self.roboMe sendCommand: kRobot_HeadTiltAllDown];
    } else if ([cmd isEqualToString: @"SING"])
    {
        [_player play];
    } else if ([cmd isEqualToString:@"PAUSE"]){
        [_player stop];
    } else if ([cmd isEqualToString:@"CALL"]){
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"tel:8167197679"]];
    } else if ([cmd isEqualToString:@"CAMERA"]){
        [self takeasnap];
    } else if ([cmd isEqualToString:@"MOVIE"]){
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.youtube.com/watch?v=NPW3mvAN0Rc"]];
        
    }
}


#pragma mark -
#pragma mark Socket

-(void) takeasnap
{

    
    
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    [picker setTitle:@"Take a photo."];
    // [poc setDelegate:self];
    [picker setSourceType:UIImagePickerControllerSourceTypeCamera];
    picker.showsCameraControls = NO;
    NSLog(@"Before taking picture");
    [picker takePicture];
    NSLog(@"Picture is taken");
}


- (void)toggleSocketState
{
    if(!isRunning)
    {
        NSError *error = nil;
        if(![listenSocket acceptOnPort:PORT error:&error])
        {
            [self log:FORMAT(@"Error starting server: %@", error)];
            return;
        }
        
        [self log:FORMAT(@"Echo server started on port %hu", [listenSocket localPort])];
        isRunning = YES;
    }
    else
    {
        // Stop accepting connections
        [listenSocket disconnect];
        
        // Stop any client connections
        @synchronized(connectedSockets)
        {
            NSUInteger i;
            for (i = 0; i < [connectedSockets count]; i++)
            {
                // Call disconnect on the socket,
                // which will invoke the socketDidDisconnect: method,
                // which will remove the socket from the list.
                [[connectedSockets objectAtIndex:i] disconnect];
            }
        }
        
        [self log:@"Stopped Echo server"];
        isRunning = false;
    }
}

- (void)log:(NSString *)msg {
    NSLog(@"%@", msg);
}

- (NSString *)getIPAddress
{
    NSString *address = @"error";
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    
    // retrieve the current interfaces - returns 0 on success
    success = getifaddrs(&interfaces);
    if (success == 0) {
        // Loop through linked list of interfaces
        temp_addr = interfaces;
        while (temp_addr != NULL) {
            if( temp_addr->ifa_addr->sa_family == AF_INET) {
                // Check if interface is en0 which is the wifi connection on the iPhone
                if ([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"]) {
                    // Get NSString from C String
                    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                }
            }
            
            temp_addr = temp_addr->ifa_next;
        }
    }
    // Free memory
    freeifaddrs(interfaces);
    
    return address;
}

#pragma mark -
#pragma mark GCDAsyncSocket Delegate

- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket
{
    // This method is executed on the socketQueue (not the main thread)
    
    @synchronized(connectedSockets)
    {
        [connectedSockets addObject:newSocket];
    }
    
    NSString *host = [newSocket connectedHost];
    UInt16 port = [newSocket connectedPort];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        @autoreleasepool {
            
            [self log:FORMAT(@"Accepted client %@:%hu", host, port)];
            
        }
    });
    
    NSString *welcomeMsg = @"Welcome to the AsyncSocket Echo Server\r\n";
    NSData *welcomeData = [welcomeMsg dataUsingEncoding:NSUTF8StringEncoding];
    
    [newSocket writeData:welcomeData withTimeout:-1 tag:WELCOME_MSG];
    
    
    [newSocket readDataWithTimeout:READ_TIMEOUT tag:0];
    newSocket.delegate = self;
    
    //    [newSocket readDataToData:[GCDAsyncSocket CRLFData] withTimeout:READ_TIMEOUT tag:0];
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag
{
    // This method is executed on the socketQueue (not the main thread)
    
    if (tag == ECHO_MSG)
    {
        [sock readDataToData:[GCDAsyncSocket CRLFData] withTimeout:100 tag:0];
    }
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    
    NSLog(@"== didReadData %@ ==", sock.description);
    
    NSString *msg = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    [self log:msg];
    [self perform:msg];
    [sock readDataWithTimeout:READ_TIMEOUT tag:0];
}

/**
 * This method is called if a read has timed out.
 * It allows us to optionally extend the timeout.
 * We use this method to issue a warning to the user prior to disconnecting them.
 **/
- (NSTimeInterval)socket:(GCDAsyncSocket *)sock shouldTimeoutReadWithTag:(long)tag
                 elapsed:(NSTimeInterval)elapsed
               bytesDone:(NSUInteger)length
{
    if (elapsed <= READ_TIMEOUT)
    {
        NSString *warningMsg = @"Are you still there?\r\n";
        NSData *warningData = [warningMsg dataUsingEncoding:NSUTF8StringEncoding];
        
        [sock writeData:warningData withTimeout:-1 tag:WARNING_MSG];
        
        return READ_TIMEOUT_EXTENSION;
    }
    
    return 0.0;
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
    if (sock != listenSocket)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            @autoreleasepool {
                [self log:FORMAT(@"Client Disconnected")];
            }
        });
        
        @synchronized(connectedSockets)
        {
            [connectedSockets removeObject:sock];
        }
    }
}




- (IBAction)tappedOnRed:(id)sender {
    _min = 160;
    _max = 179;
    
   // NSLog(@"%.2f - %.2f", _min, _max);
}

- (IBAction)tappedOnBlue:(id)sender {
    _min = 75;
    _max = 130;
    
    NSLog(@"%.2f - %.2f", _min, _max);
}

- (IBAction)tappedOnGreen:(id)sender {
    _min = 38;
    _max = 75;
    
   // NSLog(@"%.2f - %.2f", _min, _max);
}

//- (IBAction)sliderValueChanged:(id)sender
//{
//    double rangeMIN = 0;
//    double rangeMAX = 180;
//    double step = 19;
//    
//    _min = rangeMIN + _slider.value * (rangeMAX - rangeMIN - step);
//    _max = _min + step;
//    
//    _labelValue.text = [NSString stringWithFormat:@"%.2f - %.2f", _min, _max];
//}


//NO shows RGB image and highlights found circles
//YES shows threshold image
static BOOL _debug = NO;
vector<Vec3f> circles;


- (void)didCaptureIplImage:(IplImage *)iplImage
{
    //ipl image is in BGR format, it needs to be converted to RGB for display in UIImageView
    IplImage *imgRGB = cvCreateImage(cvGetSize(iplImage), IPL_DEPTH_8U, 3);
    cvCvtColor(iplImage, imgRGB, CV_BGR2RGB);
    Mat matRGB = Mat(imgRGB);

    //ipl imaeg is also converted to HSV; hue is used to find certain color
    IplImage *imgHSV = cvCreateImage(cvGetSize(iplImage), 8, 3);
    cvCvtColor(iplImage, imgHSV, CV_BGR2HSV);

    IplImage *imgThreshed = cvCreateImage(cvGetSize(iplImage), 8, 1);

    //it is important to release all images EXCEPT the one that is going to be passed to
    //the didFinishProcessingImage: method and displayed in the UIImageView
    cvReleaseImage(&iplImage);

    //filter all pixels in defined range, everything in range will be white, everything else
    //is going to be black
    cvInRangeS(imgHSV, cvScalar(_min, 100, 100), cvScalar(_max, 255, 255), imgThreshed);

    cvReleaseImage(&imgHSV);

    Mat matThreshed = Mat(imgThreshed);

    //smooths edges
    cv::GaussianBlur(matThreshed,
                     matThreshed,
                     cv::Size(9, 9),
                     2,
                     2);

    //debug shows threshold image, otherwise the circles are detected in the
    //threshold image and shown in the RGB image
    if (_debug)
    {
        cvReleaseImage(&imgRGB);
        [self didFinishProcessingImage:imgThreshed];
    }
    else
    {
        
        //get circles
        HoughCircles(matThreshed,
                     circles,
                     CV_HOUGH_GRADIENT,
                     2,
                     matThreshed.rows / 4,
                     150,
                     75,
                     10,
                     150);
       // NSLog(@" No. OF Circle Size: %lu",circles.size());
        
        
        
        for (size_t i = 0; i < circles.size(); i++)
        {
           // cout << "Circle position x = " << (int)circles[i][0] << ", y = " << (int)circles[i][1] << ", radius = " << (int)circles[i][2] << "\n";
            
            cv::Point center(cvRound(circles[i][0]), cvRound(circles[i][1]));
            
            int radius = cvRound(circles[i][2]);
            
            circle(matRGB, center, 3, Scalar(0, 255, 0), -1, 8, 0);
            circle(matRGB, center, radius, Scalar(0, 0, 255), 3, 8, 0);
        }

        //threshed image is not needed any more and needs to be released
        cvReleaseImage(&imgThreshed);
        
        //imgRGB will be released once it is not needed, the didFinishProcessingImage:
        //method will take care of that
        [self didFinishProcessingImage:imgRGB];
    }
    
static const NSTimeInterval deviceMotionMin = 0.5;
    
    int sliderValue=1;
    NSTimeInterval delta = 0.1;
    NSTimeInterval updateInterval = deviceMotionMin + delta * sliderValue;
    
    CMMotionManager *mManager = [(AppDelegate *)[[UIApplication sharedApplication] delegate] sharedManager];
    // double c = 0.0;
    
    if ([mManager isDeviceMotionAvailable] == YES) {
        [mManager setAccelerometerUpdateInterval:updateInterval];
        [mManager startAccelerometerUpdatesToQueue:[NSOperationQueue mainQueue] withHandler:^(CMAccelerometerData *accelerometerData, NSError *error) {
            
            
            double c = accelerometerData.acceleration.z;
            
            // NSLog(@"X" @"%f",a);
            
            //  NSLog(@"Y" @"%f",b);
           // NSLog(@"Z" @"%f",c);
        
            
            /*if(circles.size()>0)
            {
                NSLog(@"STOP");
                [self.roboMe sendCommand:kRobot_Stop];
                [self turnCameraOff];
              
                //[self stopUpdates];
                //[self.roboMe sendCommand:kRobot_Stop];
                
                CMMotionManager *mManager = [(AppDelegate *)[[UIApplication sharedApplication] delegate] sharedManager];
                
                if ([mManager isDeviceMotionActive] == YES) {
                    [mManager stopDeviceMotionUpdates];
                    [self.roboMe sendCommand:kRobot_Stop];
                    
                }
                if ([mManager isAccelerometerActive] == YES) {
                    [self.roboMe sendCommand:kRobot_Stop];
                    [mManager stopAccelerometerUpdates];
                    
                
                }
                

                //[UIAccelerometer sharedAccelerometer].delegate = nil;
            }
            
            if(c<=-0.1f )
            {
                if(circles.size()!=0){
                    [self.roboMe sendCommand:kRobot_Stop];
                }
                else
                {
                NSLog(@"Start");
                [self.roboMe sendCommand:kRobot_MoveForwardFastest];
                }
            }
            
            else if(c>=0.05f && circles.size()==0)
            {
                if(circles.size()!=0){
                    [self.roboMe sendCommand:kRobot_Stop];
                }
                else{
                NSLog(@"Slow");
                [self.roboMe sendCommand:kRobot_MoveForwardSlowest];
                }
            }
            
            else {
                if(circles.size()!=0){
                    [self.roboMe sendCommand:kRobot_Stop];
                }
                else{
                NSLog(@"slow ");
                    [self.roboMe sendCommand:kRobot_MoveForwardSpeed3];}
            }*/
        }];
}
}




- (void)turnCameraOff
{
    [_session stopRunning];
    _session = nil;
}


/*
static const NSTimeInterval deviceMotionMin = 0.05;


- (void)startUpdatesWithSliderValue:(int)sliderValue
{
    NSLog((@"CAME"));
    NSTimeInterval delta = 0.005;
    NSTimeInterval updateInterval = deviceMotionMin + delta * sliderValue;
    
    CMMotionManager *mManager = [(AppDelegate *)[[UIApplication sharedApplication] delegate] sharedManager];
    // double c = 0.0;
    
    if ([mManager isDeviceMotionAvailable] == YES) {
        [mManager setAccelerometerUpdateInterval:updateInterval];
        [mManager startAccelerometerUpdatesToQueue:[NSOperationQueue mainQueue] withHandler:^(CMAccelerometerData *accelerometerData, NSError *error) {
            
            
            double c = accelerometerData.acceleration.z;
            
            // NSLog(@"X" @"%f",a);
            
            //  NSLog(@"Y" @"%f",b);
           NSLog(@"Z" @"%f",c);
            
            if(c>=-0.2f && c<=0.0f)
            {
                [self.roboMe sendCommand:kRobot_MoveForwardSpeed2];
                
            }
            
            else if(c<=-0.2f && c>=-1.0f)
            {
                [self.roboMe sendCommand:kRobot_MoveForwardSpeed5];
                
            }
            
            else {
                NSLog(@"ROBO START ");
                [self.roboMe sendCommand:kRobot_MoveForwardSpeed1];
            }
            
           // NSLog(@"No.of circle %lu",circles.size());
          
           
            
            
            // NSLog(@"X-Axis: %f",gyroData.rotationRate.x);
            //NSLog(@"Y-Axis: %f",gyroData.rotationRate.y);
            // NSLog(@"Z-Axis: %f",accelerometerData.acceleration.z);
            
 
        }];
        
    }
    
    //self.updateIntervalLabel.text = [NSString stringWithFormat:@"%f", updateInterval];
}*/
         
        
        
    

- (void)stopUpdates
{
    CMMotionManager *mManager = [(AppDelegate *)[[UIApplication sharedApplication] delegate] sharedManager];
    
    if ([mManager isDeviceMotionActive] == YES) {
        [mManager stopDeviceMotionUpdates];
        [self.roboMe sendCommand:kRobot_Stop];

    }
    if ([mManager isAccelerometerActive] == YES) {
        [self.roboMe sendCommand:kRobot_Stop];
        [mManager stopAccelerometerUpdates];
    }
}

@end
