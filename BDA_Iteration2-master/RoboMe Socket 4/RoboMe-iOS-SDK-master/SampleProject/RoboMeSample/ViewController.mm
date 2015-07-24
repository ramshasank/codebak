    //
//  ViewController.m
//  RoboMeBasicSample
//
//  Copyright (c) 2013 WowWee Group Limited. All rights reserved.
//

#import "ViewController.h"
#import "GCDAsyncSocket.h"
#include <ifaddrs.h>
#include <arpa/inet.h>
#import <AddressBookUI/AddressBookUI.h>


#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <CoreAudio/CoreAudioTypes.h>
//#import <CoreAudioKit/CoreAudioKit.h>
#import <AudioUnit/AudioUnit.h>
//@import AddressBook;
#import <EventKit/EventKit.h>

#define BASE_URL "http://cs590bdnlpservices.mybluemix.net/api/service"



#define BASE_URL1 "http://api.openweathermap.org/data/2.5/weather?"
#define BASE_URL2 "http://tts-api.com/tts.mp3?"


#define WELCOME_MSG  0
#define ECHO_MSG     1
#define WARNING_MSG  2

#define READ_TIMEOUT 15.0
#define READ_TIMEOUT_EXTENSION 10.0

#define FORMAT(format, ...) [NSString stringWithFormat:(format), ##__VA_ARGS__]
#define PORT 1234


@interface ViewController () {
    dispatch_queue_t socketQueue;
    NSMutableArray *connectedSockets;
    BOOL isRunning;
    
    
    GCDAsyncSocket *listenSocket;
   
    
    
}

@property (nonatomic, strong) RoboMe *roboMe;

@property (nonatomic, strong) NSArray *tags;
@property (nonatomic, strong) NSArray *tokens;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // create RoboMe object
    self.roboMe = [[RoboMe alloc] initWithDelegate: self];
    
    // start listening for events from RoboMe
    [self.roboMe startListening];
    
    // Do any additional setup after loading the view, typically from a nib.
    socketQueue = dispatch_queue_create("socketQueue", NULL);
    
    listenSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:socketQueue];
    
    // Setup an array to store all accepted client connections
    connectedSockets = [[NSMutableArray alloc] initWithCapacity:1];
    
    isRunning = NO;
    
    NSLog(@"%@", [self getIPAddress]);
    
    [self toggleSocketState];   //Statrting the Socket
    
    self.eventStore = [[EKEventStore alloc]init];
    self.eventStoreAccessGranted = NO;
    [self.eventStore requestAccessToEntityType:EKEntityTypeReminder completion:^(BOOL success, NSError *error)
     {
         self.eventStoreAccessGranted = success;
         if(!success)
             NSLog(@"User has not granted access to add reminders.");
     }];
    
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

- (void)volumeChanged:(float)volume {
    if([self.roboMe isRoboMeConnected] && volume < 0.75) {
        [self displayText: @"Volume needs to be set above 75% to send commands"];
    }
}

- (void)roboMeConnected {
    [self displayText: @"RoboMe Connected!"];
}

- (void)roboMeDisconnected {
    [self displayText: @"RoboMe Disconnected"];
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
        [self.roboMe sendCommand:kRobot_MoveForwardFastest];
        [self speakleft:command];
        
    } else if ([cmd isEqualToString:@"RIGHT"]) {
        [self.roboMe sendCommand: kRobot_TurnRight90Degrees];
        [self.roboMe sendCommand:kRobot_MoveForward];
        [self speakright:command];
    } else if ([cmd isEqualToString:@"BACKWARD"]) {
        [self.roboMe sendCommand: kRobot_MoveBackwardFastest];
    } else if ([cmd isEqualToString:@"FORWARD"]) {
        [self.roboMe sendCommand: kRobot_MoveForwardFastest];
    } else if([cmd isEqualToString:@"STOP"]){
        [self.roboMe sendCommand:kRobot_Stop];
    } else if([cmd isEqualToString:@"UP"]){
        [self.roboMe sendCommand:kRobot_MoveForward];
        [self speakforward:command];
    } else if ([cmd isEqualToString:@"DOWN"]){
        [self.roboMe sendCommand:kRobot_MoveBackward];
        [self speakback:command];
    } else if ([cmd isEqualToString:@"ADDRESS"]){
        [self showPicker:command];
    } else if([cmd isEqualToString:@"CALL"]){
        [self makecall:command];
    }  else if ([cmd isEqualToString:@"MUSIC"]){
        [self playMusic:command];
    }   else if ([cmd isEqualToString:@"WHAT IS YOUR NAME"]){
        [self texttospeech:command];
    }   else if([cmd isEqualToString:@"HI"]){
        [self texttospeech1:command];
    }   else if([cmd isEqualToString:@"HOW DO YOU DO"]){
        [self texttospeech2:command];
    }   else if([cmd isEqualToString:@"WHAT DO YOU DO"]){
        [self texttospeech3:command];
    }   else if ([cmd isEqualToString:@"WHERE DO YOU LIVE"]){
        [self texttospeech4:command];
    }   else if ([cmd isEqualToString:@"WHAT DO YOU LIKE TO DO"]){
        [self texttospeech5:command];
    }   else if ([cmd isEqualToString:@"WHO IS YOUR PROFESSOR"]){
        [self texttospeech6:command];
    }

    
}
-(void)performNLP:(NSString *)command{
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSString *sentense = [command stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    NSString *url = [NSString stringWithFormat:@"%s/tokenize/%@", BASE_URL, sentense];
   // NSString *comnd = [command string];
    NSLog(@"%@", url);
    
    [manager GET:url parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"JSON: %@", responseObject);
        
        _tokens = [responseObject objectForKey:@"results"];
        //_tags = [responseObject objectForKey:@"tags"];
        
         NSLog(@"Tags are: %@", _tags);
        
      /*  NSInteger idx = [_tags indexOfObject:@"NN"];
        if([_tokens[idx] isEqual:@"call"])
        {

            NSLog(@"NAme: @%",_tokens[idx]);
         NSInteger idx1 = [_tags indexOfObject:@"NNP"];
            NSLog(@"NAme: @%",_tokens[idx]);
            [self call:_tokens[idx1]];
        }*/
       
            //[self call:_tokens[1]];
     
        
        
        
        
        
        
    }  failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                        message:[error description]
                                                       delegate:nil
                                              cancelButtonTitle:@"Ok"
                                              otherButtonTitles:nil, nil];
        [alert show];
        
       
    }];
    
}


-(void)call:(NSString *)name{
    
    ABAddressBookRequestAccessWithCompletion(ABAddressBookCreateWithOptions(NULL, nil), ^(bool granted, CFErrorRef errorCoding) {
        if (!granted){
            //4
            NSLog(@"Just denied");
            return;
        }
        //5
        NSLog(@"Just authorized");
    });
    
    ABAddressBookRef addressBook = ABAddressBookCreate();

    NSString *full = @"Sweety USA";
    CFArrayRef contacts = ABAddressBookCopyPeopleWithName(addressBook, (__bridge CFStringRef)(name));
    NSLog(@"contacts %s",contacts);
    CFIndex nPeople = CFArrayGetCount(contacts);
    NSLog(@"npeople %ld",nPeople);
    if ((contacts != nil) && (CFArrayGetCount(contacts) > 0))
    {
        ABRecordRef person = CFArrayGetValueAtIndex(contacts, 0);
        NSMutableArray *phoneNumbers = [[NSMutableArray alloc] init];
        ABMultiValueRef multiPhones = ABRecordCopyValue(person,kABPersonPhoneProperty);
        for(CFIndex i=0;i<ABMultiValueGetCount(multiPhones);++i) {
        CFStringRef phoneNumberRef = (CFStringRef)ABMultiValueCopyValueAtIndex(multiPhones, i);
            NSString *phoneNumber = (__bridge NSString *) phoneNumberRef;
            
            [phoneNumbers addObject:phoneNumber];
            NSLog(@"phone number %@",phoneNumber);
            
            
            NSMutableString *strippedString = [NSMutableString
                                               stringWithCapacity:phoneNumber.length];
            
            NSScanner *scanner = [NSScanner scannerWithString:phoneNumber];
            NSCharacterSet *numbers = [NSCharacterSet
                                       characterSetWithCharactersInString:@"0123456789"];
            
            while ([scanner isAtEnd] == NO) {
                NSString *buffer;
                if ([scanner scanCharactersFromSet:numbers intoString:&buffer]) {
                    [strippedString appendString:buffer];
                    
                } else {
                    [scanner setScanLocation:([scanner scanLocation] + 1)];
                }
            }
            
            NSLog(@"%@", strippedString); // "123123123"
            
            // [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"tel://%@",phoneNumber]];
            //[self callWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"tel:%@",phoneNumber]]];
            
            NSString *phoneCallNum = [NSString stringWithFormat:@"tel://%@",strippedString ];
            
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:phoneCallNum]];
            
            
        }
        

        
        
        
        
    }
    else
    {
        // Show an alert if "Appleseed" is not in Contacts
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                        message:@"Could not find Appleseed in the Contacts application"
                                                       delegate:nil
                                              cancelButtonTitle:@"Cancel"
                                              otherButtonTitles:nil];
        [alert show];
    }
    CFRelease(addressBook);
    CFRelease(contacts);
    

}
-(void)texttospeech:(NSString *)command{
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    
    
    NSString *messageBody = [NSString stringWithFormat:@"My name is Robo Assist"];
    
    //////////
    
    NSString *sentence = [messageBody stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    
    
    NSString *url = [NSString stringWithFormat:@"%sq=%@",BASE_URL2 , sentence];
    
    NSLog(@"url is: %@",url);
    
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    [manager GET:url parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        operation.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"audio/mpeg",nil];
        
        
        
        NSLog(@"NSObject: %@", responseObject);
        
        NSData *audioData = responseObject;
        
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
        [[AVAudioSession sharedInstance] setActive:YES error:nil];
        
        self->_audioPlayer = [[AVAudioPlayer alloc] initWithData:audioData error:nil]; // audioPlayer must be a strong property. Do not create it locally
        
        [self->_audioPlayer prepareToPlay];
        [self->_audioPlayer play];
        
        // NSLog(@"responseString: %@", responseString);
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                        message:[error description]
                                                       delegate:nil
                                              cancelButtonTitle:@"Ok"
                                              otherButtonTitles:nil, nil];
        [alert show];
    }];
    
    
}


-(void)speakleft:(NSString *)command{

    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    
    
    NSString *messageBody = [NSString stringWithFormat:@"Taking Left direction"];
        
        //////////
        
        NSString *sentence = [messageBody stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
        
        
        NSString *url = [NSString stringWithFormat:@"%sq=%@",BASE_URL2 , sentence];
        
        NSLog(@"url is: %@",url);
        
        manager.responseSerializer = [AFHTTPResponseSerializer serializer];
        [manager GET:url parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
            
            operation.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"audio/mpeg",nil];
            
            
            
            NSLog(@"NSObject: %@", responseObject);
            
            NSData *audioData = responseObject;
            
            [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
            [[AVAudioSession sharedInstance] setActive:YES error:nil];
            
            self->_audioPlayer = [[AVAudioPlayer alloc] initWithData:audioData error:nil]; // audioPlayer must be a strong property. Do not create it locally
            
            [self->_audioPlayer prepareToPlay];
            [self->_audioPlayer play];
            
            // NSLog(@"responseString: %@", responseString);
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Error: %@", error);
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                            message:[error description]
                                                           delegate:nil
                                                  cancelButtonTitle:@"Ok"
                                                  otherButtonTitles:nil, nil];
            [alert show];
        }];
    

}

-(void)speakright:(NSString *)command{
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    
    
    NSString *messageBody = [NSString stringWithFormat:@"Taking right direction"];
    
    //////////
    
    NSString *sentence = [messageBody stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    
    
    NSString *url = [NSString stringWithFormat:@"%sq=%@",BASE_URL2 , sentence];
    
    NSLog(@"url is: %@",url);
    
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    [manager GET:url parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        operation.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"audio/mpeg",nil];
        
        
        
        NSLog(@"NSObject: %@", responseObject);
        
        NSData *audioData = responseObject;
        
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
        [[AVAudioSession sharedInstance] setActive:YES error:nil];
        
        self->_audioPlayer = [[AVAudioPlayer alloc] initWithData:audioData error:nil]; // audioPlayer must be a strong property. Do not create it locally
        
        [self->_audioPlayer prepareToPlay];
        [self->_audioPlayer play];
        
        // NSLog(@"responseString: %@", responseString);
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                        message:[error description]
                                                       delegate:nil
                                              cancelButtonTitle:@"Ok"
                                              otherButtonTitles:nil, nil];
        [alert show];
    }];
    
    
}


-(void)speakforward:(NSString *)command{
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    
    
    NSString *messageBody = [NSString stringWithFormat:@"Moving Forward"];
    
    //////////
    
    NSString *sentence = [messageBody stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    
    
    NSString *url = [NSString stringWithFormat:@"%sq=%@",BASE_URL2 , sentence];
    
    NSLog(@"url is: %@",url);
    
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    [manager GET:url parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        operation.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"audio/mpeg",nil];
        
        
        
        NSLog(@"NSObject: %@", responseObject);
        
        NSData *audioData = responseObject;
        
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
        [[AVAudioSession sharedInstance] setActive:YES error:nil];
        
        self->_audioPlayer = [[AVAudioPlayer alloc] initWithData:audioData error:nil]; // audioPlayer must be a strong property. Do not create it locally
        
        [self->_audioPlayer prepareToPlay];
        [self->_audioPlayer play];
        
        // NSLog(@"responseString: %@", responseString);
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                        message:[error description]
                                                       delegate:nil
                                              cancelButtonTitle:@"Ok"
                                              otherButtonTitles:nil, nil];
        [alert show];
    }];
    
    
}


-(void)speakback:(NSString *)command{
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    
    
    NSString *messageBody = [NSString stringWithFormat:@"Moving backward"];
    
    //////////
    
    NSString *sentence = [messageBody stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    
    
    NSString *url = [NSString stringWithFormat:@"%sq=%@",BASE_URL2 , sentence];
    
    NSLog(@"url is: %@",url);
    
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    [manager GET:url parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        operation.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"audio/mpeg",nil];
        
        
        
        NSLog(@"NSObject: %@", responseObject);
        
        NSData *audioData = responseObject;
        
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
        [[AVAudioSession sharedInstance] setActive:YES error:nil];
        
        self->_audioPlayer = [[AVAudioPlayer alloc] initWithData:audioData error:nil]; // audioPlayer must be a strong property. Do not create it locally
        
        [self->_audioPlayer prepareToPlay];
        [self->_audioPlayer play];
        
        // NSLog(@"responseString: %@", responseString);
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                        message:[error description]
                                                       delegate:nil
                                              cancelButtonTitle:@"Ok"
                                              otherButtonTitles:nil, nil];
        [alert show];
    }];
    
    
}



-(void)texttospeech1:(NSString *)command{
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    
    
    NSString *messageBody = [NSString stringWithFormat:@"Hello!!!!!"];
    
    //////////
    
    NSString *sentence = [messageBody stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    
    
    NSString *url = [NSString stringWithFormat:@"%sq=%@",BASE_URL2 , sentence];
    
    NSLog(@"url is: %@",url);
    
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    [manager GET:url parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        operation.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"audio/mpeg",nil];
        
        
        
        NSLog(@"NSObject: %@", responseObject);
        
        NSData *audioData = responseObject;
        
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
        [[AVAudioSession sharedInstance] setActive:YES error:nil];
        
        self->_audioPlayer = [[AVAudioPlayer alloc] initWithData:audioData error:nil]; // audioPlayer must be a strong property. Do not create it locally
        
        [self->_audioPlayer prepareToPlay];
        [self->_audioPlayer play];
        
        // NSLog(@"responseString: %@", responseString);
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                        message:[error description]
                                                       delegate:nil
                                              cancelButtonTitle:@"Ok"
                                              otherButtonTitles:nil, nil];
        [alert show];
    }];
    
    
}

-(void)texttospeech2:(NSString *)command{
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    
    
    NSString *messageBody = [NSString stringWithFormat:@"HOW DO YOU DO, PLEASED TO MEET YOU"];
    
    //////////
    
    NSString *sentence = [messageBody stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    
    
    NSString *url = [NSString stringWithFormat:@"%sq=%@",BASE_URL2 , sentence];
    
    NSLog(@"url is: %@",url);
    
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    [manager GET:url parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        operation.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"audio/mpeg",nil];
        
        
        
        NSLog(@"NSObject: %@", responseObject);
        
        NSData *audioData = responseObject;
        
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
        [[AVAudioSession sharedInstance] setActive:YES error:nil];
        
        self->_audioPlayer = [[AVAudioPlayer alloc] initWithData:audioData error:nil]; // audioPlayer must be a strong property. Do not create it locally
        
        [self->_audioPlayer prepareToPlay];
        [self->_audioPlayer play];
        
        // NSLog(@"responseString: %@", responseString);
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                        message:[error description]
                                                       delegate:nil
                                              cancelButtonTitle:@"Ok"
                                              otherButtonTitles:nil, nil];
        [alert show];
    }];
    
    
}

-(void)texttospeech3:(NSString *)command{
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    
    
    NSString *messageBody = [NSString stringWithFormat:@"I'M AN ASSISTANT"];
    
    //////////
    
    NSString *sentence = [messageBody stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    
    
    NSString *url = [NSString stringWithFormat:@"%sq=%@",BASE_URL2 , sentence];
    
    NSLog(@"url is: %@",url);
    
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    [manager GET:url parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        operation.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"audio/mpeg",nil];
        
        
        
        NSLog(@"NSObject: %@", responseObject);
        
        NSData *audioData = responseObject;
        
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
        [[AVAudioSession sharedInstance] setActive:YES error:nil];
        
        self->_audioPlayer = [[AVAudioPlayer alloc] initWithData:audioData error:nil]; // audioPlayer must be a strong property. Do not create it locally
        
        [self->_audioPlayer prepareToPlay];
        [self->_audioPlayer play];
        
        // NSLog(@"responseString: %@", responseString);
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                        message:[error description]
                                                       delegate:nil
                                              cancelButtonTitle:@"Ok"
                                              otherButtonTitles:nil, nil];
        [alert show];
    }];
    
    
}

-(void)texttospeech4:(NSString *)command{
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    
    
    NSString *messageBody = [NSString stringWithFormat:@"I LIVE IN KANSAS CITY"];
    
    //////////
    
    NSString *sentence = [messageBody stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    
    
    NSString *url = [NSString stringWithFormat:@"%sq=%@",BASE_URL2 , sentence];
    
    NSLog(@"url is: %@",url);
    
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    [manager GET:url parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        operation.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"audio/mpeg",nil];
        
        
        
        NSLog(@"NSObject: %@", responseObject);
        
        NSData *audioData = responseObject;
        
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
        [[AVAudioSession sharedInstance] setActive:YES error:nil];
        
        self->_audioPlayer = [[AVAudioPlayer alloc] initWithData:audioData error:nil]; // audioPlayer must be a strong property. Do not create it locally
        
        [self->_audioPlayer prepareToPlay];
        [self->_audioPlayer play];
        
        // NSLog(@"responseString: %@", responseString);
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                        message:[error description]
                                                       delegate:nil
                                              cancelButtonTitle:@"Ok"
                                              otherButtonTitles:nil, nil];
        [alert show];
    }];
    
    
}



-(void)texttospeech5:(NSString *)command{
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    
    
    NSString *messageBody = [NSString stringWithFormat:@"I LOVE TO WORK FOR MY MASTER"];
    
    //////////
    
    NSString *sentence = [messageBody stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    
    
    NSString *url = [NSString stringWithFormat:@"%sq=%@",BASE_URL2 , sentence];
    
    NSLog(@"url is: %@",url);
    
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    [manager GET:url parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        operation.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"audio/mpeg",nil];
        
        
        
        NSLog(@"NSObject: %@", responseObject);
        
        NSData *audioData = responseObject;
        
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
        [[AVAudioSession sharedInstance] setActive:YES error:nil];
        
        self->_audioPlayer = [[AVAudioPlayer alloc] initWithData:audioData error:nil]; // audioPlayer must be a strong property. Do not create it locally
        
        [self->_audioPlayer prepareToPlay];
        [self->_audioPlayer play];
        
        // NSLog(@"responseString: %@", responseString);
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                        message:[error description]
                                                       delegate:nil
                                              cancelButtonTitle:@"Ok"
                                              otherButtonTitles:nil, nil];
        [alert show];
    }];
    
    
}
-(void)texttospeech6:(NSString *)command{
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    
    
    NSString *messageBody = [NSString stringWithFormat:@"PROFESSOR UG LEE"];
    
    //////////
    
    NSString *sentence = [messageBody stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    
    
    NSString *url = [NSString stringWithFormat:@"%sq=%@",BASE_URL2 , sentence];
    
    NSLog(@"url is: %@",url);
    
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    [manager GET:url parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        operation.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"audio/mpeg",nil];
        
        
        
        NSLog(@"NSObject: %@", responseObject);
        
        NSData *audioData = responseObject;
        
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
        [[AVAudioSession sharedInstance] setActive:YES error:nil];
        
        self->_audioPlayer = [[AVAudioPlayer alloc] initWithData:audioData error:nil]; // audioPlayer must be a strong property. Do not create it locally
        
        [self->_audioPlayer prepareToPlay];
        [self->_audioPlayer play];
        
        // NSLog(@"responseString: %@", responseString);
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                        message:[error description]
                                                       delegate:nil
                                              cancelButtonTitle:@"Ok"
                                              otherButtonTitles:nil, nil];
        [alert show];
    }];
    
    
}



- (IBAction)clickMeButton:(id)sender {

    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    
    NSString *sentense = [_enterCity.text stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    
    NSString *url = [NSString stringWithFormat:@"%sq=%@", BASE_URL1, sentense];
    
    
    [manager GET:url parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"JSON: %@", responseObject);
        
        NSDictionary *details = [responseObject objectForKey:@"main"];
        NSString *temp = [details objectForKey:@"temp"];
        NSString *temp_min = [details objectForKey:@"temp_min"];
        
        
        //   NSArray *array=[responseObject objectForKey:@"weather"];
        // NSDictionary *details2=[array objectAtIndex:0];
        //  NSString *description=[details2 objectForKey:@"description"];
        
        NSLog(@"temp: %@", temp);
        NSLog(@"temp_min:%@", temp_min);
        
        NSString *messageBody = [NSString stringWithFormat:@"temp: %@,@temp_min: %@", temp, temp_min];
        
        //////////
        
        NSString *sentence = [messageBody stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
        
        
        NSString *url = [NSString stringWithFormat:@"%sq=%@",BASE_URL2 , sentence];
        
        NSLog(@"url is: %@",url);
        
        manager.responseSerializer = [AFHTTPResponseSerializer serializer];
        [manager GET:url parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
            
            operation.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"audio/mpeg",nil];
            
            
            
            NSLog(@"NSObject: %@", responseObject);
            
            NSData *audioData = responseObject;
            
            [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
            [[AVAudioSession sharedInstance] setActive:YES error:nil];
            
            self->_audioPlayer = [[AVAudioPlayer alloc] initWithData:audioData error:nil]; // audioPlayer must be a strong property. Do not create it locally
            
            [self->_audioPlayer prepareToPlay];
            [self->_audioPlayer play];
            
            // NSLog(@"responseString: %@", responseString);
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Error: %@", error);
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                            message:[error description]
                                                           delegate:nil
                                                  cancelButtonTitle:@"Ok"
                                                  otherButtonTitles:nil, nil];
            [alert show];
        }];
        
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                        message:[error description]
                                                       delegate:nil
                                              cancelButtonTitle:@"Ok"
                                              otherButtonTitles:nil, nil];
        [alert show];
    }];

    
    
    
}


-(void)makecall:(NSString *)command{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"tel:5625526253"]];
}

-(void)playMusic:(NSString *)command{
    NSString *audioFilePath = [[NSBundle mainBundle] pathForResource:@"BlankSpace" ofType:@"mp3"];
    NSURL *pathAsURL = [[NSURL alloc] initFileURLWithPath:audioFilePath];
    
    // Init the audio player.
    NSError *error;
    _player = [[AVAudioPlayer alloc] initWithContentsOfURL:pathAsURL error:&error];
    //[_player setDelegate:self];
    
    // Check out what's wrong in case that the player doesn't init.
    if (error) {
        NSLog(@"%@", [error localizedDescription]);
    }
    else{
        // If everything is fine, just play.
        [_player play];
        //[lblStatus setText:@"Now playing..."];
    }

}

-(void)showPicker:(NSString *)command{
 
 ABPeoplePickerNavigationController *picker =
 [[ABPeoplePickerNavigationController alloc] init];

 //picker.peoplePickerDelegate = self;
 
 [self presentModalViewController:picker animated:YES];

 }

 - (void)peoplePickerNavigationControllerDidCancel:
 (ABPeoplePickerNavigationController *)peoplePicker
 {
 [self dismissModalViewControllerAnimated:YES];
 }
 /*
 
 - (BOOL)peoplePickerNavigationController:
 (ABPeoplePickerNavigationController *)peoplePicker
 shouldContinueAfterSelectingPerson:(ABRecordRef)person {
 
 [self displayPerson:person];
 [self dismissModalViewControllerAnimated:YES];
 
 return NO;
 }
 
 - (BOOL)peoplePickerNavigationController:
 (ABPeoplePickerNavigationController *)peoplePicker
 shouldContinueAfterSelectingPerson:(ABRecordRef)person
 property:(ABPropertyID)property
 identifier:(ABMultiValueIdentifier)identifier
 {
 return NO;
 }
 
 - (void)displayPerson:(ABRecordRef)person
 {
 NSString* name = (__bridge_transfer NSString*)ABRecordCopyValue(person,
 kABPersonFirstNameProperty);
 self.firstName.text = name;
 
 NSString* phone = nil;
 ABMultiValueRef phoneNumbers = ABRecordCopyValue(person,
 kABPersonPhoneProperty);
 if (ABMultiValueGetCount(phoneNumbers) > 0) {
 phone = (__bridge_transfer NSString*)
 ABMultiValueCopyValueAtIndex(phoneNumbers, 0);
 } else {
 phone = @"[None]";
 }
 self.phoneNumber.text = phone;
 CFRelease(phoneNumbers);
 }
*/

#pragma mark - Button callbacks

// The methods below send the desired command to RoboMe.
// Typically you would want to start a timer to repeatly send the
// command while the button is held down. For simplicity this wasn't
// included however if you do decide to implement this we recommand
// sending commands every 500ms for smooth movement.
// See RoboMeCommandHelper.h for a full list of robot commands
- (IBAction)moveForwardBtnPressed:(UIButton *)sender {
    // Adds command to the queue to send to the robot
    [self.roboMe sendCommand: kRobot_MoveForwardFastest];
}

- (IBAction)moveBackwardBtnPressed:(UIButton *)sender {
    [self.roboMe sendCommand: kRobot_MoveBackwardFastest];
}

- (IBAction)turnLeftBtnPressed:(UIButton *)sender {
    [self.roboMe sendCommand: kRobot_TurnLeftFastest];
}

- (IBAction)turnRightBtnPressed:(UIButton *)sender {
    [self.roboMe sendCommand: kRobot_TurnRightFastest];
}

- (IBAction)headUpBtnPressed:(UIButton *)sender {
    [self.roboMe sendCommand: kRobot_HeadTiltAllUp];
}

- (IBAction)headDownBtnPressed:(UIButton *)sender {
    [self.roboMe sendCommand: kRobot_HeadTiltAllDown];
}
#pragma mark -
#pragma mark Socket

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
    [self performNLP:msg];
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

- (IBAction)buttonAddReminder:(id)sender {
    
    if(!self.eventStoreAccessGranted)
        return;
    
    NSDate *now = [NSDate date];
    
    NSDate *alarmDate = [now dateByAddingTimeInterval:5];
    
    EKAlarm *ourAlarm = [EKAlarm alarmWithAbsoluteDate:alarmDate];
    
    EKReminder *newReminder = [EKReminder reminderWithEventStore:self.eventStore];
    
    newReminder.title = @"Stand up and stretch. ";
    newReminder.calendar = [_eventStore defaultCalendarForNewReminders];
    
    [newReminder addAlarm:ourAlarm];
    
    NSError *error = nil;
    
    [self.eventStore saveReminder:newReminder commit:YES error:&error];
}
@end
