//
//  ZYAACEncodeMgr.h
//  03-RecordAudio
//
//  Created by wzp on 2021/7/7.
//

#import <Foundation/Foundation.h>

extern "C" {
#import <libavformat/avformat.h>
}

typedef struct{
    NSString *filePath;
    AVSampleFormat format;
    uint32_t sampleRate;
    int channelLayout;
}AudioEncodeSpec;

@interface ZYAACEncodeMgr : NSObject
+ (void)aacEncode:(AudioEncodeSpec &)inSpec outFilePath:(NSString *)outFilePath;
@end

