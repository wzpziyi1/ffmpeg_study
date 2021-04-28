//
//  ZYAudioConverMgr.m
//  03-RecordAudio
//
//  Created by wzp on 2021/4/24.
//

#import "ZYAudioConverMgr.h"

extern "C" {
#import <libavcodec/avcodec.h>
#import <libavformat/avformat.h>
}

@implementation ZYAudioConverMgr
+ (void)pcmToWavWithPath:(nonnull NSString *)pcmPath
                 wavPath:(nonnull NSString *)wavPath
               wavHeader:(nonnull ZYWAVHeader *)wavHeader
                callback:(nonnull void(^)(BOOL isSuccess))callback
{
    wavHeader->blockAlign = av_get_bytes_per_sample((AVSampleFormat)wavHeader->audioFormat) * wavHeader->numChannels;
    wavHeader->bitsPreSample = wavHeader->blockAlign << 3;
    wavHeader->byteRate = wavHeader->sampleRate * wavHeader->blockAlign;
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    if ([fileMgr fileExistsAtPath:pcmPath]) {
        NSLog(@"%s pcm not exists", __func__);
        return;
    }
    
    if ([fileMgr fileExistsAtPath:wavPath]) {
        NSError *error = nil;
        [fileMgr removeItemAtPath:wavPath error:&error];
        if (error) {
            NSLog(@"%s remove file error: %@", __func__,error);
            callback(NO);
            return;
        }
    }
    
    [fileMgr createFileAtPath:wavPath contents:nil attributes:nil];
    
    NSFileHandle *pcmHandle = [NSFileHandle fileHandleForReadingAtPath:pcmPath];
    
    NSFileHandle *wavHandle = [NSFileHandle fileHandleForWritingAtPath:wavPath];
    
    NSDictionary *pcmAttrs = [fileMgr attributesOfItemAtPath:pcmPath error:nil];
    
    //设置riffChunkSize和dataChunkSize
    wavHeader->dataChunkSize = [pcmAttrs[NSFileSize] int32Value];
    //riffDataSize 不包括riffChunkId、riffChunkSize的字节数
    wavHeader->riffChunkSize = wavHeader->dataChunkSize + sizeof(ZYWAVHeader) - 8;
    
    //先将wav文件头写入文件
    NSData *headerData = [NSData dataWithBytes:(void *)wavHeader length:sizeof(ZYWAVHeader)];
    //写入wav头信息
    [wavHandle writeData:headerData];
    //头信息就是44个字节
    u_int32_t totalLen = 44;
    
    u_int32_t readLen = 1024;
    //开始读取pcm数据，写入wav里面
    NSData *pcmData;
    while ((pcmData = [pcmHandle readDataOfLength:readLen]) && pcmData.length) {
        totalLen += pcmData.length;
        [wavHandle writeData:pcmData];
    }
    [pcmHandle closeFile];
    [wavHandle closeFile];
}
@end
