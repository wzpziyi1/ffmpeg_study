//
//  main.m
//  03-RecordAudio
//
//  Created by wzp on 2021/4/6.
//

#import <Cocoa/Cocoa.h>
#import "ZYRecordAudioMgr.h"
extern "C" {
#import <libavdevice/avdevice.h>
}

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        // Setup code that might create autoreleased objects goes here.
    }
    [ZYRecordAudioMgr registerAllDevice];
    return NSApplicationMain(argc, argv);
}
