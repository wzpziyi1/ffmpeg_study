//
//  ZYAudioMgr.h
//  03-RecordAudio
//
//  Created by wzp on 2021/4/13.
//

#import <Foundation/Foundation.h>

@interface ZYAudioMgr : NSObject
+ (void)registerAllDevice;

#pragma mark - record audio
- (BOOL)isRecording;
- (void)startRecordWithFailBlock:(void(^)(void))failBlock;
- (void)stopRecord;

#pragma mark - player audio
- (void)sdlVersion;
@end
