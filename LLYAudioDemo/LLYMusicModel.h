//
//  LLYMusicModel.h
//  LLYAudioDemo
//
//  Created by lly on 2017/9/4.
//  Copyright © 2017年 lly. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface LLYMusicModel : NSObject

@property (nonatomic,copy) NSString *artistName;
@property (nonatomic,copy) NSString *musicTitle;
@property (nonatomic,copy) NSString *albumName;
@property (nonatomic,strong) UIImage *albumImage;
@property (nonatomic,assign) double duration;

@end
