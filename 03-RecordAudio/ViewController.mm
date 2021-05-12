//
//  ViewController.m
//  03-RecordAudio
//
//  Created by wzp on 2021/4/6.
//

#import "ViewController.h"
#import "ZYRecordAudioMgr.h"
#import "ZYPlayPCMMgr.h"
#import "ZYAudioConverMgr.h"

@interface ViewController()
@property (nonatomic, strong) ZYRecordAudioMgr *recordMgr;
@property (nonatomic, strong) ZYPlayPCMMgr *playMgr;
@property (nonatomic, strong) ZYAudioConverMgr *converMgr;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
//    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles"]];

    // Do any additional setup after loading the view.
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willClose:) name:NSWindowWillCloseNotification object:nil];
    
    self.recordMgr = [[ZYRecordAudioMgr alloc] init];
    self.playMgr = [[ZYPlayPCMMgr alloc] init];
    self.converMgr = [[ZYAudioConverMgr alloc] init];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (IBAction)clickRecordAudioBtn:(NSButton *)sender
{
    if ([self.recordMgr isRecording]) {
        [sender setTitle:@"开始录音"];
        [self.recordMgr stopRecord];
    }
    else {
        [sender setTitle:@"停止录音"];
        [self.recordMgr startPCMRecordWithFailBlock:^{
            [sender setTitle:@"开始录音"];
        }];
    }
}
- (IBAction)clickPlayAudioBth:(id)sender
{
    if ([self.playMgr isPlaying]) {
        [sender setTitle:@"开始播放"];
        [self.playMgr stopPlayAudio];
    }
    else {
        [sender setTitle:@"停止播放"];
        [self.playMgr playAudioWithCallback:^{
            [sender setTitle:@"开始播放"];
        }];
    }
}

- (IBAction)clickPcmConverWavBtn:(id)sender {
    ZYWAVHeader wavHeader;
//    wavHeader.audioFormat = 
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}


- (void)willClose:(NSNotification *)notification
{

    NSLog(@"窗口关闭");
    [self.recordMgr stopRecord];
    [self.playMgr stopPlayAudio];
    [NSThread sleepForTimeInterval:0.25];
    [[NSApplication sharedApplication] terminate:nil];
    //退出程序
//    exit(0);
}
@end
