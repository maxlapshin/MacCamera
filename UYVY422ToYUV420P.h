//
//  UYVY422ToYUV420P.h
//  MacCamera
//
//  Created by sK0T on 26.01.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#include <libswscale/swscale.h>


@interface UYVY422ToYUV420P : NSObject {
	struct SwsContext *converter_;
	uint8_t *picture_[3];
	int pictureStride_[3];
	uint64_t frameSize_;
}

@end
