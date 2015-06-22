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


#define kImageCacheFolder		@"image_cache"

@interface LocalImageManager : NSObject <RCTBridgeModule>
- (void)resize:(NSDictionary *)input callback:(RCTResponseSenderBlock)callback;
- (void)remove:(NSString *)pathFileToDelete callback:(RCTResponseSenderBlock)callback;
- (void)download:(NSDictionary *)input callback:(RCTResponseSenderBlock)callback;

- (void)downloadCached:(NSString *)pathFileToCache callback:(RCTResponseSenderBlock)callback;
- (void)removeCached:(NSString *)pathFileToDelete callback:(RCTResponseSenderBlock)callback;
- (void)clearCache:(NSString *)unused callback:(RCTResponseSenderBlock)callback;

@end

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
			 UIImage *sourceImage = [UIImage imageWithCGImage:imageRef scale:1.0f orientation:[rep orientation]];
			 
			 CGRect rect = CGRectMake(0, 0, width, height);
			 // make a new graphics context (think layer)
			 UIGraphicsBeginImageContextWithOptions(rect.size, YES, 1.0f);
			 // draw our source image to size in the layer
			 [sourceImage drawInRect:rect];
			 UIImage * resizedImage = UIGraphicsGetImageFromCurrentImageContext();
			 UIGraphicsEndImageContext();
			 
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


// Available as NativeModules.LocalImageManager.download
RCT_EXPORT_METHOD(download:(NSDictionary *)input callback:(RCTResponseSenderBlock)callback)
{
	NSURL *assetUrl = [NSURL URLWithString:input[@"uri"]];
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


#pragma mark - Cached calls


// Available as NativeModules.LocalImageManager.downloadCached
RCT_EXPORT_METHOD(downloadCached:(NSString *)pathFileToCache callback:(RCTResponseSenderBlock)callback)
{
	NSString *path = pathFileToCache;
	if ( path.length <= 0 ) {
		callback(@[RCTMakeError(@"invalid uri", nil, nil)]);
	}
	
	// we will be returning this path
	NSString *fullPath = [self getFullPathForFilePath:path];
	
	// first, see if we have it
	if ( [self imageExists:path] ) {
		[self touchCachedImage:path];
		callback(@[fullPath]);
		return;
	}
	
	// nope, gotta download it
	
	NSURL *assetUrl = [NSURL URLWithString:path];
	NSData *data = [NSData dataWithContentsOfURL:assetUrl];
	if ( data == nil ) {
		callback(@[RCTMakeError(@"uri did not return any data", nil, nil)]);
		
	} else {
		[self storeImageData:data forPath:path];
		
		// return the location we specified
		callback(@[path]);
	}
}

// Available as NativeModules.LocalImageManager.removeCached
RCT_EXPORT_METHOD(removeCached:(NSString *)pathFileToDelete callback:(RCTResponseSenderBlock)callback)
{
	[self clearImage:pathFileToDelete];
}

// Available as NativeModules.LocalImageManager.clearCache
RCT_EXPORT_METHOD(clearCache:(NSString *)unused callback:(RCTResponseSenderBlock)callback)
{
	[self clearImageCache];
}


#pragma mark - Internal Cached Image Manager


// fetch the desired Image version from afar (then cache it)
- (BOOL)imageExists:(NSString *)path;
{
	NSString *fullPath = [self getFullPathForFilePath:path];
	
	BOOL isDir;
	return [[NSFileManager defaultManager] fileExistsAtPath:fullPath isDirectory:&isDir];
}

// fetch the desired Image version from afar (then cache it)
- (void)storeImageData:(NSData *)imageData forPath:(NSString *)path;
{
	NSString *fullPath = [self getFullPathForFilePath:path];
	
	[imageData writeToFile:fullPath atomically:YES];
}

- (NSData *)loadImageData:(NSString *)path;
{
	NSString *fullPath = [self getFullPathForFilePath:path];
	
	NSData *data = [NSData dataWithContentsOfFile:fullPath];
	if ( data ) {
		[self touchCachedImage:path];
	}
	return data;
}

// load from cache, the requested Image version, nil if not present
- (UIImage *)loadImage:(NSString *)path;
{
	if ( path.length == 0 ) return nil;
	
	NSData *data = [self loadImageData:path];
	if ( data ) {
		[self touchCachedImage:path];
		return [UIImage imageWithData:data];
	} else {
		return nil;
	}
}

- (void)storeImage:(UIImage *)image forPath:(NSString *)path;
{
	NSData *data = UIImageJPEGRepresentation(image, 1.0);
	
	[self storeImageData:data forPath:path];
}

- (void)touchCachedImage:(NSString *)path;
{
	NSString *fullPath = [self getFullPathForFilePath:path];
	
	NSDictionary *attribs = @{NSFileModificationDate:[NSDate date]};
	NSError *err;
	[[NSFileManager defaultManager] setAttributes:attribs ofItemAtPath:fullPath error:&err];
}

// clear, from cache, the desired Image version
- (void)clearImage:(NSString *)path;
{
	NSString *fullPath = [self getFullPathForFilePath:path];
	
	[[NSFileManager defaultManager] removeItemAtPath:fullPath error:nil];
}

// clear the cache
- (void)clearImageCache;
{
	[[NSFileManager defaultManager] removeItemAtPath:[self getCacheFolderPath] error:nil];
}



#pragma mark - Internal Helpers

- (NSString *)getFullPathForFilePath:(NSString *)filePath
{
	NSString *cachePath = [self getCacheFolderPath];
	NSString *filename = [filePath stringByReplacingOccurrencesOfString:@"/" withString:@"~"];
	filename = [filename stringByReplacingOccurrencesOfString:@":" withString:@"~"];
	NSString *fullPath = [cachePath stringByAppendingPathComponent:filename];
	
	return fullPath;
}

- (NSString *)getCacheFolderPath
{
	NSArray *cachedirs = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
	NSString *cachedir = cachedirs[0];
	
	NSString *cachePath = [cachedir stringByAppendingPathComponent:kImageCacheFolder];
	
	//make sure it exists
	[[NSFileManager defaultManager] createDirectoryAtPath:cachePath withIntermediateDirectories:YES attributes:nil error:nil];
	
	return cachePath;
}

- (NSString *)getDestLocation:(NSString *)filename
{
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	
	return [documentsDirectory stringByAppendingPathComponent:filename];
}

@end