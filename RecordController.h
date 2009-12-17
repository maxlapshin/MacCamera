//
//  RecordController.h
//  MacCamera
//
//  Created by sK0T on 01.12.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QTKit/QTKit.h>

@interface RecordController : NSObject {
	IBOutlet QTCaptureView	*captureView_;
	IBOutlet NSPopUpButton	*camerasList_;
	QTCaptureSession		*captureSession_;
	QTCaptureDeviceInput	*captureDeviceInput_;
	QTCaptureDecompressedVideoOutput	*videoOutput_;
}

- (IBAction)startRecording:(id)sender;
- (IBAction)stopRecording:(id)sender;
- (IBAction)cameraSelected:(id)sender;
@end
