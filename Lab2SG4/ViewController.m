//
//  ViewController.m
//  SG4Tut4Serv
//
//  Created by Kothuri, Umamaheswara Rao (UMKC-Student) on 6/19/15.
//  Copyright (c) 2015 Kothuri, Umamaheswara Rao (UMKC-Student). All rights reserved.
//


#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import "AFHTTPRequestOperationManager.h"
#define BASE_URL "http://translate.google.com/translate_tts?tl=en&q="

@interface ViewController ()
@property (strong, nonatomic) AVAudioPlayer *audioPlayer;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)textToSpeech:(id)sender {
    
    [_textField resignFirstResponder];
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    
    NSString *sentense = [_textField.text stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    
    NSString *url = [NSString stringWithFormat:@"%s%@", BASE_URL, sentense];
    
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    [manager GET:url parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
  
        operation.responseSerializer.acceptableContentTypes = [NSSet setWithObject:@"audio/mpeg"];
     
        NSLog(@"NSObject: %@", responseObject);
        
        NSData *audioData = responseObject;
        
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
        [[AVAudioSession sharedInstance] setActive:YES error:nil];
        
        self.audioPlayer = [[AVAudioPlayer alloc] initWithData:audioData error:nil]; // audioPlayer must be a strong property. Do not create it locally
        
        [self.audioPlayer prepareToPlay];
        [self.audioPlayer play];
        
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

@end
