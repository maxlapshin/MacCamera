//
//  X264Encoder.h
//  MacCamera
//
//  Created by sK0T on 01.12.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#include <x264.h>

@interface X264Encoder : NSObject
{
	x264_param_t	parameters_;
	x264_t			*encoder_;

	x264_picture_t	picture_;
	x264_picture_t	*pic_;

	int64_t			frameNo_;
	unsigned		width_;
	unsigned		height_;
	int				level_;

	BOOL			externalFrame_;
	uint8_t			*savedPlane_[4];
	int				savedStride_[4];

	NSMutableString	*errors_;
}

/** Устанавливает размер картинки заодно выделяя под неё память. */
- (void)setWidth:(unsigned)width height:(unsigned)height;

/** Кодирует установленную картинку выдавая raw 264 nal units в буфер */
- (void)encodeTo:(NSMutableData *)buffer;

/** Очищает буфер энкодера в конце кодирования сохраняя данные в буфер.
 Возвращает NO когда не сохранённых данных больше не осталось. */
- (BOOL)flushedAllDelayedFramesTo:(NSMutableData *)buffer;

/** Копирует данные из AVFrame во внутренний кадр. */
- (void)consumeAVFrame:(void *)frame;

/** Устанавливает уровень (level_idc) */
- (void)setLevel:(int)level;
@end
