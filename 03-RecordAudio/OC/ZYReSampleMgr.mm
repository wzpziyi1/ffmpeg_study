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
    
    //输入文件的参数***************
    int inChannelLayout = inChannels == 1 ? AV_CH_LAYOUT_MONO : AV_CH_LAYOUT_STEREO;
    uint8_t **inData = nullptr;
    NSFileHandle *inHandle = [NSFileHandle fileHandleForReadingAtPath:inPath];
    //输入缓冲区样本个数
    int inSampleNum = 1024;
    //输入缓冲区大小
    int inLinesize = 0;
    //每个样本占的字节数
    int inBytesPreSample = inChannels * av_get_bytes_per_sample(inSampleFmt);
    
    
    //输出文件的参数***************
    int outChannelLayout = outChannels == 1 ? AV_CH_LAYOUT_MONO : AV_CH_LAYOUT_STEREO;
    uint8_t **outData = nullptr;
    NSFileHandle *outHandle = [NSFileHandle fileHandleForWritingAtPath:outPath];
    /*输出缓冲区样本个数
     
     这里需要根据输入缓冲区样本个数来计算：
     比如说将 44100 16位 双声道
     转化为
            48000 32位 单声道
     
     输入缓冲区样本个数为1024，那么输出缓冲区样本个数要大点，否则会丢失一些样本数：
     
     outSampleNum = outSampleRate / inSampleRate * inSampleNum
     向上取整
     */
    int outSampleNum = (int)av_rescale_rnd(outSampleRate, inSampleNum, inSampleRate, AV_ROUND_UP);
    //输出缓冲区大小
    int outLinesize = 0;
    //每个样本占的字节数
    int outBytesPreSample = outChannels * av_get_bytes_per_sample(outSampleFmt);
    
    
    NSData *readData = nil;
    NSData *writeData = nil;
    
    //创建采样上下文***************
    SwrContext *context = swr_alloc_set_opts(nil,
                                             outChannelLayout, outSampleFmt, outSampleRate,
                                             inChannelLayout, inSampleFmt, inSampleRate,
                                             0, nullptr);
    if (context == NULL) {
        NSLog(@"swr_alloc_set_opts error");
        goto End;
    }
    
    //初始化重采样上下文***************
    code = swr_init(context);
    if (code < 0) {
        ERROR_BUF(code, @"swr_init")
        goto End;
    }
    
    /*创建输入缓冲区
     
     问题来了，第一个参数是 uint8_t ***data
     为什么是三个*，查看ffmpeg源码可以发现，它是通过设置  data = malloc(sizeof(uint8_t **) * count1)
     然后 *data = malloc(sizeof(uint8_t) * count2)
     
     源码：
     uint_8 ***audio_data = &inData;
     
     开辟  sizeof(uint_8**) * nb_planes个内存空间
     *audio_data = av_calloc(nb_planes, sizeof(**audio_data));
     
     uint_8 **p = *audio;
     uint_8 *buf = av_malloc(size);
     buf[0] = buf
     
     总的来说，之所以传递&inData， 是为了里面改变indata 里面存储的地址，一开始indata == nullptr
     
     源码里面 *audio = av_calloc(nb_planes, sizeof(**audio_data));   相当于给 indata赋值了一块新的内存地址，在函数调用完也可生效
     
     然后 *audio 是指针数组，也就是 uint_8 ** 类型， 里面存储 uint_8 * 类型的指针
     */
    code = (int)av_samples_alloc_array_and_samples(&inData, &inLinesize, inChannelLayout, inSampleRate, inSampleFmt, 1);
    
    if (code < 0) {
        ERROR_BUF(code, @"input buffer av_samples_alloc_array_and_samples");
        goto End;
    }
    
    
    //创建输出缓冲区
    code = (int)av_samples_alloc_array_and_samples(&outData, &outLinesize, outChannelLayout, outSampleRate, outSampleFmt, 1);
    
    if (code < 0) {
        ERROR_BUF(code, @"output buffer av_samples_alloc_array_and_samples");
        goto End;
    }
    
    
    while (1) {
        readData = [inHandle readDataOfLength:inLinesize];
        if (readData.length == 0) {
            break;
        }
        //真正这次读取样本的数量
        inSampleNum = readData.length / inBytesPreSample;
        [readData getBytes:(void *)inData[0] length:readData.length];
        
        //转化数据，从输入缓冲区--》转化数据--》输出到输出缓冲区
        //code 返回的是样本数
        int ret = swr_convert(context, outData, outSampleNum, (const uint8_t **)inData, inSampleNum);
        if (ret < 0) {
            ERROR_BUF(code, @"swr_convert");
            goto End;
        }
        
        writeData = [NSData dataWithBytes:(void *)outData[0] length:ret * outBytesPreSample];
        [outHandle writeData:writeData];
    }
    
  //释放资源
End:
    [inHandle closeFile];
    [outHandle closeFile];
    swr_free(&context);
}
@end
