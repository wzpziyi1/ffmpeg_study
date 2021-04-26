//
//  ZYRecordAudioMgr.m
//  03-RecordAudio
//
//  Created by wzp on 2021/4/13.
//

#import "ZYRecordAudioMgr.h"

extern "C" {
#import <libavdevice/avdevice.h>
#import <libavutil/avutil.h>
#import <libavformat/avformat.h>
#import <SDL2/SDL.h>
}

#ifdef TARGET_OS_MAC
    #define kFrameworkName "AVFoundation"
    #define kDeviceName ":0"
#elif
    #define kFrameworkName "dshow"
    #define kDeviceName ":0"
#endif

#define kAudioPath @"/Users/wzp/Downloads/xxxxx.pcm"


@interface ZYRecordAudioMgr()
@property (nonatomic, strong) dispatch_queue_t serial_queue;


@property (atomic, assign) BOOL isStop;
@end

@implementation ZYRecordAudioMgr
+ (void)registerAllDevice
{
    avdevice_register_all();
}

- (instancetype)init
{
    if (self = [super init]) {
        self.serial_queue = dispatch_queue_create("recordAudio.queue", DISPATCH_QUEUE_SERIAL);
        self.isStop = YES;
    }
    return self;
}

- (void)startRecordWithFailBlock:(void(^)(void))failBlock
{
    
    void(^tmpBlock)(void) = ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            if (failBlock) {
                failBlock();
            }
            [self stopRecord];
        });
    };
    self.isStop = NO;
    dispatch_async(self.serial_queue, ^{
        // 1、获取、打开 输入设备
        AVFormatContext *context = nullptr;
        AVInputFormat *format = av_find_input_format(kFrameworkName);
        int code = avformat_open_input(&context, kDeviceName, format, nil);
        
        if (code != 0) {
            char errorBuf[1024];
            av_strerror(code, errorBuf, sizeof(errorBuf));
            NSLog(@"open avformat error, code: %d, errorInfo:%s", code, errorBuf);
            tmpBlock();
            return;
        }
        
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *basePath = @"/Users/wzp/Downloads/";
        
//        NSTimeInterval interval = [[NSDate date] timeIntervalSince1970];
//        NSString *path = [NSString stringWithFormat:@"%@%lld%@", basePath, (long long)interval, @".pcm"];
        
        NSString *path = kAudioPath;
        if ([fileManager fileExistsAtPath:path]) {
            NSError *error = nil;
            [fileManager removeItemAtPath:path error:&error];
            if (error) {
                NSLog(@"remove file error: %@", error);
                avformat_close_input(&context);
                tmpBlock();
                return;
            }
        }
        
        [fileManager createFileAtPath:path contents:nil attributes:nil];
        if (![fileManager isWritableFileAtPath:path]) {
            NSLog(@"write file error");
            avformat_close_input(&context);
            return;
        }
        
        NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:path];
        AVPacket pkt;
        while (!self.isStop) {
            //读取pkt
            code = av_read_frame(context, &pkt);
            if (code == 0) {
                NSData *data = [NSData dataWithBytes:pkt.data length:pkt.size];
                [fileHandle writeData:data];
            }
            else {
                char errorBuf[1024];
                av_strerror(code, errorBuf, sizeof(errorBuf));
                NSLog(@"read audio error, code: %d, errorInfo:%s", code, errorBuf);
            }
        }
        [fileHandle closeFile];
        
        
        [self printContextLog:context];
        avformat_close_input(&context);
    });
}

- (void)printContextLog:(AVFormatContext *)context
{
    //streams are created by libavformat in avformat_open_input().
    //使用avformat_open_input创建一个streams
    AVStream *stream = context->streams[0];
    AVCodecParameters *codeParams = stream->codecpar;
    //采样率
    NSLog(@"采样率：%d", codeParams->sample_rate);
    //声道数
    NSLog(@"声道数：%d", codeParams->channels);
    //采样格式
    AVSampleFormat format = (AVSampleFormat)codeParams->format;
    NSLog(@"采样格式：%d", format);
    //编码格式，可以看出采样格式,注意，是16进制数
    NSLog(@"采样格式：0x%lx  0x%lx", codeParams->codec_id, AV_CODEC_ID_PCM_F32LE);
    
    //每个sample一个声道所占字节数,Return codec bits per sample.
    NSLog(@"每个sample所占位数：%d", av_get_bits_per_sample(codeParams->codec_id));
    
    //每一个样本的一个声道占用多少个字节
    NSLog(@"每个sample所占字节数：%d", av_get_bytes_per_sample((AVSampleFormat)codeParams->format));
}

- (void)stopRecord
{
    self.isStop = YES;
}

- (BOOL)isRecording
{
    return !self.isStop;
}

@end
