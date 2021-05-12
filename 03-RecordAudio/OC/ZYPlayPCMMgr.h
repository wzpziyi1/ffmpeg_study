//
//  ZYPlayPCMMgr.h
//  03-RecordAudio
//
//  Created by wzp on 2021/4/16.
//

#import <Foundation/Foundation.h>


@interface ZYPlayPCMMgr : NSObject
@property(atomic, assign, readonly) BOOL isPlaying;
- (void)sdlVersion;
- (void)playAudioWithCallback:(void(^)(void))callback;

- (void)stopPlayAudio;
@end
