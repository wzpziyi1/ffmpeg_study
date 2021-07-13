//
//  ZYAACEncodeMgr.m
//  03-RecordAudio
//
//  Created by wzp on 2021/7/7.
//

#import "ZYAACEncodeMgr.h"

extern "C"{
#import <fdk-aac/aacenc_lib.h>
}
#define ERROR_BUF(code, func)\
    char errBuf[1025];\
    av_strerror(code, errBuf, sizeof(errBuf));\
    NSLog(@"%@ error: %s", func, errBuf);

@implementation ZYAACEncodeMgr

//查询fdk-aac支持的采样格式
static bool check_sample_format(AVCodec *codec, AVSampleFormat fmt)
{
    const enum AVSampleFormat *fmt_p = codec->sample_fmts;
    while (*fmt_p != AV_SAMPLE_FMT_NONE) {
        if (*fmt_p == fmt) return true;
        fmt_p++;
    }
    return false;
}

// 音频编码
// 返回负数：中途出现了错误
// 返回0：编码操作正常完成
static int encode(AVCodecContext *context, AVFrame *frame, AVPacket *packet, NSFileHandle *outHandle)
{
    //发送数据到编码器
    int ret = avcodec_send_frame(context, frame);
    if (ret < 0) {
        ERROR_BUF(ret, @"avcodec_send_frame");
        return ret;
    }
    
    //不断的从编码器读取编码后的数据
    while (true) {
        ret = avcodec_receive_packet(context, packet);
        //临时文件错误、读取到文件末尾了
        if (ret == AVERROR(EAGAIN) || ret == AVERROR_EOF) {
            //继续读取frame中的pcm数据
            return 0;
        }
        else if (ret < 0) {
            return ret;
        }
        
        //将编码后的aac数据写入文件
        NSData *data = [NSData dataWithBytes:(void *)packet->data length:packet->size];
        [outHandle writeData:data];
        
        //释放packet内部资源
        av_packet_unref(packet);
    }
}

+ (void)aacEncode:(AudioEncodeSpec &)inSpec outFilePath:(NSString *)outFilePath
{
    NSFileHandle *inHandle = [NSFileHandle fileHandleForReadingAtPath:inSpec.filePath];
    NSFileHandle *outHandle = [NSFileHandle fileHandleForWritingAtPath:outFilePath];
    
    //返回结果
    int ret = 0;
    
    //编码器
    AVCodec *codec = nullptr;
    
    //编码上下文
    AVCodecContext *context = nullptr;
    
    //存放编码前的数据（pcm数据）
    AVFrame *frame = nullptr;
    
    //存放编码后数据(aac数据)
    AVPacket *packet = nullptr;
    
    //获取编码器
    codec = avcodec_find_encoder_by_name("libfdk-aac");
    if (!codec) {
        NSLog(@"avcodec not find");
        return;
    }
    
    //fdk-aac编码音频采样格式必须是：16位整数
    if (!check_sample_format(codec, inSpec.format)) {
        NSLog(@"unsupport format: %s", av_get_sample_fmt_name(inSpec.format));
        return;
    }
    
    //创建编码上下文
    context = avcodec_alloc_context3(codec);
    if (!context) {
        NSLog(@"avcodec_alloc_context3 error");
        return;
    }
    
    //设置pcm参数
    context->sample_rate = inSpec.sampleRate;
    context->sample_fmt = inSpec.format;
    context->channel_layout = inSpec.channelLayout;
    
    //比特率
    context->bit_rate = 32000;
    //规格
    context->profile = FF_PROFILE_AAC_HE_V2;
    
    //打开编码器，可以设置AVDictionary参数
    //    AVDictionary *options = nullptr;
    //    av_dict_set(&options, "vbr", "5", 0);
    //    ret = avcodec_open2(ctx, codec, &options);
    ret = avcodec_open2(context, codec, nullptr);
    if (ret < 0) {
        ERROR_BUF(ret, @"avcodec_open2");
        goto End;
    }
    
    // 创建AVFrame
    frame = av_frame_alloc();
    if (!frame) {
        NSLog(@"av_frame_alloc error");
        goto End;
    }
    //frame缓冲区中的样本帧数量（由context->frame_size决定）
    frame->nb_samples = context->frame_size;
    frame->format = context->sample_fmt;
    frame->channel_layout = context->channel_layout;
    // 利用nb_samples、format、channel_layout创建缓冲区
    ret = av_frame_get_buffer(frame, 0);
    if (ret < 0) {
        ERROR_BUF(ret, @"av_frame_get_buffer");
        goto End;
    }
    
    packet = av_packet_alloc();
    if (!packet) {
        NSLog(@"av_frame_get_buffer error");
        goto End;
    }
    
    if (!inHandle) {
        NSLog(@"read file error");
        goto End;
    }
    
    if (!outHandle) {
        NSLog(@"write file error");
        goto End;
    }
    
    //读取pcm数据到AVFrame里面--》送到编码器--》编码为AVPacket数据--》写入文件
    while (1)
    {
        NSData *pcmData = [inHandle readDataOfLength:frame->linesize[0]];
        frame->data[0] = (uint8 *)[pcmData bytes];
        //存在一个问题，从文件中读取的数据并不足以填充完缓冲区
        if (pcmData.length < frame->linesize[0]) {
            //那就要重新计算frame里面采样的样本数了
            int bytes = av_get_bytes_per_sample((AVSampleFormat)frame->format);
            int ch = av_get_channel_layout_nb_channels(frame->channel_layout);
            
            // 设置真正有效的样本帧数量
            // 防止编码器编码了一些冗余数据
            frame->nb_samples = pcmData.length / (ch * bytes);
        }
        
        ret = encode(context, frame, packet, outHandle);
        if (ret < 0) {
            goto End;
        }
    }
    
    //while结束的时候，还存在一些数据再缓冲区里面编码，需要输出
    //刷新缓冲区
    encode(context, nullptr, nullptr, outHandle);
    
End:
    [inHandle closeFile];
    [outHandle closeFile];
    
    //释放资源
    av_frame_free(&frame);
    av_packet_free(&packet);
    avcodec_free_context(&context);
    NSLog(@"aac 编码正常结束！");
}

@end
