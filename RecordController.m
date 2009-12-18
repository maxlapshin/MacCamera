//
//  RecordController.m
//  MacCamera
//
//  Created by sK0T on 01.12.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "RecordController.h"


@implementation RecordController

- (NSArray *)cameras
{
	NSMutableArray *ret = [NSMutableArray array];
	[ret addObjectsFromArray:[QTCaptureDevice inputDevicesWithMediaType:QTMediaTypeVideo]];
	[ret addObjectsFromArray:[QTCaptureDevice inputDevicesWithMediaType:QTMediaTypeMuxed]];
	return ret;
}

- (void)awakeFromNib
{
	videoEncoder_ = [[X264Encoder alloc] init];
	if (!fileOutput_)
		fileOutput_ = [[NSFileHandle fileHandleForWritingAtPath:@"/private/tmp/out.264"] retain];
	if (!frameOutput_)
		frameOutput_ = [[NSMutableData data] retain];

	[camerasList_ removeAllItems];
	for (id<NSObject> o in [self cameras])
		[camerasList_ addItemWithTitle:[o description]];
	captureSession_ = [[QTCaptureSession alloc] init];
	[self cameraSelected:[camerasList_ selectedItem]];
}

- (IBAction)startRecording:(id)sender
{
	videoOutput_ = [[QTCaptureDecompressedVideoOutput alloc] init];
	[videoOutput_ setDelegate:self];
	NSError *error;
	BOOL success = [captureSession_ addOutput:videoOutput_ error:&error];
	if (!success) {
		[[NSAlert alertWithError:error] runModal];
		return;
	}
	[videoEncoder_ setWidth:1280 height:1024];
	[videoEncoder_ start];
	framesCountDown_ = 25;
	secondsCount_ = 0;
	[captureSession_ startRunning];
}

- (void)captureOutput:(QTCaptureOutput *)captureOutput
  didOutputVideoFrame:(CVImageBufferRef)videoFrame
	 withSampleBuffer:(QTSampleBuffer *)sampleBuffer
	   fromConnection:(QTCaptureConnection *)connection
{
	
	[videoEncoder_ consumeCVImage:videoFrame];
	[videoEncoder_ encodeTo:frameOutput_];
	framesCountDown_ -= 1;
	if (framesCountDown_ == 0) {
		framesCountDown_ = 25;
		while (![videoEncoder_ flushedAllDelayedFramesTo:frameOutput_]);
		[frameOutput_ writeToFile:[NSString stringWithFormat:@"/private/tmp/test%05d.h264", secondsCount_] atomically:NO];
		secondsCount_ += 1;
		[frameOutput_ release];
		frameOutput_ = [[NSMutableData data] retain];
		[videoEncoder_ stop];
		[videoEncoder_ start];
	}
}

- (IBAction)stopRecording:(id)sender
{
}

- (IBAction)cameraSelected:(id)sender
{
	if (!sender)
		return;

	QTCaptureDevice *device;
	for (device in [self cameras]) {
		if ([[sender title] isEqualTo:[device description]])
			break;
	}
	NSError *err;
	if (![device open:&err]) {
		NSLog(@"Could not open device: %@", err);
		return;
	}
	if (captureDeviceInput_)
		[captureSession_ removeInput:captureDeviceInput_];
	[captureDeviceInput_ release];
	captureDeviceInput_ = [[QTCaptureDeviceInput alloc] initWithDevice:device];
	if (![captureSession_ addInput:captureDeviceInput_ error:&err]) {
		NSLog(@"Failed to add input %@", err);
		return;
	}
	[captureView_ setCaptureSession:captureSession_];
	[captureSession_ startRunning];
}

- (void)windowWillClose:(NSNotification *)notification
{
	[captureSession_ stopRunning];
	[[captureDeviceInput_ device] close];
}

@end
