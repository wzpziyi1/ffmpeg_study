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

#define kSampleRate 48000
#define kChannelCount 2

#define kSampleFormat AUDIO_F32LSB
//位深度
#define kSampleSize (kSampleFormat & 0xFF)

//音频缓冲区数量，必须是2的幂次方
#define kSampleBufferCount 1024

//一个缓冲区样本大小：位深度 * 声道数 / 8  个字节
#define kSingleSampleBufferBytes ((kSampleSize * kChannelCount) >> 3)

//缓冲区样本总大小，字节数
#define kTotalSampleBufferBytes (kSingleSampleBufferBytes * kSampleBufferCount)

typedef struct {
    int len = 0;
    int pullLen = 0;
    Uint8 *data = nullptr;
}AudioBuffer;

@interface ZYPlayAudioMgr()
@property(atomic, assign, readwrite) BOOL isPlaying;
@end

@implementation ZYPlayAudioMgr

- (instancetype)init
{
    if (self = [super init]) {
        self.isPlaying = NO;
    }
    return self;
}

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
    AudioBuffer *buffer = (AudioBuffer *)userdata;
    
    if (buffer->len == 0) return;
    
    buffer->pullLen = buffer->len < len ? buffer->len : len;
    
    SDL_MixAudio(stream, buffer->data, buffer->pullLen, SDL_MIX_MAXVOLUME);
    
    //一段buffer->data填充进去缓冲区了，得换下一段了
    buffer->data += buffer->pullLen;
    buffer->len -= buffer->pullLen;
}

- (void)playAudioWithCallback:(void(^)(void))callback
{
    void (^block)(void) = ^{
        self.isPlaying = NO;
        if (callback) {
            dispatch_async(dispatch_get_main_queue(), ^{
                callback();
            });
        }
    };
    NSThread *thread = [[NSThread alloc] initWithBlock:^{
        self.isPlaying = YES;
        //初始化音频子系统，返回值不为0就是失败
        if (SDL_Init(SDL_INIT_AUDIO) != 0) {
            NSLog(@"SDL_Init error: %s", SDL_GetError());
            block();
            return;
        }
        
        SDL_AudioSpec spec;
        //采样率
        spec.freq = kSampleRate;
        //采样fromat，包含（位深度）、大小端
        spec.format = kSampleFormat;
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
            block();
            return;
        }
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if (![fileManager isReadableFileAtPath:kAudioPath]) {
            NSLog(@"playAudio: read file error");
            SDL_Quit();
            block();
            return;
        }
        NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:kAudioPath];
        
        static Uint8 readData[kTotalSampleBufferBytes];
        
        SDL_PauseAudio(0);
        int offset = 0;
        while (self.isPlaying) {
            if (buffer.len > 0) {
                SDL_Delay(1);
                continue;
            };
            NSData *pcmData = [fileHandle readDataOfLength:kTotalSampleBufferBytes];
            
            //读取到文件末尾了
            //这里有问题，当音频缓冲区读完数据的时候，还没开始播放，就break了
            //会导致最后读取的这部分音频数据不能播放
            //所以，这里要推测还剩下多长播放时间，delay下，再退出
            if (pcmData == nil || pcmData.length == 0) {
                //还剩下多长播放时间：剩余样本数 / 每秒采样率
                
                //剩余样本数量
                int samples = buffer.pullLen / kSingleSampleBufferBytes;
                
                //转换成毫秒
                int ms = samples * 1000 / spec.freq;
                SDL_Delay(ms);
                break;
            }
            buffer.len = (int)pcmData.length;
            [pcmData getBytes:readData length:buffer.len];
            buffer.data = readData;
            offset += buffer.len;
            [fileHandle seekToFileOffset:offset];
        }
        
        [fileHandle closeFile];
        //关闭音频
        SDL_CloseAudio();
        //退出音频子系统
        SDL_Quit();
        block();
    }];
    [thread start];
}

- (void)stopPlayAudio
{
    self.isPlaying = NO;
}
@end
