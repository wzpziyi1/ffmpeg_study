//
//  RecordAudio.cpp
//  03-RecordAudio
//
//  Created by wzp on 2021/4/22.
//

#include "RecordAudio.hpp"

extern "C" {
#include <libavdevice/avdevice.h>
#include <libavutil/avutil.h>
#include <libavformat/avformat.h>
}

static void registerAllDevices()
{
    avdevice_register_all();
}

bool RecordAudio::isRecording()
{
    return !this->isStoped;
}
void RecordAudio::startRecordAudio(void *callback)
{
    
}
void RecordAudio::stopRecord()
{
    this->isStoped = true;
}
