//
//  GameLayer.h
//  DoodleDrop
//
//  Created by Lynch on 3/28/14.
//  Copyright 2014 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"

@interface GameLayer : CCLayer {
    
    CCSprite *player;//玩家精灵
    CGPoint playerVelocity;//加速计
    
    NSMutableArray *spiders;//蜘蛛精灵数组
    float spiderMoveDuration;//蜘蛛移动的时间
    int numSpidersMoved;//移动中的蜘蛛的个数
    
    int score;//得分
    CCNode<CCLabelProtocol> *scoreLabel;//得分标签
}

+ (id)scene;

@end
