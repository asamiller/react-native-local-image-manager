//
//  RCTLocalImageManager.m
//
//  Created by Asa Miller and Eric Hayes on 6/10/15.
//  Copyright (c) 2015 Asa Miller. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreGraphics/CoreGraphics.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "RCTBridgeModule.h"
#import "RCTUtils.h"

@implementation LocalImageManager


RCT_EXPORT_MODULE();

// Available as NativeModules.LocalImageManager.resize
RCT_EXPORT_METHOD(resize:(NSDictionary *)input callback:(RCTResponseSenderBlock)callback)
{
	NSURL *assetUrl = [[NSURL alloc] initWithString:input[@"uri"]];
	CGFloat width = [input[@"width"] floatValue];
	CGFloat height = [input[@"height"] floatValue];
	CGFloat quality = [input[@"quality"] floatValue];
	NSString *outputName = input[@"filename"];

	ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
	[library assetForURL:assetUrl
		resultBlock:^(ALAsset *asset) {
			// grab the image from the asset
			ALAssetRepresentation *rep = [asset defaultRepresentation];
			CGImageRef imageRef = [rep fullResolutionImage];
			
			// make a UIImage out of it, so we can draw it into our context
			UIImage *sourceImage = [UIImage imageWithCGImage:imageRef];
			CGRect rect = CGRectMake(0, 0, width, height);
			
			// make a new graphics context (think layer)
			UIGraphicsBeginImageContextWithOptions(rect.size, YES, 1.0f); {
				// draw our source image to size in the layer
				[sourceImage drawInRect:rect];
			}

			// grab the UIImage from the graphics context
			UIImage * resizedImage = UIGraphicsGetImageFromCurrentImageContext();
			
			// convert the image to DATA (and jpeg it to the requested quality)
			NSData *data = UIImageJPEGRepresentation(resizedImage, quality);
			
			// write it to disk
			NSString *path = [self getDestLocation:outputName];
			[data writeToFile:path atomically:YES];
		
			// return the location we specified
			callback(@[path]);
		
		}
		failureBlock:^(NSError *error) {
			callback(@[RCTMakeError(@"Error resizing image", nil, nil)]);
		}
	];
}

// Available as NativeModules.LocalImageManager.remove
RCT_EXPORT_METHOD(remove:(NSString *)pathFileToDelete callback:(RCTResponseSenderBlock)callback)
{
	[[NSFileManager defaultManager] removeItemAtPath:pathFileToDelete error:nil];
}

- (NSString *)getDestLocation:(NSString *)filename
{
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	
	return [documentsDirectory stringByAppendingPathComponent:filename];
}

// Available as NativeModules.LocalImageManager.download
RCT_EXPORT_METHOD(download:(NSDictionary *)input callback:(RCTResponseSenderBlock)callback)
{
	NSURL *assetUrl = [[NSURL alloc] initWithString:input[@"uri"]];
	NSString *outputName = input[@"filename"];
	
	NSData *data = [NSData dataWithContentsOfURL:assetUrl];
	if ( data == nil ) {
		callback(@[RCTMakeError(@"uri did not return any data", nil, nil)]);
	
	} else {
		NSString *path = [self getDestLocation:outputName];
		[data writeToFile:path atomically:YES];

		// return the location we specified
		callback(@[path]);
	}
}

- (NSString *)getDestLocation:(NSString *)filename
{
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	
	return [documentsDirectory stringByAppendingPathComponent:filename];
}

@end