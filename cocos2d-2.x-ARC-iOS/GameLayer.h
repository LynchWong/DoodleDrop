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
    
    CCSprite *player;
    CGPoint playerVelocity;
    
    NSMutableArray *spiders;
    float spiderMoveDuration;
    int numSpidersMoved;
    
    int score;
    CCNode<CCLabelProtocol> *scoreLabel;
}

+ (id)scene;

@end
