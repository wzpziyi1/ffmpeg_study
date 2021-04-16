//
//  ZYPlayAudioMgr.m
//  03-RecordAudio
//
//  Created by wzp on 2021/4/16.
//

#import "ZYPlayAudioMgr.h"

extern "C" {
#import <SDL2/SDL.h>
}

#define kAudioPath @"/Users/wzp/Downloads/xxxxx.pcm"

#define kSampleRate 44100
#define kChannelCount 2

//音频缓冲区数量，必须是2的幂次方
#define kSampleBufferCount 1024

//一个缓冲区样本大小：位深度 * 声道数 / 8  个字节
#define kSingleSampleBufferBytes (16 * kChannelCount) / 8

//缓冲区样本总大小，字节数
#define kTotalSampleBufferBytes (kSingleSampleBufferBytes * kSampleBufferCount)

typedef struct {
    int len;
    int pullLen;
    UInt8 *data = nullptr;
}AudioBuffer;

static UInt8 readData[kTotalSampleBufferBytes];
static int readLen = 0;

@implementation ZYPlayAudioMgr

- (void)sdlVersion
{
    SDL_version v;
    SDL_VERSION(&v);
    NSLog(@"sdlVersion：%d.%d.%d", v.major, v.minor, v.patch);
}

/// SDL 拉取音频数据的回调函数
/// @param userdata SDL_AudioSpec.userdata
/// @param stream 音频缓冲区，需要将音频数据填充到这个缓冲区
/// @param len 音频缓冲区的大小（SDL_AudioSpec.samples * 每个样本的大小）
void pullAudioCallback(void *userdata, Uint8 * stream, int len)
{
    SDL_memset(stream, 0, len);
    
    //取出
}

- (void)playAudio
{
    
    //初始化音频子系统，返回值不为0就是失败
    if (SDL_Init(SDL_INIT_AUDIO) != 0) {
        NSLog(@"SDL_Init error: %s", SDL_GetError());
        return;
    }
    
    SDL_AudioSpec spec;
    //采样率
    spec.freq = kSampleRate;
    //采样fromat，包含（位深度）、大小端
    spec.format = AUDIO_S16LSB;
    //声道数
    spec.channels = kChannelCount;
    //音频缓冲区数量(最多缓存个数)，必须是2的幂次方
    spec.samples = kSampleBufferCount;
    
    //pull音频数据时的回调函数
    spec.callback = pullAudioCallback;
    
    //传递回调的参数
    AudioBuffer buffer;
    spec.userdata = &buffer;
    
    //打开音频设备
    if (SDL_OpenAudio(&spec, nullptr) != 0) {
        NSLog(@"SDL_OpenAudio error: %s", SDL_GetError());
        //要与init对应
        SDL_Quit();
        return;
    }
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager isReadableFileAtPath:kAudioPath]) {
        NSLog(@"playAudio: read file error");
        SDL_Quit();
        return;
    }
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:kAudioPath];
    
    while (true) {
        NSData *data = [fileHandle readDataOfLength:kTotalSampleBufferBytes];
        //读取到文件末尾了
        if (data == nil || data.length == 0) {
            break;
        }
        readLen = (int)data.length;
        [data getBytes:readData length:readLen];
        [fileHandle seekToFileOffset:readLen];
        while (readLen > 0) {
            SDL_Delay(1);
        }
    }
     
}
@end
