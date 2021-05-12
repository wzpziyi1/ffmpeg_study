//
//  ZYPlayWavMgr.m
//  03-RecordAudio
//
//  Created by wzp on 2021/5/12.
//

#import "ZYPlayWavMgr.h"

extern "C" {
#include <SDL2/SDL.h>
}

typedef struct {
    UInt8 *data = nullptr;
    UInt32 len = 0;
    UInt32 pullLen = 0;
}AudioBuffer;

@interface ZYPlayWavMgr()
@property(atomic, assign, readwrite) BOOL isPlaying;
@end

@implementation ZYPlayWavMgr

void pull_audio_callback(void *userdata, Uint8 * stream,
                                            int len)
{
    //先清空缓冲区
    SDL_memset(stream, 0, len);
    AudioBuffer *buffer = (AudioBuffer *)userdata;
    
    //数据还没准备好
    if (buffer->len == 0) {
        return;
    }
    buffer->pullLen = buffer->len < len ? buffer->len : len;
    
    //填充数据
    SDL_MixAudio(stream, (const UInt8 *)buffer->data, buffer->pullLen, SDL_MIX_MAXVOLUME);
    buffer->data += buffer->pullLen;
    buffer->len -= buffer->pullLen;
    
}

- (void)playAudioWithFilePath:(NSString *)filePath
                       Callback:(void(^)(void))callback;
{
    void (^block)(void) = ^{
        self.isPlaying = NO;
        if (callback) {
            dispatch_async(dispatch_get_main_queue(), ^{
                callback();
            });
        }
    };
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        self.isPlaying = YES;
        int code = SDL_Init(SDL_INIT_AUDIO);
        
        if (code != 0) {
            NSLog(@"SDL_Init error: %s", SDL_GetError());
            block();
            return;
        }
        
        SDL_AudioSpec spec;
        AudioBuffer buffer;
        //参数：wav 的spec  一次性读取到的wav data   wav data的长度
        if (!SDL_LoadWAV([filePath cStringUsingEncoding:NSUTF8StringEncoding], &spec, &buffer.data, &buffer.len)) {
            NSLog(@"SDL_LoadWAV error: %s", SDL_GetError());
            block();
            SDL_Quit();
            return;
        }
        
        //要在SDL_LoadWAV后面设置spec参数，不然会被SDL_LoadWAV设置时覆盖掉
        spec.callback = pull_audio_callback;
        spec.userdata = &buffer;
        UInt8 *data = buffer.data;
        if (SDL_OpenAudio(&spec, nullptr) != 0) {
            NSLog(@"SDL_OpenAudio error: %s", SDL_GetError());
            block();
            SDL_FreeWAV(buffer.data);
            SDL_Quit();
            return;
        }
        
        SDL_PauseAudio(0);
        
        while (1)
        {
            if (buffer.len >0) {
                continue;
            }
            //一个样本字节数
            UInt32 bytePerSample = SDL_AUDIO_BITSIZE(spec.format) * spec.channels >> 3;
            //最后一个pulldata 读取的样本数
            UInt32 numSamples = buffer.pullLen / bytePerSample + 1;
            //最后一次播放还需要的时间
            UInt32 ms = 1000.0 * numSamples / spec.freq;
            SDL_Delay(ms);
            break;
        }
        
        SDL_FreeWAV(data);
        SDL_CloseAudio();
        SDL_Quit();
    });
}

- (void)stopPlayAudio
{
    self.isPlaying = NO;
}
@end
