//
//  ViewController.m
//  LLYAudioDemo
//
//  Created by lly on 2017/9/4.
//  Copyright © 2017年 lly. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "UIImage+OCColorImage.h"
#import <MediaPlayer/MediaPlayer.h>
#import "LLYMusicModel.h"


@interface ViewController ()

@property (nonatomic,strong) AVPlayer *player;
@property (nonatomic,strong) NSMutableArray *playerItemArray;
@property (nonatomic,strong) NSMutableArray *urlArray;
@property (nonatomic,assign) NSInteger curPlayIndex;

@property (weak, nonatomic) IBOutlet UIImageView *albumImageView;

@property (weak, nonatomic) IBOutlet UILabel *musicInfoLabel;

@property (weak, nonatomic) IBOutlet UISlider *playSlider;
@property (weak, nonatomic) IBOutlet UIButton *playBtn;
@property (weak, nonatomic) IBOutlet UIButton *nextBtn;
@property (weak, nonatomic) IBOutlet UIButton *preBtn;

@property (nonatomic,assign) BOOL playing;
@property (nonatomic,assign,getter=isSeeking) BOOL seeking;

@property (nonatomic,strong) id mTimeObserver;


@property (nonatomic,strong) LLYMusicModel *musicModel;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.curPlayIndex = 0;
    self.playing = YES;

    [self initUI];
    
    [self.player play];
    [self addNotification];
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)initUI{

    [self customPlaySlider];
    [self.playBtn setImage:[UIImage imageNamed:@"pause"] forState:UIControlStateNormal];
}



- (void)viewWillAppear:(BOOL)animated{

    [super viewWillAppear:animated];
    
    //开始接受远程控制
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    [self becomeFirstResponder];
}


- (void)viewWillDisappear:(BOOL)animated{

    [super viewWillDisappear:animated];
    
    //解除远程控制
    [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
    [self resignFirstResponder];
}

// 重写父类成为响应者方法
- (BOOL)canBecomeFirstResponder {
    return YES;
}



//重写父类方法，接受外部事件的处理
- (void) remoteControlReceivedWithEvent: (UIEvent *) receivedEvent {
    if (receivedEvent.type == UIEventTypeRemoteControl) {
        
        switch (receivedEvent.subtype) { // 得到事件类型
                
            case UIEventSubtypeRemoteControlPreviousTrack:  // 上一首
                [self preBtnClicked:self.preBtn];
                break;
                
            case UIEventSubtypeRemoteControlNextTrack: // 下一首
                [self nextBtnClicked:self.nextBtn];
                break;
                
            case UIEventSubtypeRemoteControlPlay: //播放
            case UIEventSubtypeRemoteControlTogglePlayPause:
            case UIEventSubtypeRemoteControlPause:
                
                [self playBtnClicked:self.playBtn];

                break;
                
            default:
                break;
        }
    }
}


#pragma mark - get && set
- (void)setPlaying:(BOOL)playing{
    
    if (playing) {
        [self.playBtn setImage:[UIImage imageNamed:@"pause"] forState:UIControlStateNormal];
    }
    else{
        [self.playBtn setImage:[UIImage imageNamed:@"play"] forState:UIControlStateNormal];
    }
    
    _playing = playing;
}



#pragma mark - lazy load

- (AVPlayer *)player{

    if (!_player) {
        AVPlayerItem *nextItem = self.playerItemArray[self.curPlayIndex];
        _player = [AVPlayer playerWithPlayerItem:nextItem];
        [self addObserverToPlayerItem:nextItem];
    }
    
    return _player;
}


- (NSMutableArray *)playerItemArray{

    if (!_playerItemArray) {
        _playerItemArray  = [NSMutableArray array];
        
        for (int i = 0; i < 8; i++) {
            NSURL *musicUrl = [[NSBundle mainBundle] bundleURL];
            musicUrl = [musicUrl URLByAppendingPathComponent:[NSString stringWithFormat:@"%d.mp3",i]];
            [self.urlArray addObject:musicUrl];
            AVPlayerItem *playItem = [AVPlayerItem playerItemWithURL:musicUrl];
            [_playerItemArray addObject:playItem];
        }
    }
    
    return _playerItemArray;
}

- (NSMutableArray *)urlArray{

    if (!_urlArray) {
        _urlArray = [NSMutableArray array];
    }
    return _urlArray;
}

- (LLYMusicModel *)musicModel{

    if (!_musicModel) {
        _musicModel = [[LLYMusicModel alloc]init];
    }
    return _musicModel;
}

//播放进度条
- (void)customPlaySlider{
    
    {
        _playSlider.minimumValue = 0;
        _playSlider.maximumValue = 1;
        
        UIImage *pointImage = [UIImage imageNamed:@"thumb"];
        [_playSlider setThumbImage:pointImage forState:UIControlStateNormal];
        [_playSlider setThumbImage:pointImage forState:UIControlStateHighlighted];
        
        [_playSlider setMinimumTrackImage:[UIImage imageWithColor:[UIColor colorWithRed:0.78 green:0.15 blue:0.15 alpha:1.00]] forState:UIControlStateNormal];
        [_playSlider setMaximumTrackImage:[UIImage imageWithColor:[UIColor greenColor]] forState:UIControlStateNormal];
        
        _playSlider.value = 0;
        _playSlider.continuous = NO;
        [_playSlider addTarget:self action:@selector(onSeek:) forControlEvents:UIControlEventValueChanged | UIControlEventTouchDragExit | UIControlEventTouchUpInside | UIControlEventTouchUpOutside | UIControlEventTouchCancel];
        [_playSlider addTarget:self action:@selector(onSeekBegin:) forControlEvents:(UIControlEventTouchDown)];
        [_playSlider addTarget:self action:@selector(onDrag:) forControlEvents:UIControlEventTouchDragInside];
    }
}

#pragma mark - 通知
/**
 *  添加播放器通知
 */
-(void)addNotification{
    //给AVPlayerItem添加播放完成通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackFinished:) name:AVPlayerItemDidPlayToEndTimeNotification object:self.player.currentItem];
}

-(void)removeNotification{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

/**
 *  播放完成通知
 *
 *  @param notification 通知对象
 */
-(void)playbackFinished:(NSNotification *)notification{
    NSLog(@"视频播放完成.");
    if (self.playerItemArray.count > self.curPlayIndex+1) {
        self.curPlayIndex++;
        AVPlayerItem *nextItem = self.playerItemArray[self.curPlayIndex];
        [self p_play:nextItem];
    }
}

#pragma mark - kvo

/**
 *  给AVPlayerItem添加监控
 *
 *  @param playerItem AVPlayerItem对象
 */
-(void)addObserverToPlayerItem:(AVPlayerItem *)playerItem{
    //监控状态属性，注意AVPlayer也有一个status属性，通过监控它的status也可以获得播放状态
    [playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    //监控网络加载情况属性
    [playerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
    //监控是否开始播放
    [playerItem addObserver:self forKeyPath:@"rate" options:NSKeyValueObservingOptionNew context:nil];

}
-(void)removeObserverFromPlayerItem:(AVPlayerItem *)playerItem{
    [playerItem removeObserver:self forKeyPath:@"status"];
    [playerItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
    [playerItem removeObserver:self forKeyPath:@"rate"];
}

/**
 *  通过KVO监控播放器状态
 *
 *  @param keyPath 监控属性
 *  @param object  监视器
 *  @param change  状态改变
 *  @param context 上下文
 */
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    AVPlayerItem *playerItem=object;
    
    if ([keyPath isEqualToString:@"status"]) {
        AVPlayerStatus status= [[change objectForKey:@"new"] intValue];
        if(status==AVPlayerStatusReadyToPlay){
            NSLog(@"正在播放...，总长度:%.2f",CMTimeGetSeconds(playerItem.duration));
            
            [self p_updateMusicInfoLabel];
            
            self.playing = YES;
            
            [self p_addPlayerTimeObserver];
            
            [self p_setupLockScreenInfo];
        }
    }else if([keyPath isEqualToString:@"loadedTimeRanges"]){
        NSArray *array=playerItem.loadedTimeRanges;
        CMTimeRange timeRange = [array.firstObject CMTimeRangeValue];//本次缓冲时间范围
        float startSeconds = CMTimeGetSeconds(timeRange.start);
        float durationSeconds = CMTimeGetSeconds(timeRange.duration);
        NSTimeInterval totalBuffer = startSeconds + durationSeconds;//缓冲总长度
        NSLog(@"共缓冲：%.2f",totalBuffer);
        //
    }
    else if ([keyPath isEqualToString:@"rate"]){
        
        NSLog(@"开始播放！！！！%@",change);

    }
}

#pragma mark - ui action
- (IBAction)playBtnClicked:(id)sender {
    
    if (self.playing) {
        self.playing = NO;
        
        [self.player pause];
    }
    else{
        self.playing = YES;
        
        [self.player play];
    }
    
}
- (IBAction)nextBtnClicked:(id)sender {
    
    if (self.playerItemArray.count > self.curPlayIndex+1) {
        //添加下一曲的数据
        self.curPlayIndex++;
        AVPlayerItem *nextItem = self.playerItemArray[self.curPlayIndex];
        [self p_play:nextItem];
    }
    
}
- (IBAction)preBtnClicked:(id)sender {
    
    if (self.curPlayIndex > 0 && self.playerItemArray.count > 1) {
        self.curPlayIndex--;
        AVPlayerItem *nextItem = self.playerItemArray[self.curPlayIndex];
        [self p_play:nextItem];
    }
    
}

- (void)onSeek:(UISlider *)slider{
    
    if (!self.isSeeking) {
        self.seeking = YES;
        
        CMTime playerDuration = [self p_playerItemDuration];
        if (CMTIME_IS_INVALID(playerDuration)) {
            return;
        }
        
        double duration = CMTimeGetSeconds(playerDuration);
        if (isfinite(duration))
        {
            float minValue = [slider minimumValue];
            float maxValue = [slider maximumValue];
            float value = [slider value];
            
            double time = duration * (value - minValue) / (maxValue - minValue);
            __weak typeof(self) weakSelf = self;
            [self.player seekToTime:CMTimeMakeWithSeconds(time, NSEC_PER_SEC) completionHandler:^(BOOL finished) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    weakSelf.seeking = NO;
                    [weakSelf p_addPlayerTimeObserver];
                });
            }];
        }
    }
}
- (void)onSeekBegin:(UISlider *)slider{
    
    [self p_removePlayerTimeObserver];
}
- (void)onDrag:(UISlider *)slider{
    
    float progress = slider.value;
    
    NSLog(@"滑动到%f",progress);
    
}


#pragma mark - private method


- (void)getMusicInfo{

    AVURLAsset *mp3Asset = [AVURLAsset URLAssetWithURL:self.urlArray[self.curPlayIndex] options:nil];
    // 遍历有效元数据格式
    for (NSString *format in [mp3Asset availableMetadataFormats]) {
        
        // 根据数据格式获取AVMetadataItem（数据成员）；
        // 根据AVMetadataItem属性commonKey能够获取专辑信息；
        for (AVMetadataItem *metadataItem in [mp3Asset metadataForFormat:format]) {
            // NSLog(@"%@", metadataItem);
            
            // 1、获取艺术家（歌手）名字commonKey：AVMetadataCommonKeyArtist
            if ([metadataItem.commonKey isEqual:AVMetadataCommonKeyArtist]) {
                NSLog(@"艺术家 = %@", (NSString *)metadataItem.value);
                self.musicModel.artistName = (NSString *)metadataItem.value;
            }
            // 2、获取音乐名字commonKey：AVMetadataCommonKeyTitle
            else if ([metadataItem.commonKey isEqual:AVMetadataCommonKeyTitle]) {
                NSLog(@"音乐名字 = %@", (NSString *)metadataItem.value);
                self.musicModel.musicTitle = (NSString *)metadataItem.value;
            }
            // 3、获取专辑图片commonKey：AVMetadataCommonKeyArtwork
            else if ([metadataItem.commonKey isEqual:AVMetadataCommonKeyArtwork]) {
                //                NSLog(@"%@", (NSData *)metadataItem.value);
                self.musicModel.albumImage = [UIImage imageWithData:(NSData *)metadataItem.value];
                self.albumImageView.image = self.musicModel.albumImage;
            }
            // 4、获取专辑名commonKey：AVMetadataCommonKeyAlbumName
            else if ([metadataItem.commonKey isEqual:AVMetadataCommonKeyAlbumName]) {
                NSLog(@"专辑名 = %@", (NSString *)metadataItem.value);
                self.musicModel.albumName = (NSString *)metadataItem.value;
            }
        }
    }
    
    CMTime playerDuration = [self p_playerItemDuration];
    if (CMTIME_IS_INVALID(playerDuration)) {
        return;
    }
    double duration = CMTimeGetSeconds(playerDuration);
    self.musicModel.duration = duration;
}

- (void)p_updateMusicInfoLabel{

    [self getMusicInfo];
    
    self.musicInfoLabel.text = [NSString stringWithFormat:@"%@\n%@\n%@\n",self.musicModel.artistName,self.musicModel.musicTitle,self.musicModel.albumName];

}

-(void)p_play:(AVPlayerItem *)playItem{
    //清除之前播放的数据
    [self removeNotification];
    [self removeObserverFromPlayerItem:self.player.currentItem];
    [self p_removePlayerTimeObserver];
    
    [self.player replaceCurrentItemWithPlayerItem:playItem];
    [self.player play];
    
//    self.playSlider.value = 0.0;
//    [self.player seekToTime:kCMTimeZero];
    
    [self addNotification];
    [self addObserverToPlayerItem:playItem];
    
}

- (void)p_syncSlider{

    CMTime playerDuration = [self p_playerItemDuration];
    if (CMTIME_IS_INVALID(playerDuration))
    {
        self.playSlider.minimumValue = 0.0;
        return;
    }
    
    double duration = CMTimeGetSeconds(playerDuration);
    if (isfinite(duration))
    {
        float minValue = [self.playSlider minimumValue];
        float maxValue = [self.playSlider maximumValue];
        double time = CMTimeGetSeconds([self.player currentTime]);
        
        [self.playSlider setValue:(maxValue - minValue) * time / duration + minValue];
        
        NSLog(@"当前已经播放%.2fs.",self.playSlider.value);

    }

}

- (CMTime)p_playerItemDuration
{
    AVPlayerItem *playerItem = [self.player currentItem];
    if (playerItem.status == AVPlayerItemStatusReadyToPlay)
    {
        return([playerItem duration]);
    }
    
    return(kCMTimeInvalid);
}

- (void)p_addPlayerTimeObserver{
    
    
    CMTime playerDuration = [self p_playerItemDuration];
    if (CMTIME_IS_INVALID(playerDuration))
    {
        return;
    }
    
    double duration = CMTimeGetSeconds(playerDuration);
    if (isfinite(duration))
    {
        CGFloat width = CGRectGetWidth([self.playSlider bounds]);
        double tolerance = 0.5f * duration / width;
        
        __weak typeof(self) weakSelf = self;
        self.mTimeObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(tolerance, NSEC_PER_SEC) queue:NULL usingBlock:
                         ^(CMTime time)
                         {
                             [weakSelf p_syncSlider];
                         }];
    }

}

-(void)p_removePlayerTimeObserver{
    
    if (self.mTimeObserver)
    {
        [self.player removeTimeObserver:self.mTimeObserver];
        self.mTimeObserver = nil;
    }
}


//音乐锁屏信息展示(这里的信息应该后台返回，与URL对应。)
- (void)p_setupLockScreenInfo
{
    //歌词获取为空。
    //    AVAsset *asset = self.player.currentItem.asset;
    //    NSLog(@"lyrics===%@",asset.lyrics);
    
    // 1.获取锁屏中心
    MPNowPlayingInfoCenter *playingInfoCenter = [MPNowPlayingInfoCenter defaultCenter];
    
    //初始化一个存放音乐信息的字典
    NSMutableDictionary *playingInfoDict = [NSMutableDictionary dictionary];
    // 2、设置歌曲名
    [playingInfoDict setObject:self.musicModel.albumName forKey:MPMediaItemPropertyAlbumTitle];
    // 设置歌手名
    [playingInfoDict setObject:self.musicModel.artistName forKey:MPMediaItemPropertyArtist];
    // 3设置封面的图片
    MPMediaItemArtwork *artwork = [[MPMediaItemArtwork alloc] initWithImage:self.musicModel.albumImage];
    [playingInfoDict setObject:artwork forKey:MPMediaItemPropertyArtwork];
    
    // 4设置歌曲的总时长
    [playingInfoDict setObject:@(self.musicModel.duration) forKey:MPMediaItemPropertyPlaybackDuration];
    
    //当前播放时长
    double time = CMTimeGetSeconds([self.player currentTime]);
    [playingInfoDict setObject:@(time) forKey:MPNowPlayingInfoPropertyElapsedPlaybackTime];
    
    //音乐信息赋值给获取锁屏中心的nowPlayingInfo属性
    playingInfoCenter.nowPlayingInfo = playingInfoDict;
}

@end
