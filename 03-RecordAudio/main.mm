//
//  main.m
//  03-RecordAudio
//
//  Created by wzp on 2021/4/6.
//

#import <Cocoa/Cocoa.h>

extern "C" {
#import <libavdevice/avdevice.h>
}

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        // Setup code that might create autoreleased objects goes here.
    }
    avdevice_register_all();
    return NSApplicationMain(argc, argv);
}
