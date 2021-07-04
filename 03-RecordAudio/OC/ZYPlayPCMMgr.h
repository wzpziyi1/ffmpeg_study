//
//  ZYPlayPCMMgr.h
//  03-RecordAudio
//
//  Created by wzp on 2021/4/13.
//

#import <Foundation/Foundation.h>

@interface ZYPlayPCMMgr : NSObject
+ (void)registerAllDevice;

#pragma mark - record audio
- (BOOL)isRecording;

/// pcm录音
/// @param failBlock callback
- (void)startPCMRecordWithFailBlock:(void(^)(void))failBlock;


/// wav录音
/// @param failBlock callback
- (void)startWACRecordWithFailBlock:(void(^)(void))failBlock;
- (void)stopRecord;

@end
