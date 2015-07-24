//
//  FJFaceRecognitionViewController.m
//  opencvtest
//
//  Created by Engin Kurutepe on 28/01/15.
//  Copyright (c) 2015 Fifteen Jugglers Software. All rights reserved.
//

#import "FJFaceRecognitionViewController.h"
#import "FJFaceRecognizer.h"
#import "AFHTTPRequestOperationManager.h"
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>
#define BASE_URL2 "http://tts-api.com/tts.mp3?"

@interface FJFaceRecognitionViewController ()
{
AVAudioPlayer *_audioPlayer;
}
@property (strong, nonatomic) IBOutlet UILabel *nameLabel;
@property (strong, nonatomic) IBOutlet UILabel *confidenceLabel;
@property (strong, nonatomic) IBOutlet UIImageView *inputImageView;

@property (nonatomic, strong) FJFaceRecognizer *faceModel;
@end

@implementation FJFaceRecognitionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _inputImageView.image = _inputImage;
    
    NSURL *modelURL = [self faceModelFileURL];
    self.faceModel = [FJFaceRecognizer faceRecognizerWithFile:[modelURL path]];
    
    double confidence;
    
    if (_faceModel.labels.count == 0) {
        [_faceModel updateWithFace:_inputImage name:@"Person 1"];
    }

    NSString *name = [_faceModel predict:_inputImage confidence:&confidence];
    
    _nameLabel.text = name;
    _confidenceLabel.text = [@(confidence) stringValue];
    
    
}

-(void)texttospeech{
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSString *messageBody= [NSString stringWithFormat:@"Hello osh"];
    
    
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


- (NSURL *)faceModelFileURL {
    NSArray *paths = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
    NSURL *documentsURL = [paths lastObject];
    NSURL *modelURL = [documentsURL URLByAppendingPathComponent:@"face-model.xml"];
    return modelURL;
}


- (IBAction)didTapCorrect:(id)sender {
    //Positive feedback for the correct prediction
    [self texttospeech];
    [_faceModel updateWithFace:_inputImage name:_nameLabel.text];
    [_faceModel serializeFaceRecognizerParamatersToFile:[[self faceModelFileURL] path]];
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    
}

- (IBAction)didTapWrong:(id)sender {
    //Update our face model with the new person
    NSString *name = [@"Person " stringByAppendingFormat:@"%lu", (unsigned long)_faceModel.labels.count];
    [_faceModel updateWithFace:_inputImage name:name];
    [_faceModel serializeFaceRecognizerParamatersToFile:[[self faceModelFileURL] path]];
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

@end
