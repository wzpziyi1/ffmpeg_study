//
//  ViewController.m
//  03-RecordAudio
//
//  Created by wzp on 2021/4/6.
//

#import "ViewController.h"
#import "ZYRecordAudioMgr.h"

@interface ViewController()
@property (nonatomic, strong) ZYRecordAudioMgr *recordAudio;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
//    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles"]];

    // Do any additional setup after loading the view.
    
    self.recordAudio = [[ZYRecordAudioMgr alloc] init];
}

- (IBAction)clickRecordAudioBtn:(NSButton *)sender {
    if ([self.recordAudio isRecording]) {
        [sender setTitle:@"开始录音"];
        [self.recordAudio stopRecord];
    }
    else {
        [sender setTitle:@"停止录音"];
        [self.recordAudio startRecordWithFailBlock:^{
            [sender setTitle:@"开始录音"];
        }];
    }
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}




@end
