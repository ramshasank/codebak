//
//  Locations.m
//  TourMyTown
//
//  Created by Michael Katz on 8/15/13.
//  Copyright (c) 2013 mikekatz. All rights reserved.
//

#import "Locations.h"
#import "Location.h"

static NSString* const kBaseURL = @"http://localhost:3000/";
static NSString* const kLocations = @"locations";
static NSString* const kFiles = @"files";


@interface Locations ()
@property (nonatomic, strong) NSMutableArray* objects;
@end

@implementation Locations

- (id)init
{
    self = [super init];
    if (self) {
        _objects = [NSMutableArray array];
    }
    return self;
}

- (NSArray*) filteredLocations
{
    return [self objects];
}

- (void) addLocation:(Location*)location
{
    [self.objects addObject:location];
}

- (void)loadImage:(Location*)location
{
    NSURL* url = [NSURL URLWithString:[[kBaseURL stringByAppendingPathComponent:kFiles] stringByAppendingPathComponent:location.imageId]]; //1
    
    NSURLSessionConfiguration* config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession* session = [NSURLSession sessionWithConfiguration:config];
    
    NSURLSessionDownloadTask* task = [session downloadTaskWithURL:url completionHandler:^(NSURL *fileLocation, NSURLResponse *response, NSError *error) { //2
        if (!error) {
            NSData* imageData = [NSData dataWithContentsOfURL:fileLocation]; //3
            UIImage* image = [UIImage imageWithData:imageData];
            if (!image) {
                NSLog(@"unable to build image");
            }
            location.image = image;
            if (self.delegate) {
                [self.delegate modelUpdated];
            }
        }
    }];
    
    [task resume]; //4
}

- (void)import
{
    NSURL* url = [NSURL URLWithString:[kBaseURL stringByAppendingPathComponent:kLocations]]; //1
    
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"GET"; //2
    [request addValue:@"application/json" forHTTPHeaderField:@"Accept"]; //3
    
    NSURLSessionConfiguration* config = [NSURLSessionConfiguration defaultSessionConfiguration]; //4
    NSURLSession* session = [NSURLSession sessionWithConfiguration:config];
    
    NSURLSessionDataTask* dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) { //5
        if (error == nil) {
            NSArray* responseArray = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL]; //6
            [self parseAndAddLocations:responseArray toArray:self.objects]; //7
        }
    }];
    
    [dataTask resume]; //8
}

- (void)parseAndAddLocations:(NSArray*)locations toArray:(NSMutableArray*)destinationArray
{
    for (NSDictionary* item in locations) {
        Location* location = [[Location alloc] initWithDictionary:item];
        [destinationArray addObject:location];
        
        if (location.imageId) { //1
            [self loadImage:location];
        }
    }
    
    if (self.delegate) {
        [self.delegate modelUpdated];
    }
}

- (void) runQuery:(NSString *)queryString
{
    NSString* urlStr = [[kBaseURL stringByAppendingPathComponent:kLocations] stringByAppendingString:queryString]; //1
    NSURL* url = [NSURL URLWithString:urlStr];
    
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"GET";
    [request addValue:@"application/json" forHTTPHeaderField:@"Accept"];
    
    NSURLSessionConfiguration* config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession* session = [NSURLSession sessionWithConfiguration:config];
    
    NSURLSessionDataTask* dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error == nil) {
            [self.objects removeAllObjects]; //2
            NSArray* responseArray = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
            NSLog(@"received %lu items", (unsigned long)responseArray.count);
            [self parseAndAddLocations:responseArray toArray:self.objects];
        }
    }];
    [dataTask resume];
}

- (void) queryRegion:(MKCoordinateRegion)region //1
{
    //not assumes the NE hemisphere. This logic should really check first.
    //also note that searches across hemisphere lines are not interpreted properly by Mongo
    CLLocationDegrees x0 = region.center.longitude - region.span.longitudeDelta; //2
    CLLocationDegrees x1 = region.center.longitude + region.span.longitudeDelta;
    CLLocationDegrees y0 = region.center.latitude - region.span.latitudeDelta;
    CLLocationDegrees y1 = region.center.latitude + region.span.latitudeDelta;
    
    NSString* boxQuery = [NSString stringWithFormat:@"{\"$geoWithin\":{\"$box\":[[%f,%f],[%f,%f]]}}",x0,y0,x1,y1]; //3
    NSString* locationInBox = [NSString stringWithFormat:@"{\"location\":%@}", boxQuery]; //4
    NSString* escBox = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL,
                                                                                             (CFStringRef) locationInBox,
                                                                                             NULL,
                                                                                             (CFStringRef) @"!*();':@&=+$,/?%#[]{}",
                                                                                             kCFStringEncodingUTF8)); //5
    NSString* query = [NSString stringWithFormat:@"?query=%@", escBox]; //6
    [self runQuery:query]; //7
}

- (void) saveNewLocationImageFirst:(Location*)location
{
    NSURL* url = [NSURL URLWithString:[kBaseURL stringByAppendingPathComponent:kFiles]]; //1
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST"; //2
    [request addValue:@"image/png" forHTTPHeaderField:@"Content-Type"]; //3
    
    NSURLSessionConfiguration* config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession* session = [NSURLSession sessionWithConfiguration:config];
    
    NSData* bytes = UIImagePNGRepresentation(location.image); //4
    NSURLSessionUploadTask* task = [session uploadTaskWithRequest:request fromData:bytes completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) { //5
        if (error == nil && [(NSHTTPURLResponse*)response statusCode] < 300) {
            NSDictionary* responseDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
            location.imageId = responseDict[@"_id"]; //6
            [self persist:location]; //7
        }
    }];
    [task resume];
}


- (void) persist:(Location*)location
{
    if (!location || location.name == nil || location.name.length == 0) {
        return; //input safety check
    }
    
    //if there is an image, save it first
    if (location.image != nil && location.imageId == nil) { //1
        [self saveNewLocationImageFirst:location]; //2
        return;
    }
    
    
    NSString* locations = [kBaseURL stringByAppendingPathComponent:kLocations];
    
    BOOL isExistingLocation = location._id != nil;
    NSURL* url = isExistingLocation ? [NSURL URLWithString:[locations stringByAppendingPathComponent:location._id]] :
    [NSURL URLWithString:locations]; //1
    
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = isExistingLocation ? @"PUT" : @"POST"; //2
    
    NSData* data = [NSJSONSerialization dataWithJSONObject:[location toDictionary] options:0 error:NULL]; //3
    request.HTTPBody = data;
    
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"]; //4
    
    NSURLSessionConfiguration* config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession* session = [NSURLSession sessionWithConfiguration:config];
    
    NSURLSessionDataTask* dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) { //5
        if (!error) {
            NSArray* responseArray = @[[NSJSONSerialization JSONObjectWithData:data options:0 error:NULL]];
            [self parseAndAddLocations:responseArray toArray:self.objects];
        }
    }];
    [dataTask resume];
}
@end
