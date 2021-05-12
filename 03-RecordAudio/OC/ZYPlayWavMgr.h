//
//  ZYPlayWavMgr.h
//  03-RecordAudio
//
//  Created by wzp on 2021/5/12.
//

#import <Foundation/Foundation.h>


@interface ZYPlayWavMgr : NSObject
@property(atomic, assign, readonly) BOOL isPlaying;

- (void)playAudioWithFilePath:(NSString *)filePath
                       Callback:(void(^)(void))callback;

- (void)stopPlayAudio;
@end

