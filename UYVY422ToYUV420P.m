//
//  UYVY422ToYUV420P.m
//  MacCamera
//
//  Created by sK0T on 26.01.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "UYVY422ToYUV420P.h"
#import <QTKit/QTKit.h>


@implementation UYVY422ToYUV420P
- (id)init
{
//	int width, height;
	if ((self = [super init])) {
//		TODO initWithFrame:
//		converter_ = sws_getContext(width, height, PIX_FMT_UYVY422,
//									width, height, PIX_FMT_YUV420P,
//									2, NULL, NULL, NULL);
//		if (!converter_) {
//			[self release];
//			return nil;
//		}
	}

	return self;
}

- (void)setCVImage:(CVImageBufferRef)image
{
	OSType fmt = CVPixelBufferGetPixelFormatType(image); // unsigned long
	if (fmt != kComponentVideoUnsigned) { // "yuvs"
		char buf[5] = {0, 0, 0, 0, 0};
		memcpy(buf, &fmt, 4);
		NSLog(@"Pixel format '%s' is unsupported by %@", buf, self);
		return;
	}

	if (CVPixelBufferIsPlanar(image)) {
		NSLog(@"Planar images are not supported by %@", self);
		return;
	}

	CVPixelBufferLockBaseAddress(image, 0); {
		uint8_t *buffer = CVPixelBufferGetBaseAddress(image);
		size_t bpr = CVPixelBufferGetBytesPerRow(image);
		size_t width = CVPixelBufferGetWidth(image);
		size_t height = CVPixelBufferGetHeight(image);

		if (frameSize_ != bpr * height) {
			frameSize_ = bpr * height;
			int i;
			for (i = 0; i < 3; i++) {
				if (picture_[i])
					free(picture_[i]);

				if (i == 0) {
					picture_[i] = malloc(frameSize_);
					pictureStride_[i] = width;
				} else {
					picture_[i] = malloc(frameSize_/2);
					pictureStride_[i] = width / 2;
				}
			}
		}

		converter_ = sws_getCachedContext(converter_,
									width, height, PIX_FMT_UYVY422,
									width, height, PIX_FMT_YUV420P,
									2, NULL, NULL, NULL);

        uint8_t *src[3] = {(uint8_t *)buffer, NULL, NULL};
        int srcStride[3] = {bpr, 0, 0};
		pictureStride_[0] = width;
		pictureStride_[1] = width / 2.0;
		pictureStride_[2] = width / 2.0;
        sws_scale(converter_, src, srcStride, 0, height, picture_, pictureStride_);
	} CVPixelBufferUnlockBaseAddress(image, 0);
}

- (void)dealloc
{
	sws_freeContext(converter_);
	[super dealloc];
}

@end
