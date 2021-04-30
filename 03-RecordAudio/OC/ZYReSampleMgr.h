//
//  ZYReSampleMgr.h
//  03-RecordAudio
//
//  Created by wzp on 2021/4/30.
//

#import <Foundation/Foundation.h>

extern "C" {
#import <libavformat/avformat.h>
}

@interface ZYReSampleMgr : NSObject
+ (void)resampleWithInPath:(NSString *)inPath
                  inSample:(int)inSampleRate
                inChannels:(int)inChannels
               inSampleFmt:(AVSampleFormat)inSampleFmt
                   outPath:(NSString *)outPath
                 outSample:(int)outSampleRate
               outChannels:(int)outChannels
              outSampleFmt:(AVSampleFormat)outSampleFmt;
@end
