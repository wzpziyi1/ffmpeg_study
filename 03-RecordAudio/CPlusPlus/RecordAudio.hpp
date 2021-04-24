//
//  RecordAudio.hpp
//  03-RecordAudio
//
//  Created by wzp on 2021/4/22.
//

#ifndef RecordAudio_hpp
#define RecordAudio_hpp

#include <iostream>
#include <thread>

class RecordAudio {
public:
    static void registerAllDevices();
    bool isRecording();
    void startRecordAudio(void *callback);
    void stopRecord();
private:
    std::atomic <bool> isStoped;
};

#endif /* RecordAudio_hpp */
