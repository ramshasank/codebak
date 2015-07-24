//
//  DetailViewController.m
//  PG6_NightBot_Romo
//
//  Created by Jeff Lanning on 7/12/15.
//  Copyright (c) 2015 Jeff Lanning. All rights reserved.
//

#import "DetailViewController.h"
#import "AppDelegate.h"

#import <opencv2/objdetect/objdetect.hpp>
#include <opencv2/core/core.hpp>
#include <opencv2/highgui/highgui.hpp>
#include <opencv2/imgproc/imgproc.hpp>
#import "opencv2/opencv.hpp"

#import "AFHTTPRequestOperationManager.h"
#import "STTwitterAPI.h"

#import "GCDAsyncSocket.h"

#define BASE_URL "http://nlpservices.mybluemix.net/api/service"
#define MONGO_URL "https://api.mongolab.com/api/1/databases/cs590_sg3/collections/TwitterData"

#define WELCOME_MSG  0
#define ECHO_MSG     1
#define WARNING_MSG  2

#define NO_TIMEOUT -1.0
#define READ_TIMEOUT 15.0
#define READ_TIMEOUT_EXTENSION 10.0

#define FORWARD @"FORWARD"
#define BACK @"BACK"
#define LEFT @"LEFT"
#define RIGHT @"RIGHT"
#define STOP @"STOP"
#define LAUGH @"LAUGH"
#define SPEED @"SPEED"

#define FASTER @"FASTER"
#define SLOWER @"SLOWER"
#define STOPSIGN @"STOPSIGN"
#define GOSIGN @"GOSIGN"
#define LEFTSIGN @"LEFTSIGN"
#define RIGHTSIGN @"RIGHTSIGN"
#define SLOWSIGN @"SLOWSIGN"
#define DNESIGN @"DNESIGN"
#define TWEET @"TWEET"
#define OFF @"OFF"
#define ON @"ON"

#define BURGLARY @"burglary"
#define THEFT @"theft"
#define ROBBERY @"robbery"
#define ASSAULT @"assault"
#define BREAKENTER @"breaking & entering"
#define ARSON @"arson"
#define ARREST @"arrest"
#define VANDALISM @"vandalism"
#define SHOOTING @"shooting"
#define OTHER @"other"

#define FORMAT(format, ...) [NSString stringWithFormat:(format), ##__VA_ARGS__]

double currentMaxRotX;
double currentMaxRotY;
double currentMaxRotZ;

dispatch_queue_t _socketQueue;
GCDAsyncSocket *_listenSocket;
NSMutableArray *_connectedSockets;
BOOL isRunning;

@implementation NSString (Contains)

- (BOOL)myContainsString:(NSString*)other {
    NSRange range = [self rangeOfString:other];
    return range.length != 0;
}

@end

@interface DetailViewController ()

@property (strong, nonatomic) CMMotionManager *motionManager;
@property (strong, nonatomic) NSString *currentRotX;
@property (strong, nonatomic) NSString *currentRotY;
@property (strong, nonatomic) NSString *currentRotZ;
@property (strong, nonatomic) NSString *maxRotX;
@property (strong, nonatomic) NSString *maxRotY;
@property (strong, nonatomic) NSString *maxRotZ;

@property (strong, nonatomic) NSString *currentMaxRotX;
@property (strong, nonatomic) NSString *currentMaxRotY;
@property (strong, nonatomic) NSString *currentMaxRotZ;

@property (nonatomic, assign) BOOL isBeginning;
@property (nonatomic, assign) BOOL isClimbing;
@property (nonatomic, assign) BOOL isOnTop;
@property (nonatomic, assign) BOOL isDescending;
@property (nonatomic, assign) BOOL isEnding;

@property (nonatomic, strong) NSArray *tokens;

@property (nonatomic, assign) BOOL sawRedColor;

@property (strong, nonatomic) NSString *stop;
@property (strong, nonatomic) NSString *doNotEnter;
@property (strong, nonatomic) NSString *go;
@property (strong, nonatomic) NSString *turnLeft;
@property (strong, nonatomic) NSString *turnRight;
@property (strong, nonatomic) NSString *slowDown;
@property (strong, nonatomic) NSString *activeSign;

@property (strong, nonatomic) NSMutableArray *signs;
@property (nonatomic, assign) int signIdx;

@end

@implementation DetailViewController

#pragma mark - Managing the detail item

- (void)setDetailItem:(id)newDetailItem {
    if (_detailItem != newDetailItem) {
        _detailItem = newDetailItem;
            
        // Update the view.
        [self configureView];
    }
}

- (void)configureView {
    // Update the user interface for the detail item.
    if (self.detailItem) {
        self.detailDescriptionLabel.text = [self.detailItem description];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self setupCamera];
    [self turnCameraOn];
    //[self tappedOnRed:self];
    
    self.signIdx = 0;
    
    self.stop = [[NSBundle mainBundle] pathForResource:@"traffic-sign-stop" ofType:@"bmp"];
    self.go = [[NSBundle mainBundle] pathForResource:@"traffic-sign-go" ofType:@"bmp"];
    self.doNotEnter = [[NSBundle mainBundle] pathForResource:@"traffic-sign-do-not-enter" ofType:@"bmp"];
    self.turnLeft = [[NSBundle mainBundle] pathForResource:@"traffic-sign-turn-left" ofType:@"bmp"];
    self.turnRight = [[NSBundle mainBundle] pathForResource:@"traffic-sign-turn-right" ofType:@"bmp"];
    self.slowDown = [[NSBundle mainBundle] pathForResource:@"traffic-sign-slow-down" ofType:@"bmp"];
    
    self.signs = [[NSMutableArray alloc] init];
    [self.signs addObject:_stop];
    [self.signs addObject:_go];
    [self.signs addObject:_doNotEnter];
    [self.signs addObject:_turnLeft];
    [self.signs addObject:_turnRight];
    [self.signs addObject:_slowDown];
    
    // Grab a shared instance of the Romo character
    self.Romo = [RMCharacter Romo];
    
    // To receive messages when Robots connect & disconnect, set RMCore's delegate to self
    [RMCore setDelegate:self];
    
    NSString *ipAddress = [self getIPAddress];
    [self logInfo:@"The iOS Device IP Address is..."];
    [self logInfo:ipAddress];
    
    _socketQueue = dispatch_queue_create("socketQueue", NULL);
    _listenSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:_socketQueue];
    _connectedSockets = [[NSMutableArray alloc] initWithCapacity:1];
    isRunning = NO;
    
    NSError *error = nil;
    if (![_listenSocket acceptOnPort:1234 error:&error])
    {
        NSLog(@"Error accepting listen socket on port: %@", error);
    }
    
    isRunning = YES;
    
    _activeSign = _stop;
    
    [self callMongoService];
    [self sendTwilioText:@"Hello, I'm Romo, give me something to do..."];
    
    YWeatherUtils* yweatherUtils = [YWeatherUtils getInstance];
    [yweatherUtils setMAfterRecieveDataDelegate: self];
    [yweatherUtils queryYahooWeather:@"Kansas%20City"];
    
    //self.Romo.emotion = RMCharacterEmotionCurious;
    //self.Romo.expression = RMCharacterExpressionSneeze;
    
    /** COMMENT OUT LOGGING PURPOSE ONLY **/
    /*
     AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
     
     self.motionManager = [appDelegate sharedMotionManager];
     self.motionManager.gyroUpdateInterval = 0.3;
     self.motionManager.magnetometerUpdateInterval = 0.3;
     self.motionManager.accelerometerUpdateInterval = 0.3;
     self.motionManager.deviceMotionUpdateInterval = 0.3;
     
     self.isBeginning = true;
     self.isClimbing = false;
     self.isOnTop = false;
     self.isDescending = false;
     self.isEnding = false;
     
     [self.motionManager startGyroUpdatesToQueue:[NSOperationQueue currentQueue] withHandler:^(CMGyroData *gyroData, NSError *error) {
     [self outputRotationData:gyroData.rotationRate];
     }];
     
     [self.motionManager startDeviceMotionUpdatesToQueue:[NSOperationQueue currentQueue] withHandler:^(CMDeviceMotion *motion, NSError *error) {
     [self processMotion:motion];
     }];
     */
    
    [self configureView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    // Add Romo's face to self.view whenever the view will appear
    [self.Romo addToSuperview:self.romoView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)doNothing
{
    
}

- (void)processMotion:(CMDeviceMotion*)motion
{
    float pitch =  (180/M_PI)*motion.attitude.pitch;
    float roll = (180/M_PI)*motion.attitude.roll;
    float yaw = (180/M_PI)*motion.attitude.yaw;
    
    NSLog(@"Roll: %@, Pitch: %@, Yaw: %@", [NSString stringWithFormat:@"%f", roll],[NSString stringWithFormat:@"%f",pitch], [NSString stringWithFormat:@"%f",yaw]);
    
    // Romo is flat
    if (pitch >= 70.0 && pitch < 90.0)
    {
        // 1. Romo is starting out...
        if (self.isBeginning == true)
        {
            NSLog(@"Is Beginning...");
            [self.Romo3 driveForwardWithSpeed:0.40];
            self.Romo.emotion = RMCharacterEmotionExcited;
            self.Romo.expression = RMCharacterExpressionExcited;
        }
        // 3. Romo is on top...
        else if (self.isBeginning == false && self.isClimbing == true)
        {
            NSLog(@"Is On Top...");
            self.isClimbing = false;
            self.isOnTop = true;
            
            [self.Romo3 driveForwardWithSpeed:0.25];
            
            [self.Romo3 stopDriving];
            self.Romo.emotion = RMCharacterEmotionSleepy;
            self.Romo.expression = RMCharacterExpressionYippee;
            
            // Call NLP Service and Tweet message!
            [self callNLPService];
            [self.Romo3 driveForwardWithSpeed:0.25];
        }
        // 5. Romo is at the finish line...
        else if (self.isDescending == true)
        {
            NSLog(@"Is at the Finish Line...");
            self.isDescending = false;
            self.isEnding = true;
            
            [self.Romo3 driveForwardWithSpeed:0.30];
            
            self.Romo.emotion = RMCharacterEmotionExcited;
            self.Romo.expression = RMCharacterExpressionWee;
        }
        else
        {
            NSLog(@"Saw Red Color... @%d", _sawRedColor);
            if (_sawRedColor == TRUE)
            {
                [self.Romo3 stopDriving];
            }
        }
    }
    // 2. Romo is climbing...
    else if (pitch < 70.0)
    {
        if (self.isBeginning == true)
        {
            NSLog(@"Is Climbing...");
            self.isBeginning = false;
            self.isClimbing = true;
            
            [self.Romo3 driveForwardWithSpeed:0.75];
            self.Romo.expression = RMCharacterExpressionStruggling;
        }
        
        // 4. Romo is descending...
        else if (self.isOnTop == true)
        {
            NSLog(@"Is Descending...");
            self.isOnTop = false;
            self.isDescending = true;
            
            [self.Romo3 driveForwardWithSpeed:0.15];
            self.Romo.emotion = RMCharacterEmotionScared;
            self.Romo.expression = RMCharacterExpressionScared;
        }
    }
    
    NSLog(@"Beginning: %@, Climbing: %@, OnTop: %@, Descending: %@, Finished: %@", [NSString stringWithFormat:@"%s", self.isBeginning ? "true" : "false"],[NSString stringWithFormat:@"%s", self.isClimbing ? "true" : "false"],[NSString stringWithFormat:@"%s", self.isOnTop ? "true" : "false"],[NSString stringWithFormat:@"%s", self.isDescending ? "true" : "false"],[NSString stringWithFormat:@"%s", self.isEnding ? "true" : "false"]);
}

- (void)outputRotationData:(CMRotationRate)rotation
{
    self.currentRotX = [NSString stringWithFormat:@" %.2fr/s",rotation.x];
    if(fabs(rotation.x) > fabs(currentMaxRotX))
    {
        currentMaxRotX = rotation.x;
    }
    self.currentRotY = [NSString stringWithFormat:@" %.2fr/s",rotation.y];
    if(fabs(rotation.y) > fabs(currentMaxRotY))
    {
        currentMaxRotY = rotation.y;
    }
    self.currentRotZ = [NSString stringWithFormat:@" %.2fr/s",rotation.z];
    if(fabs(rotation.z) > fabs(currentMaxRotZ))
    {
        currentMaxRotZ = rotation.z;
    }
    
    self.maxRotX = [NSString stringWithFormat:@" %.2f",currentMaxRotX];
    self.maxRotY = [NSString stringWithFormat:@" %.2f",currentMaxRotY];
    self.maxRotZ = [NSString stringWithFormat:@" %.2f",currentMaxRotZ];
    
    /*
     [self logInfo:[NSString stringWithFormat:@"%@%@", @"Current X Rot: ",self.currentRotX]];
     [self logInfo:[NSString stringWithFormat:@"%@%@", @"Current Y Rot: ",self.currentRotY]];
     [self logInfo:[NSString stringWithFormat:@"%@%@", @"Current Z Rot: ",self.currentRotZ]];
     
     [self logInfo:[NSString stringWithFormat:@"%@%@", @"Max X Rot: ",self.maxRotX]];
     [self logInfo:[NSString stringWithFormat:@"%@%@", @"Max Y Rot: ",self.maxRotY]];
     [self logInfo:[NSString stringWithFormat:@"%@%@", @"Max Z Rot: ",self.maxRotZ]];
     */
}

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
/*
 * This is our new function that calls into the Twitter API to tweet the NLP Commands.
 */
- (void) tweetCommands {
    NSMutableString * result = [[NSMutableString alloc] init];
    for (NSObject * obj in _tokens)
    {
        [result appendString:[obj description]];
        [result appendString:@" "];
    }
    NSLog(@"The concatenated string is %@", result);
    
    NSString *apiKey = @"K5irO3T6OnBimYiLwKI1aDPv0";
    NSString *apiSecret = @"sswoK3Dgjpr17AAUaWlQyfLdFpA0ENEs11wDoCQ2ahghcAaZvu";
    NSString *oauthToken = @"3248175864-yiPSna2GQo0b3WHUSHPWeFl0kHjmb4zBPy648A4";
    NSString *oathSecret = @"ZAVqYA8UTavzk0gg9I1ksthmq404LZtsoXvpbFuLBHJwr";
    
    STTwitterAPI *twitter = [STTwitterAPI twitterAPIWithOAuthConsumerKey:apiKey consumerSecret:apiSecret oauthToken:oauthToken oauthTokenSecret:oathSecret];
    
    [twitter verifyCredentialsWithSuccessBlock:^(NSString *bearerToken) {
        
        NSLog(@"Access granted with %@", bearerToken);
        
        [twitter postStatusUpdate:result
                inReplyToStatusID:nil
                         latitude:nil
                        longitude:nil
                          placeID:nil
               displayCoordinates:nil
                         trimUser:nil
                     successBlock:^(NSDictionary *status) {
                         NSLog(@"Success: %@", status);
                     } errorBlock:^(NSError *error) {
                         NSLog(@"Error: %@", error);
                     }];
        
    } errorBlock:^(NSError *error) {
        NSLog(@"-- error %@", error);
    }];
}

- (void)callNLPService {
    
    //Formats date and converts to a string
    NSDateFormatter *formatter;
    NSString        *dateString;
    
    formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"hh:mm a"]; //hour,minute, am/pm format
    
    dateString = [formatter stringFromDate:[NSDate date]];
    
    //Concatenates outputMSG string and the current time
    NSString *outputMSG = @"Greetings from Romo at ";
    NSString *outputDate = [outputMSG stringByAppendingString:dateString];
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObject:@"text/html"];
    NSString *sentence = [outputDate stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    
    NSString *url = [NSString stringWithFormat:@"%s/chunks/%@", BASE_URL, sentence];
    
    NSLog(@"%@", url);
    
    /*
    [manager GET:url parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"JSON: %@", responseObject);
        
        _tokens = [responseObject objectForKey:@"tokens"];
        
        [self tweetCommands];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                        message:[error description]
                                                       delegate:nil
                                              cancelButtonTitle:@"Ok"
                                              otherButtonTitles:nil, nil];
        [alert show];
    }];
     */
    
    _tokens = [outputDate componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    [self tweetCommands];
    
}

- (void)callMongoService {
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObject:@"application/json"];
    NSString *apiKey = @"j-xyG_r8AOd5fKxRNNGlmsS9vradUXAU";
    NSString *url = [NSString stringWithFormat:@"%s?apiKey=%@", MONGO_URL, apiKey];
    
    NSLog(@"Calling MongoDB URL: %@", url);
    
    [manager GET:url parameters:nil success:^(AFHTTPRequestOperation *operation,
        id responseObject)
    {
        NSLog(@"JSON: %@", responseObject);
        NSArray *responses = responseObject;
        
        int idx = 0;
        for (id object in responses) {
            NSDictionary* responseMap = object;
            NSString* topicVal = [[responseMap valueForKey:@"topTopics"] objectAtIndex:0];
            NSLog(@"Topic: %@", topicVal);
            
            NSString* tweetVal = [[responseMap valueForKey:@"topStatuses"] objectAtIndex:0];
            NSLog(@"Tweet: %@", tweetVal);
            
            NSString* placeVal = [[responseMap valueForKey:@"topPlaces"] objectAtIndex:0];
            NSLog(@"Place: %@", placeVal);
            
            if (idx == 30) {
                NSLog(@"");
            }
            idx++;
            
            NSString* message;
            if ([tweetVal myContainsString:BURGLARY])
            {
                message = [NSString stringWithFormat:@"Alert from Romo! Burglary reported: %@ By: %@, At: %@", tweetVal, topicVal, placeVal];
            }
            else if ([tweetVal myContainsString:THEFT])
            {
                message = [NSString stringWithFormat:@"Alert from Romo! Theft reported: %@ By: %@, At: %@", tweetVal, topicVal, placeVal];
            }
            else if ([tweetVal myContainsString:ROBBERY])
            {
                message = [NSString stringWithFormat:@"Alert from Romo! Robbery reported: %@ By: %@, At: %@", tweetVal, topicVal, placeVal];
            }
            else if ([tweetVal myContainsString:ASSAULT])
            {
                message = [NSString stringWithFormat:@"Alert from Romo! Assault reported: %@ By: %@, At: %@", tweetVal, topicVal, placeVal];
            }
            else if ([tweetVal myContainsString:BREAKENTER])
            {
                message = [NSString stringWithFormat:@"Alert from Romo! Breaking In reported: %@ By: %@, At: %@", tweetVal, topicVal, placeVal];
            }
            else if ([tweetVal myContainsString:ARSON])
            {
                message = [NSString stringWithFormat:@"Alert from Romo! Arson reported: %@ By: %@, At: %@", tweetVal, topicVal, placeVal];
            }
            else if ([tweetVal myContainsString:ARREST])
            {
                message = [NSString stringWithFormat:@"Alert from Romo! Arrest reported: %@ By: %@, At: %@", tweetVal, topicVal, placeVal];
            }
            else if ([tweetVal myContainsString:VANDALISM])
            {
                message = [NSString stringWithFormat:@"Alert from Romo! Vandalism reported: %@ By: %@, At: %@", tweetVal, topicVal, placeVal];
            }
            else if ([tweetVal myContainsString:SHOOTING])
            {
                message = [NSString stringWithFormat:@"Alert from Romo! Shooting reported: %@ By: %@, At: %@", tweetVal, topicVal, placeVal];
            }
            else if ([tweetVal myContainsString:OTHER])
            {
                message = [NSString stringWithFormat:@"Alert from Romo! Other reported: %@ By: %@, At: %@", tweetVal, topicVal, placeVal];
            }
            
            if (message != nil) {
                // define the range you're interested in
                NSRange stringRange = {0, MIN([message length], 160)};
                
                // adjust the range to include dependent chars
                stringRange = [message rangeOfComposedCharacterSequencesForRange:stringRange];
                
                // Now you can create the short string
                NSString *shortString = [message substringWithRange:stringRange];
                
                [self sendTwilioText:shortString];
            }
        }
    }
    failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
            message:[error description]
        delegate:nil
        cancelButtonTitle:@"Ok"
        otherButtonTitles:nil, nil];
        [alert show];
    }];
}

- (void)sendTwilioText: (NSString*)message {
    NSLog(@"Sending Twilio Text request.");
    
    // Common constants
    NSString *kTwilioSID = @"AC58d6371746b89f7e0b89a52492fee638";
    NSString *kTwilioSecret = @"23613fd085a376bcfdbfe916118c6713";
    NSString *kFromNumber = @"+18163988624";
    NSString *kToNumber = @"+18167198467";//@"+19137306622"; //TODO PHONE NUMBER GOES HERE!
    
    NSString *kMessage = [message stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    
    // Build request
    NSString *urlString = [NSString stringWithFormat:@"https://%@:%@@api.twilio.com/2010-04-01/Accounts/%@/SMS/Messages", kTwilioSID, kTwilioSecret, kTwilioSID];
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:url];
    [request setHTTPMethod:@"POST"];
    
    // Set up the body
    NSString *bodyString = [NSString stringWithFormat:@"From=%@&To=%@&Body=%@", kFromNumber, kToNumber, kMessage];
    NSData *data = [bodyString dataUsingEncoding:NSUTF8StringEncoding];
    [request setHTTPBody:data];
    NSError *error;
    NSURLResponse *response;
    NSData *receivedData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    
    // Handle the received data
    if (error) {
        NSLog(@"Error: %@", error);
    } else {
        NSString *receivedString = [[NSString alloc]initWithData:receivedData encoding:NSUTF8StringEncoding];
        NSLog(@"Request sent. %@", receivedString);
    }     
}

- (NSString*)gotWeatherInfo:(WeatherInfo *)weatherInfo {
    NSMutableString* text = nil;
    if (weatherInfo == nil) {
        text = [NSMutableString stringWithString:YAHOO_WEATHER_ERROR];
        return text;
    }
    text = [NSMutableString stringWithString:@""];
    [text appendString:@"\n***Current Weather Info***\n"];
    if ([self stringIsNonNilOrEmpty:weatherInfo.mCurrentText]) {
        [text appendString:@"Condition: "];
        [text appendString:weatherInfo.mCurrentText];
        [text appendString:@"\n"];
    }
    if ([self stringIsNonNilOrEmpty:[NSString stringWithFormat: @"%d", weatherInfo.mCurrentTempC]]) {
        [text appendString:[NSString stringWithFormat: @"%dºF", weatherInfo.mCurrentTempF]];
        [text appendString:@"\n"];
        [text appendString:[NSString stringWithFormat:@"Humidity: %@%%", weatherInfo.mAtmosphereHumidity]];
        [text appendString:@"\n"];
    }
    [text appendString:@"\n"];
    [text appendString:@"***Today's Forecast***\n"];
    if ([self stringIsNonNilOrEmpty:weatherInfo.mForecast1Info.mForecastDate]) {
        [text appendString:weatherInfo.mForecast1Info.mForecastDate];
        [text appendString:@"\n"];
    }
    if ([self stringIsNonNilOrEmpty:[NSString stringWithFormat: @"%d", weatherInfo.mForecast1Info.mForecastTempLowC]]) {
        [text appendString:[NSString stringWithFormat: @"Low: %dºF  High: %dºF", weatherInfo.mForecast1Info.mForecastTempLowF, weatherInfo.mForecast1Info.mForecastTempHighF]];
        [text appendString:@"\n"];
    }
    if ([self stringIsNonNilOrEmpty:weatherInfo.mForecast1Info.mForecastText]) {
        [text appendString:weatherInfo.mForecast1Info.mForecastText];
        [text appendString:@"\n"];
    }
    
    [self sendTwilioText:text];
    
    return text;
}

- (bool)stringIsNonNilOrEmpty:(NSString*)pString {
    if (pString != nil && ![pString isEqualToString:@""]) {
        return YES;
    }
    return NO;
}

- (void)socket:(GCDAsyncSocket *)sender didAcceptNewSocket:(GCDAsyncSocket *)newSocket
{
    @synchronized(_connectedSockets)
    {
        [_connectedSockets addObject:newSocket];
    }
    
    NSString *host = [newSocket connectedHost];
    UInt16 port = [newSocket connectedPort];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        @autoreleasepool {
            [self logInfo:FORMAT(@"Accepted client %@:%hu", host, port)];
        }
    });
    
    /*
     NSString *welcomeMsg = @"Welcome to the Romo Server\r\n";
     NSData *welcomeData = [welcomeMsg dataUsingEncoding:NSUTF8StringEncoding];
     
     [newSocket writeData:welcomeData withTimeout:-1 tag:WELCOME_MSG];
     */
    [newSocket readDataWithTimeout:NO_TIMEOUT tag:0];
}

- (void)socket:(GCDAsyncSocket *)socket didWriteDataWithTag:(long)tag
{
}

- (void)socket:(GCDAsyncSocket *)socket didReadData:(NSData *)data withTag:(long)tag
{
    dispatch_async(dispatch_get_main_queue(), ^{
        @autoreleasepool {
            NSData *strData = [data subdataWithRange:NSMakeRange(0, [data length])];
            NSString *msg = [[NSString alloc] initWithData:strData encoding:NSUTF8StringEncoding];
            if (msg)
            {
                [self logMessage:msg];
                [self perform:msg:socket];
            }
            else
            {
                [self logError:@"Error converting the data received into UTF-8"];
            }
        }
    });
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)socket withError:(NSError *)err
{
    if (socket != _listenSocket)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            @autoreleasepool {
                [self logInfo:FORMAT(@"Client disconnected")];
            }
        });
    }
    
    @synchronized(_connectedSockets)
    {
        [_connectedSockets removeObject:socket];
    }
    
    isRunning = NO;
}

- (void)perform:(NSString *)msg :(GCDAsyncSocket*) socket
{
    NSLog(@"Calling perform with msg: %@", msg);
    if ([msg caseInsensitiveCompare:FORWARD] == NSOrderedSame)
    {
        // Romo will drive Forward
        self.Romo.emotion = RMCharacterEmotionExcited;
        self.Romo.expression = RMCharacterExpressionExcited;
        [self.Romo3 driveForwardWithSpeed:0.25];
    }
    else if([msg caseInsensitiveCompare:BACK] == NSOrderedSame)
    {
        // Romo will drive Backwards
        self.Romo.emotion = RMCharacterEmotionScared;
        self.Romo.expression = RMCharacterExpressionScared;
        [self.Romo3 driveBackwardWithSpeed:0.25];
    }
    else if([msg caseInsensitiveCompare:LEFT] == NSOrderedSame)
    {
        // Romo will drive Left
        self.Romo.emotion = RMCharacterEmotionDelighted;
        self.Romo.expression = RMCharacterExpressionDizzy;
        [self.Romo3 driveWithRadius:-1.0 speed:0.25];
    }
    else if ([msg caseInsensitiveCompare:RIGHT] == NSOrderedSame)
    {
        // Romo will drive Right
        self.Romo.emotion = RMCharacterEmotionDelighted;
        self.Romo.expression = RMCharacterExpressionDizzy;
        [self.Romo3 driveWithRadius:1.0 speed:0.25];
    }
    else if ([msg caseInsensitiveCompare:STOP] == NSOrderedSame)
    {
        // Romo will Stop
        self.Romo.emotion = RMCharacterEmotionSleepy;
        self.Romo.expression = RMCharacterExpressionExhausted;
        [self.Romo3 stopAllMotion];
    }
    else if ([msg caseInsensitiveCompare:LAUGH] == NSOrderedSame)
    {
        self.Romo.emotion = RMCharacterEmotionHappy;
        // Romo will Laugh
        self.Romo.expression = RMCharacterExpressionLaugh;
    }
    else if ([msg caseInsensitiveCompare:SLOWER]== NSOrderedSame)
    {
        [self.Romo3 driveWithPower:0.15];
    }
    else if ([msg caseInsensitiveCompare:FASTER]== NSOrderedSame)
    {
        [self.Romo3 driveWithPower:0.50];
    }
    else if ([msg caseInsensitiveCompare:STOPSIGN]== NSOrderedSame)
    {
        _activeSign = _stop;
    }
    else if ([msg caseInsensitiveCompare:GOSIGN]== NSOrderedSame)
    {
        _activeSign = _go;
    }
    else if ([msg caseInsensitiveCompare:LEFTSIGN]== NSOrderedSame)
    {
        _activeSign = _turnLeft;
    }
    else if ([msg caseInsensitiveCompare:RIGHTSIGN]== NSOrderedSame)
    {
        _activeSign = _turnRight;
    }
    else if ([msg caseInsensitiveCompare:SLOWSIGN]== NSOrderedSame)
    {
        _activeSign = _slowDown;
    }
    else if ([msg caseInsensitiveCompare:DNESIGN]== NSOrderedSame)
    {
        _activeSign = _doNotEnter;
    }
    else if ([msg caseInsensitiveCompare:TWEET]== NSOrderedSame)
    {
        [self callNLPService];
    }
    else if ([msg caseInsensitiveCompare:OFF]== NSOrderedSame)
    {
        [self turnCameraOff];
        
    }
    else if ([msg caseInsensitiveCompare:ON]== NSOrderedSame)
    {
        [self turnCameraOn];
    }
    else
    {
        self.Romo.emotion = RMCharacterEmotionBewildered;
        self.Romo.expression = RMCharacterExpressionFart;
    }
    
    [socket readDataWithTimeout:NO_TIMEOUT tag:0];
}

- (void) processMovement: (NSString *) sign {
    NSLog(@"Calling processMovement with sign: %@", sign);
    if ([sign caseInsensitiveCompare:_stop] == NSOrderedSame)
    {
        NSLog(@"Stop Sign - Stopping All Motion");
        [self.Romo3 stopAllMotion];
    }
    else if ([sign caseInsensitiveCompare:_go] == NSOrderedSame)
    {
        NSLog(@"Go Sign - Going...");
        [self.Romo3 driveForwardWithSpeed:0.25];
    }
    else if ([sign caseInsensitiveCompare:_doNotEnter] == NSOrderedSame)
    {
        NSLog(@"DNE Sign - Go Back...");
        [self.Romo3 driveBackwardWithSpeed:0.25];
    }
    else if ([sign caseInsensitiveCompare:_turnLeft] == NSOrderedSame)
    {
        NSLog(@"Left Sign - Turning Left...");
        [self.Romo3 driveWithRadius:-1.0 speed:0.25];
    }
    else if ([sign caseInsensitiveCompare:_turnRight] == NSOrderedSame)
    {
        NSLog(@"Right Sign - Turning Right...");
        [self.Romo3 driveWithRadius:1.0 speed:0.25];
    }
    else if ([sign caseInsensitiveCompare:_slowDown] == NSOrderedSame)
    {
        NSLog(@"Slow Sign - Slowing down");
        [self.Romo3 driveWithPower:0.10];
    }
}

#pragma mark - RMCoreDelegate Methods
- (void)robotDidConnect:(RMCoreRobot *)robot
{
    // Currently the only kind of robot is Romo3, so this is just future-proofing
    if ([robot isKindOfClass:[RMCoreRobotRomo3 class]]) {
        self.Romo3 = (RMCoreRobotRomo3 *)robot;
        
        // Change Romo's LED to be solid at 80% power
        [self.Romo3.LEDs setSolidWithBrightness:0.8];
        
        // When we plug Romo in, he get's excited!
        self.Romo.expression = RMCharacterExpressionExcited;
    }
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    self.Romo.emotion = RMCharacterEmotionCurious;
    self.Romo.expression = RMCharacterExpressionTalking;
    
    
    [self.Romo3 tiltToAngle:90 completion:^(BOOL success) {
        if (success) {
            NSLog(@"Successfully tilted");
        } else {
            NSLog(@"Couldn't tilt to the desired angle");
        }
     }];
    
    self.motionManager = [appDelegate sharedMotionManager];
    self.motionManager.gyroUpdateInterval = 0.2;
    self.motionManager.magnetometerUpdateInterval = 0.2;
    self.motionManager.accelerometerUpdateInterval = 0.2;
    self.motionManager.deviceMotionUpdateInterval = 0.2;
    
    self.isBeginning = true;
    self.isClimbing = false;
    self.isOnTop = false;
    self.isDescending = false;
    self.isEnding = false;
    
    [self.motionManager startGyroUpdatesToQueue:[NSOperationQueue currentQueue] withHandler:^(CMGyroData *gyroData, NSError *error) {
        [self outputRotationData:gyroData.rotationRate];
    }];
    
    [self.motionManager startDeviceMotionUpdatesToQueue:[NSOperationQueue currentQueue] withHandler:^(CMDeviceMotion *motion, NSError *error) {
        [self processMotion:motion];
    }];
}

- (void)robotDidDisconnect:(RMCoreRobot *)robot
{
    if (robot == self.Romo3) {
        self.Romo3 = nil;
        
        // When we plug Romo in, he get's excited!
        self.Romo.expression = RMCharacterExpressionSad;
    }
}

#pragma mark - Gesture recognizers

- (void)addGestureRecognizers
{
    // Let's start by adding some gesture recognizers with which to interact with Romo
    UISwipeGestureRecognizer *swipeLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipedLeft:)];
    swipeLeft.direction = UISwipeGestureRecognizerDirectionLeft;
    [self.view addGestureRecognizer:swipeLeft];
    
    UISwipeGestureRecognizer *swipeRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipedRight:)];
    swipeRight.direction = UISwipeGestureRecognizerDirectionRight;
    [self.view addGestureRecognizer:swipeRight];
    
    UISwipeGestureRecognizer *swipeUp = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipedUp:)];
    swipeUp.direction = UISwipeGestureRecognizerDirectionUp;
    [self.view addGestureRecognizer:swipeUp];
    
    UITapGestureRecognizer *tapReceived = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedScreen:)];
    [self.view addGestureRecognizer:tapReceived];
}


- (void)swipedLeft:(UIGestureRecognizer *)sender
{
    // When the user swipes left, Romo will turn in a circle to his left
    [self.Romo3 driveWithRadius:-1.0 speed:1.0];
}

- (void)swipedRight:(UIGestureRecognizer *)sender
{
    // When the user swipes right, Romo will turn in a circle to his right
    [self.Romo3 driveWithRadius:1.0 speed:1.0];
}

// Swipe up to change Romo's emotion to some random emotion
- (void)swipedUp:(UIGestureRecognizer *)sender
{
    int numberOfEmotions = 7;
    
    // Choose a random emotion from 1 to numberOfEmotions
    // That's different from the current emotion
    int randomEmotionValue = 1 + (arc4random() % numberOfEmotions);
    RMCharacterEmotion randomEmotion = (RMCharacterEmotion)randomEmotionValue;
    
    self.Romo.emotion = randomEmotion;
}

// Simply tap the screen to stop Romo
- (void)tappedScreen:(UIGestureRecognizer *)sender
{
    [self.Romo3 stopDriving];
}

#pragma mark - Networking/Sockets

- (NSString *)getIPAddress {
    
    NSString *address = @"error";
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    // retrieve the current interfaces - returns 0 on success
    success = getifaddrs(&interfaces);
    if (success == 0) {
        // Loop through linked list of interfaces
        temp_addr = interfaces;
        while(temp_addr != NULL) {
            if(temp_addr->ifa_addr->sa_family == AF_INET) {
                // Check if interface is en0 which is the wifi connection on the iPhone
                if([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"]) {
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

#pragma mark - Logging Utilities

- (void)logError:(NSString *)msg
{
    NSString *paragraph = [NSString stringWithFormat:@"%@\n", msg];
    
    NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithCapacity:1];
    [attributes setObject:[UIColor redColor] forKey:NSForegroundColorAttributeName];
    
    NSAttributedString *as = [[NSAttributedString alloc] initWithString:paragraph attributes:attributes];
    NSString *str = [as string];
    NSLog(@"%@", str);
}

- (void)logInfo:(NSString *)msg
{
    NSString *paragraph = [NSString stringWithFormat:@"%@\n", msg];
    
    NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithCapacity:1];
    [attributes setObject:[UIColor purpleColor] forKey:NSForegroundColorAttributeName];
    
    NSAttributedString *as = [[NSAttributedString alloc] initWithString:paragraph attributes:attributes];
    
    NSString *str = [as string];
    NSLog(@"%@", str);
}

- (void)logMessage:(NSString *)msg
{
    NSString *paragraph = [NSString stringWithFormat:@"%@\n", msg];
    
    NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithCapacity:1];
    [attributes setObject:[UIColor blackColor] forKey:NSForegroundColorAttributeName];
    
    NSAttributedString *as = [[NSAttributedString alloc] initWithString:paragraph attributes:attributes];
    
    NSString *str = [as string];
    NSLog(@"%@", str);
}


#pragma mark - Capture


- (void)flipAction
{
    _useBackCamera = !_useBackCamera;
    
    [self turnCameraOff];
    [self setupCamera];
    [self turnCameraOn];
}

- (void)setupCamera
{
    _captureDevice = nil;
    
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    
    for (AVCaptureDevice *device in devices)
    {
        if (device.position == AVCaptureDevicePositionFront && !_useBackCamera)
        {
            _captureDevice = device;
            break;
        }
        if (device.position == AVCaptureDevicePositionBack && _useBackCamera)
        {
            _captureDevice = device;
            break;
        }
    }
    
    if (!_captureDevice)
        _captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
}


- (void)turnCameraOn
{
    NSError *error;
    
    _session = [[AVCaptureSession alloc] init];
    [_session beginConfiguration];
    [_session setSessionPreset:AVCaptureSessionPresetMedium];
    
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:_captureDevice error:&error];
    
    if (input == nil)
        NSLog(@"%@", error);
    
    [_session addInput:input];
    
    AVCaptureVideoDataOutput *output = [[AVCaptureVideoDataOutput alloc] init];
    [output setSampleBufferDelegate:self queue:dispatch_queue_create("myQueue", NULL)];
    output.videoSettings = @{(id)kCVPixelBufferPixelFormatTypeKey:@(kCVPixelFormatType_32BGRA)};
    output.alwaysDiscardsLateVideoFrames = YES;
    
    [_session addOutput:output];
    
    [_session commitConfiguration];
    [_session startRunning];
}


- (void)turnCameraOff
{
    [_session stopRunning];
    _session = nil;
}


- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    
    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    
    IplImage *iplimage = nullptr;
    if (baseAddress)
    {
        iplimage = cvCreateImageHeader(cvSize((int)width, (int)height), IPL_DEPTH_8U, 4);
        iplimage->imageData = (char*)baseAddress;
    }
    
    IplImage *workingCopy = cvCreateImage(cvSize((int)height, (int)width), IPL_DEPTH_8U, 4);
    
    if (_captureDevice.position == AVCaptureDevicePositionFront)
    {
        cvTranspose(iplimage, workingCopy);
    }
    else
    {
        cvTranspose(iplimage, workingCopy);
        cvFlip(workingCopy, nil, 1);
    }
    
    cvReleaseImageHeader(&iplimage);
    
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
    
    /*
     NSString *sign = [signs objectAtIndex:signIdx];
     
     if (signIdx < [signs count])
     {
     signIdx = signIdx + 1;
     }
     else
     {
     signIdx = 0;
     }
     
     NSLog(@"THE SIGN IS: %@", sign);
     */
    
    [self didCaptureIplImage:workingCopy:_activeSign];
}


#pragma mark - Image processing


static void ReleaseDataCallback(void *info, const void *data, size_t size)
{
#pragma unused(data)
#pragma unused(size)
    IplImage *iplImage = (IplImage*)info;
    cvReleaseImage(&iplImage);
}

- (CGImageRef)getCGImageFromIplImage:(IplImage*)iplImage
{
    size_t bitsPerComponent = 8;
    size_t bytesPerRow = iplImage->widthStep;
    
    size_t bitsPerPixel;
    CGColorSpaceRef space;
    
    if (iplImage->nChannels == 1)
    {
        bitsPerPixel = 8;
        space = CGColorSpaceCreateDeviceGray();
    }
    else if (iplImage->nChannels == 3)
    {
        bitsPerPixel = 24;
        space = CGColorSpaceCreateDeviceRGB();
    }
    else if (iplImage->nChannels == 4)
    {
        bitsPerPixel = 32;
        space = CGColorSpaceCreateDeviceRGB();
    }
    else
    {
        abort();
    }
    
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault | kCGImageAlphaNone;
    CGDataProviderRef provider = CGDataProviderCreateWithData(iplImage,
                                                              iplImage->imageData,
                                                              0,
                                                              ReleaseDataCallback);
    const CGFloat *decode = NULL;
    bool shouldInterpolate = true;
    CGColorRenderingIntent intent = kCGRenderingIntentDefault;
    
    CGImageRef cgImageRef = CGImageCreate(iplImage->width,
                                          iplImage->height,
                                          bitsPerComponent,
                                          bitsPerPixel,
                                          bytesPerRow,
                                          space,
                                          bitmapInfo,
                                          provider,
                                          decode,
                                          shouldInterpolate,
                                          intent);
    CGColorSpaceRelease(space);
    CGDataProviderRelease(provider);
    return cgImageRef;
}


- (UIImage*)getUIImageFromIplImage:(IplImage*)iplImage
{
    CGImageRef cgImage = [self getCGImageFromIplImage:iplImage];
    UIImage *uiImage = [[UIImage alloc] initWithCGImage:cgImage
                                                  scale:1.0
                                            orientation:UIImageOrientationUp];
    
    CGImageRelease(cgImage);
    return uiImage;
}

#pragma mark - didFinishProcessingImage


- (void)didFinishProcessingImage:(IplImage *)iplImage
{
    dispatch_async(dispatch_get_main_queue(), ^{
        UIImage *uiImage = [self getUIImageFromIplImage:iplImage];
        _imageView.image = uiImage;
    });
}


#pragma mark - Object Detection

- (void)didCaptureIplImage:(IplImage *)iplImage
                          :(NSString *)triggerImageURL
{
    //ipl image is in BGR format, it needs to be converted to RGB for display in UIImageView
    IplImage *imgRGB = cvCreateImage(cvGetSize(iplImage), IPL_DEPTH_8U, 1);
    cvCvtColor(iplImage, imgRGB, CV_BGR2GRAY);
    
    //it is important to release all images once they are not needed EXCEPT the one
    //that is going to be passed to the didFinishProcessingImage: method and
    //displayed in the UIImageView
    cvReleaseImage(&iplImage);
    
    //here you can manipulate RGB image, e.g. blur the image or whatever OCV magic you want
    cv::Mat matRGB = cv::Mat(imgRGB);
    
    //smooths edges
    cv::GaussianBlur(matRGB,
                     matRGB,
                     cv::Size(19, 19),
                     10,
                     10);
    
    cv::Mat img_object= cv::imread([triggerImageURL UTF8String], CV_LOAD_IMAGE_GRAYSCALE);
    cv::Mat img_scene = imgRGB;
    
    if (!img_object.data)
    {
        img_object.deallocate();
        img_object =cv::imread([triggerImageURL UTF8String], CV_LOAD_IMAGE_GRAYSCALE);
    }
    
    if( !img_object.data || !img_scene.data )
    { std::cout<< " --(!) Error reading images " << std::endl;  }
    
    //-- Step 1: Detect the keypoints using SURF Detector
    int minHessian = 400;
    
    cv::SurfFeatureDetector detector( minHessian );
    
    std::vector<cv::KeyPoint> keypoints_object, keypoints_scene;
    
    detector.detect( img_object, keypoints_object );
    detector.detect( img_scene, keypoints_scene );
    
    //-- Step 2: Calculate descriptors (feature vectors)
    cv::SurfDescriptorExtractor extractor;
    
    cv::Mat descriptors_object, descriptors_scene;
    
    extractor.compute( img_object, keypoints_object, descriptors_object );
    extractor.compute( img_scene, keypoints_scene, descriptors_scene );
    
    if ( descriptors_object.empty() ) {
        return;
    }
    if ( descriptors_scene.empty() ) {
        return;
    }
    
    //-- Step 3: Matching descriptor vectors using FLANN matcher
    cv::FlannBasedMatcher matcher;
    std::vector< cv::DMatch > matches;
    matcher.match( descriptors_object, descriptors_scene, matches );
    
    double max_dist = 0; double min_dist = 100;
    
    //-- Quick calculation of max and min distances between keypoints
    for (int i = 0; i < descriptors_object.rows; i++)
    {
        double dist = matches[i].distance;
        if( dist < min_dist ) min_dist = dist;
        if( dist > max_dist ) max_dist = dist;
    }
    
    //printf("-- Max dist : %f \n", max_dist );
    //printf("-- Min dist : %f \n", min_dist );
    
    //-- Draw only "good" matches (i.e. whose distance is less than 3*min_dist )
    std::vector< cv::DMatch > good_matches;
    
    for( int i = 0; i < descriptors_object.rows; i++ )
    { if( matches[i].distance < 3*min_dist )
    { good_matches.push_back( matches[i]); }
    }
    
    cv::Mat img_matches;
    cv::drawMatches( img_object, keypoints_object, img_scene, keypoints_scene,
                    good_matches, img_matches, cv::Scalar::all(-1), cv::Scalar::all(-1),
                    std::vector<char>(), cv::DrawMatchesFlags::NOT_DRAW_SINGLE_POINTS );
    
    //-- Localize the object
    std::vector<cv::Point2f> obj;
    std::vector<cv::Point2f> scene;
    
    for( int i = 0; i < good_matches.size(); i++ )
    {
        //-- Get the keypoints from the good matches
        obj.push_back( keypoints_object[ good_matches[i].queryIdx ].pt );
        scene.push_back( keypoints_scene[ good_matches[i].trainIdx ].pt );
    }
    
    cv::Mat H = findHomography( obj, scene, CV_RANSAC );
    
    //-- Get the corners from the image_1 ( the object to be "detected" )
    std::vector<cv::Point2f> obj_corners(4);
    obj_corners[0] = cvPoint(0,0); obj_corners[1] = cvPoint( img_object.cols, 0 );
    obj_corners[2] = cvPoint( img_object.cols, img_object.rows ); obj_corners[3] = cvPoint( 0, img_object.rows );
    std::vector<cv::Point2f> scene_corners(4);
    
    perspectiveTransform( obj_corners, scene_corners, H);
    
    //-- Draw lines between the corners (the mapped object in the scene - image_2 )
    line( img_matches, scene_corners[0] + cv::Point2f( img_object.cols, 0), scene_corners[1] + cv::Point2f( img_object.cols, 0), cv::Scalar( 0, 255, 0), 4 );
    line( img_matches, scene_corners[1] + cv::Point2f( img_object.cols, 0), scene_corners[2] + cv::Point2f( img_object.cols, 0), cv::Scalar( 0, 255, 0), 4 );
    line( img_matches, scene_corners[2] + cv::Point2f( img_object.cols, 0), scene_corners[3] + cv::Point2f( img_object.cols, 0), cv::Scalar( 0, 255, 0), 4 );
    line( img_matches, scene_corners[3] + cv::Point2f( img_object.cols, 0), scene_corners[0] + cv::Point2f( img_object.cols, 0), cv::Scalar( 0, 255, 0), 4 );
    
    double area = contourArea(scene_corners);
    //printf("-- AREA %.2f", area);
    if(area > 10000)
    {
        std::cout<<"GOT IT !!!!\n Perform your action on object recognition here";
        [self processMovement:triggerImageURL];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        _imageView.image=[self imageWithCVMat:img_matches];
    });
    
    [self didFinishProcessingImage:imgRGB];
}

- (UIImage *)imageWithCVMat:(const cv::Mat&)cvMat
{
    NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize() * cvMat.total()];
    
    CGColorSpaceRef colorSpace;
    
    if (cvMat.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    CGImageRef imageRef = CGImageCreate
        (cvMat.cols,
        // Width
        cvMat.rows,                                     // Height
        8,                                              // Bits per component
        8 * cvMat.elemSize(),                           // Bits per pixel
        cvMat.step[0],                                  // Bytes per row
        colorSpace,                                     // Colorspace
        kCGImageAlphaNone | kCGBitmapByteOrderDefault,  // Bitmap info flags
        provider,                                       // CGDataProviderRef
        NULL,                                           // Decode
        false,                                          // Should interpolate
        kCGRenderingIntentDefault);                     // Intent
    
    UIImage *image = [[UIImage alloc] initWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return image;
}

@end
