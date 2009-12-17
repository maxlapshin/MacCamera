//
//  X264Encoder.h
//  MacCamera
//
//  Created by sK0T on 01.12.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "X264Encoder.h"

@implementation X264Encoder

extern int x264_encoder_delayed_frames(x264_t *);

- (id)init
{
	if ((self = [super init])) {
		x264_param_default(&parameters_);
		errors_ = [[NSMutableString string] retain];
	}
	return self;
}

- (void)setWidth:(unsigned)width height:(unsigned)height
{
	if (pic_)
		x264_picture_clean(pic_);

	pic_ = &picture_;
	if (x264_picture_alloc(pic_, X264_CSP_I420, width, height) < 0) {
		[errors_ appendFormat:@"Failed to allocate %fx%f picture\n",
		 width, height];
		pic_ = NULL;
	}
	width_ = width;
	height_ = height;
}

- (BOOL)isStarted
{
	return !(NULL == encoder_);
}

- (BOOL)validateForStart:(NSError **)error
{
	return YES;
}

- (void)setLevel:(int)level
{
	level_ = level;
}

- (void)setupParams
{
//	"cabac=yes",
	parameters_.b_cabac = 1;
//	"bframes=0",
	parameters_.i_bframe = 0;
//	"keyint=125",  -I, --keyint <integer>      Maximum GOP size [250]
	parameters_.i_keyint_max = 125;
//	"ref=5",   -r, --ref <integer>         Number of reference frames [3]
	parameters_.i_frame_reference = 5;
//	"mixed-refs=yes",
	parameters_.analyse.b_mixed_references = 1;
//	"direct=auto", #define X264_DIRECT_PRED_AUTO   3
	parameters_.analyse.i_direct_mv_pred = X264_DIRECT_PRED_AUTO;
//	"me=umh", #define X264_ME_UMH                  2
	parameters_.analyse.i_me_method = X264_ME_UMH;
//	"merange=24",
	parameters_.analyse.i_me_range = 24;
//	"subme=7",
	parameters_.analyse.i_subpel_refine = 7;
//	"trellis=2",
	parameters_.analyse.i_trellis = 2;
//	"weightb=yes",
	parameters_.analyse.b_weighted_bipred = 1;
//	"partitions=all",
	parameters_.analyse.inter = ~0;
//	"non-deterministic=yes",
	parameters_.b_deterministic = 1;
//	"vbv-maxrate=512",
	parameters_.rc.i_vbv_max_bitrate = 512;
//	"vbv-bufsize=9000",
	parameters_.rc.i_vbv_buffer_size = 9000;
//	"ratetol=1000.0",
	parameters_.rc.f_rate_tolerance = 1000.0;
//	"scenecut=60"
	parameters_.i_scenecut_threshold = 60;
// from x264.c profile selection
	parameters_.analyse.b_transform_8x8 = 0;
	parameters_.i_cqm_preset = X264_CQM_FLAT;

}

- (void)start
{
	parameters_.i_width = width_;
	parameters_.i_height = height_;
	parameters_.i_sps_id = 1; // TODO надо бы настраиваемым штоле сделать?

	[self setupParams];

	if (level_) {
		NSLog(@"Setting level to %d", level_);
		parameters_.i_level_idc = level_;
	}

	encoder_ = x264_encoder_open(&parameters_);
}

- (void)stop
{
	x264_encoder_close(encoder_);
	encoder_ = NULL;
}

- (void)consumeAVFrame:(void *)frame
{
	struct avframe { uint8_t *data[4]; int linesize[4]; };
	struct avframe *f = (struct avframe *)frame;

	int i;
	for (i = 0; i < 4; i++) {
		if (!externalFrame_) {
			savedPlane_[i] = picture_.img.plane[i];
			savedStride_[i] = picture_.img.i_stride[i];
		}
		picture_.img.plane[i] = f->data[i];
		picture_.img.i_stride[i] = f->linesize[i];
	}
	externalFrame_ = YES;
}

- (void)dealloc
{
	if (encoder_)
		x264_encoder_close(encoder_);
	if (pic_) {
		if (externalFrame_) {
			int i;
			for (i = 0; i < 4; i++) {
				picture_.img.plane[i] = savedPlane_[i];
				picture_.img.i_stride[i] = savedStride_[i];
			}
		}
		x264_picture_clean(pic_);
	}
	[errors_ release];
	[super dealloc];
}

- (void)encodeTo:(NSMutableData *)buffer
{
	x264_picture_t	output;
	x264_nal_t		*nals;
	int				nalsCount, i;

	picture_.i_pts = (int64_t)frameNo_ * parameters_.i_fps_den;
	picture_.i_type = X264_TYPE_AUTO;
	picture_.i_qpplus1 = 0;

	if (x264_encoder_encode(encoder_, &nals, &nalsCount, pic_, &output) < 0) {
		NSLog(@"x264_encoder_encode failed");
        return;
    }

	for (i = 0; i < nalsCount; i++)
		[buffer appendBytes:nals[i].p_payload length:nals[i].i_payload];

	frameNo_++;
}

- (BOOL)flushedAllDelayedFramesTo:(NSMutableData *)buffer
{
	if (!encoder_)
		return YES;

	if (!x264_encoder_delayed_frames(encoder_))
		return YES;

	x264_picture_t	output;
	x264_nal_t		*nals;
	int				nalsCount, i;

	if (x264_encoder_encode(encoder_, &nals, &nalsCount, NULL, &output) < 0) {
		NSLog(@"x264_encoder_encode failed");
        return YES;
    }

	for (i = 0; i < nalsCount; i++)
		[buffer appendBytes:nals[i].p_payload length:nals[i].i_payload];

	return NO;
}

@end
