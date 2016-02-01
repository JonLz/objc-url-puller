//
//  URLPuller.h
//  objc-url-puller
//
//  Created by Jon on 1/30/16.
//  Copyright © 2016 Second Wind, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface URLPuller : NSObject
- (void) downloadUrlsAsync: (NSArray*)urls;
- (void) waitUntilAllDownloadsFinish;
- (NSString*) downloadedPathForURL: (NSURL*)url;
@end
