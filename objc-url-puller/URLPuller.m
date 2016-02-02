//
//  URLPuller.m
//  objc-url-puller
//
//  Created by Jon on 1/30/16.
//  Copyright © 2016 Second Wind, LLC. All rights reserved.
//

#import "URLPuller.h"

@interface URLPuller() <NSURLSessionDownloadDelegate>
@property (nonatomic, assign) BOOL downloadsInProgress;
@property (nonatomic, strong) NSMutableArray *downloadedURLs;
@property (nonatomic, strong) NSMutableArray *downloadingURLs;
@property (nonatomic, strong) NSURLSession *session;
@end

@implementation URLPuller

/*
 keep track of URLs downloaded
 start a download for a url
 know when a download finishes
*/

-(instancetype)init {
    self = [super init];
    if (!self) return nil;
    
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    configuration.HTTPAdditionalHeaders = @{@"Accept": @"application/json"};
    configuration.requestCachePolicy = NSURLRequestReloadIgnoringCacheData;
    self.session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:nil];
    
    self.downloadedURLs = [[NSMutableArray alloc] init];
    self.downloadingURLs = [[NSMutableArray alloc] init];
    
    return self;
}

-(void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location
{
    NSURL *downloadedURL = downloadTask.currentRequest.URL;
    
    NSFileManager *defaultFileManager = [NSFileManager defaultManager];
  
    NSURL *destinationURL = [NSURL URLWithString:[self destinationPathForURL:downloadedURL]];
    [defaultFileManager moveItemAtURL:location toURL:destinationURL error:nil];
    
    NSLog(@"Moved file from %@ to %@", location, destinationURL);
    
    [self completeURLDownload:downloadedURL];
    
    if ([self.downloadingURLs count] == 0) {
        self.downloadsInProgress = NO;
    }
}

- (void)completeURLDownload:(NSURL *)downloadedURL
{
    for (NSURL *url in self.downloadingURLs) {
        if ([[downloadedURL absoluteString] isEqualToString:[url absoluteString]])
        {
            [self.downloadingURLs removeObject:url];
            [self.downloadedURLs addObject:downloadedURL];
        }
    }
}

//The urls array will contain an array of NSURL’s. The method should return immediately, eg, it’s an asynchronous API call that will run in the background.

//The downloaded files can be stored in any directory, where the filename is {sha1 hash of url}.downloaded -> We will just do a regular hash function instead for simplicity
- (void) downloadUrlsAsync: (NSArray*)urls
{
    for (NSURL *url in urls) {
        [self downloadUrl:url];
    }
}

//Block until all of the URLs have been downloaded.

//If this is called while there is no download in progress, it should return immediately. Otherwise, it should block until all the downloads have finished.
- (void) waitUntilAllDownloadsFinish
{
    
    if (!self.downloadsInProgress) {
        return;
    }
    
    while (self.downloadsInProgress) {
        [NSThread sleepForTimeInterval:1.0];
    }
    
    NSLog(@"Blocker finished");
}

//Return the path where the given url was downloaded to.

//If the given url has not been downloaded yet, or was never requested to be downloaded, then it should return nil.

- (NSString*) downloadedPathForURL: (NSURL*)url
{
    if (![self urlIsDownloading:url]) {
        return nil;
    }
    
    return [self destinationPathForURL:url];
}

- (BOOL) urlIsDownloading:(NSURL *)downloadingURL
{
    for (NSURL *url in self.downloadingURLs) {
        if ([[downloadingURL absoluteString] isEqualToString:[url absoluteString]])
        {
            return YES;
        }
    }
    return NO;
}

- (NSString *) destinationPathForURL:(NSURL *)url
{
    NSURL *destinationPath = [[NSBundle mainBundle] bundleURL];
    NSUInteger fileName = [url hash];
    NSURL *destinationURL = [destinationPath URLByAppendingPathComponent:[NSString stringWithFormat:@"%lu.downloaded", fileName]];
    return [destinationURL absoluteString];
}

- (void)downloadUrl:(NSURL *)url
{
    NSURLSessionDownloadTask *task = [self.session downloadTaskWithURL:url];
    
    [self.downloadingURLs addObject:url];
    self.downloadsInProgress = YES;
    [task resume];
}


- (BOOL)responseContainsSuccessfulStatusCode:(NSURLResponse *)response
{
    NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(200, 99)];
    NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
    NSLog(@"status code: %li",(long)statusCode);
    return [indexSet containsIndex:(NSUInteger)statusCode];
}

@end
