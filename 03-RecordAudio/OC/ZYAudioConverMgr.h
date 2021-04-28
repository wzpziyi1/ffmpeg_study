//
//  ZYAudioConverMgr.h
//  03-RecordAudio
//
//  Created by wzp on 2021/4/24.
//

#import <Foundation/Foundation.h>
typedef NS_ENUM(NSInteger, AudioFormatType) {
    AudioFormatPCM = 1,
    AudioFormatFloat = 3
};
typedef struct {
    u_int8_t riffChunkId[4] = {'R', 'I', 'F', 'F'};
    u_int32_t riffChunkSize;
    u_int8_t fmt[4] = {'W', 'A', 'V', ' '};
    u_int8_t fmtChunkId[4] = {'f', 'm', 't', ' '};
    //fmt chunk的data大小：存储PCM数据时，是16
    u_int32_t fmtChunkSize = 16;
    //音频编码，1表示PCM，3表示Floating Point；AVSampleFormat里面
    u_int16_t audioFormat = 1;
    u_int16_t numChannels;
    u_int32_t sampleRate;
    u_int32_t byteRate;
    //一个样本占多少字节，考虑单双声道
    u_int16_t blockAlign;
    //位深度
    u_int16_t bitsPreSample;
    u_int8_t dataChunkId[4] = {'d', 'a', 't', 'a'};
    //data chunk的data大小：音频数据的总长度，即文件总长度减去文件头的长度(一般是44)
    u_int32_t dataChunkSize;
}ZYWAVHeader;


@interface ZYAudioConverMgr : NSObject
+ (void)pcmToWavWithPath:(nonnull NSString *)pcmPath
                 wavPath:(nonnull NSString *)wavPath
               wavHeader:(nonnull ZYWAVHeader *)wavHeader
                callback:(nonnull void(^)(BOOL isSuccess))callback;
@end
