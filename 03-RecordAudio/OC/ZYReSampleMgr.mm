//
//  ZYReSampleMgr.m
//  03-RecordAudio
//
//  Created by wzp on 2021/4/30.
//

#import "ZYReSampleMgr.h"

extern "C"{
#import <libavutil/avutil.h>
#import <libswresample/swresample.h>
}

#define ERROR_BUF(code, func)\
    char errBuf[1025];\
    av_strerror(code, errBuf, sizeof(errBuf));\
    NSLog(@"%@ error: %s", func, errBuf);

@implementation ZYReSampleMgr
+ (void)resampleWithInPath:(NSString *)inPath
                  inSample:(int)inSampleRate
                inChannels:(int)inChannels
               inSampleFmt:(AVSampleFormat)inSampleFmt
                   outPath:(NSString *)outPath
                 outSample:(int)outSampleRate
               outChannels:(int)outChannels
              outSampleFmt:(AVSampleFormat)outSampleFmt
{
    //结果码
    int code = 0;
    //输入文件的参数
    int64_t inChannelLayout = inChannels == 1 ? AV_CH_LAYOUT_MONO : AV_CH_LAYOUT_STEREO;
    
    
    //输出文件的参数
    int64_t outChannelLayout = outChannels == 1 ? AV_CH_LAYOUT_MONO : AV_CH_LAYOUT_STEREO;
    
    //创建采样上下文
    SwrContext *context = swr_alloc_set_opts(nil,
                                             outChannelLayout, outSampleFmt, outSampleRate,
                                             inChannelLayout, inSampleFmt, inSampleRate,
                                             0, nullptr);
    if (context == NULL) {
        NSLog(@"swr_alloc_set_opts error");
        goto End;
    }
    
    //初始化重采样上下文
    code = swr_init(context);
    if (code < 0) {
        ERROR_BUF(code, @"swr_init")
        goto End;
    }
    
    //创建输入缓冲区
//    av_samples_alloc_array_and_samples(<#uint8_t ***audio_data#>, <#int *linesize#>, <#int nb_channels#>, <#int nb_samples#>, <#enum AVSampleFormat sample_fmt#>, <#int align#>)
    
  //释放资源
End:
    
    swr_free(&context);
}
@end
