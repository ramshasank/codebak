//
//  ViewController.m
//  Tutorial21
//
//  Created by Doddala, Mohan Krishna (UMKC-Student) on 6/22/15.
//  Copyright (c) 2015 umkc. All rights reserved.
//

#import "ViewController.h"
#import "AFHTTPRequestOperationManager.h"
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
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
    [_sentenceTextField resignFirstResponder];
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    
    NSString *sentense = [_sentenceTextField.text stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    
    NSString *url = [NSString stringWithFormat:@"%s%@", BASE_URL, sentense];
    
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    [manager GET:url parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        //        NSString *string = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
        operation.responseSerializer.acceptableContentTypes = [NSSet setWithObject:@"audio/mpeg"];
        //AudioPlayer *player = (AudioPlayer *) responseObject;
        //NSSound *round = [NSSound soundNamed:@"replace-with-file-name-without-the-extension"];
        //NSString *responseString=[NSString stringWithUTF8String:[responseObject bytes]];
        
        //
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
