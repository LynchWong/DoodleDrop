//
//  GameLayer.m
//  DoodleDrop
//
//  Created by Lynch on 3/28/14.
//  Copyright 2014 __MyCompanyName__. All rights reserved.
//

#import "GameLayer.h"
#import "SimpleAudioEngine.h"


@implementation GameLayer

+ (id)scene {
    CCScene *scene = [CCScene node];
    CCLayer *layer = [GameLayer node];
    [scene addChild:layer];
    return scene;
}

- (id)init {
    if ((self = [super init])) {
        
        CCLOG(@"%@: %@", NSStringFromSelector(_cmd), self);
        
        [[CCFileUtils sharedFileUtils]  setiPadSuffix:@""];
        [[CCFileUtils sharedFileUtils] setiPadRetinaDisplaySuffix:@"-hd"];
        
        self.isAccelerometerEnabled = YES;
        
        player = [CCSprite spriteWithFile:@"alien.png"];
        [self addChild:player z:0 tag:1];
        
        CGSize screenSize = [CCDirector sharedDirector].winSize;
        float imageHeight = player.texture.contentSize.height;
        player.position = CGPointMake(screenSize.width / 2, imageHeight / 2);
        
        [self scheduleUpdate];
        [self initSpiders];
        
        scoreLabel = [CCLabelBMFont labelWithString:@"0" fntFile:@"bitmapfont.fnt"];
        scoreLabel.position = CGPointMake(screenSize.width / 2, screenSize.height);
        
        scoreLabel.anchorPoint = CGPointMake(0.5f, 1.0f);
        
        [self addChild:scoreLabel z:-1];

        [[SimpleAudioEngine sharedEngine] playBackgroundMusic:@"blues.mp3" loop:YES];
        [[SimpleAudioEngine sharedEngine] preloadEffect:@"alien-sfx.caf"];
        
        srandom(time(NULL));
        
        [self showGameOver];
    }
    return self;
}

- (void)dealloc {
    CCLOG(@"%@: %@", NSStringFromSelector(_cmd), self);
}

- (void)accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)acceleration {

    float deceleration = 0.4f;
    float sensitivity = 6.0f;
    float maxVelocity = 100;
    
    playerVelocity.x = playerVelocity.x * deceleration + acceleration.x * sensitivity;
    
    if (playerVelocity.x > maxVelocity) {
        playerVelocity.x = maxVelocity;
    } else if (playerVelocity.x < -maxVelocity) {
        playerVelocity.x = -maxVelocity;
    }
}

- (void)update:(ccTime)delta {
    
    CGPoint pos = player.position;
    pos.x += playerVelocity.x;
    
    CGSize screenSize = [CCDirector sharedDirector].winSize;
    float imageWidthHalved = player.texture.contentSize.width * 0.5f;
    float leftBorderLimit = imageWidthHalved;
    float rightBorderLimit = screenSize.width - imageWidthHalved;
    
    if (pos.x < leftBorderLimit) {
        pos.x = leftBorderLimit;
        playerVelocity = CGPointZero;
    } else if (pos.x > rightBorderLimit) {
        pos.x = rightBorderLimit;
        playerVelocity = CGPointZero;
    }
    player.position = pos;
    [self checkForCollision];
    
    if ([CCDirector sharedDirector].totalFrames % 60 == 0) {
        score++;
        [scoreLabel setString:[NSString stringWithFormat:@"%i", score]];
    }
}

- (void)initSpiders {

    CGSize screenSize = [CCDirector sharedDirector].winSize;
    
    CCSprite *tempSpider = [CCSprite spriteWithFile:@"spider.png"];
    float imageWidth = tempSpider.texture.contentSize.width;
    
    int numSpiders = screenSize.width / imageWidth;
    
    spiders = [NSMutableArray arrayWithCapacity:numSpiders];
    for (int i = 0; i < numSpiders; i++) {
        CCSprite *spider = [CCSprite spriteWithFile:@"spider.png"];
        [self addChild:spider z:0 tag:2];
        [spiders addObject:spider];
    }
    [self resetSpiders];
}

- (void)resetSpiders {
    
    CGSize screenSize = [CCDirector sharedDirector].winSize;
    CCSprite *tempSpider = [spiders lastObject];
    CGSize size = tempSpider.texture.contentSize;
    int numSpiders = [spiders count];
    for (int i = 0; i < numSpiders; i++) {
        CCSprite *spider = [spiders objectAtIndex:i];
        spider.position = CGPointMake(size.width * 0.5f + size.width * i, screenSize.height + size.height);
        [spider stopAllActions];
    }
    [self schedule:@selector(spidersUpdate:) interval:0.7f];
    numSpidersMoved = 0;
    spiderMoveDuration = 8.0f;
}

- (void)spidersUpdate:(ccTime)delta {
    
    for (int i = 0; i < 10; i++) {
        int randomSpiderIndex = CCRANDOM_0_1() * spiders.count;
        CCSprite *spider = [spiders objectAtIndex:randomSpiderIndex];
        
        if (spider.numberOfRunningActions == 0) {
            
            if (i > 0) {
                CCLOG(@"Dropping a Spider after %i retries.", i);
            }
            [self runSpiderMoveSequence:spider];
            break;
        }
    }
}

- (void)runSpiderMoveSequence:(CCSprite *)spider {

    numSpidersMoved++;
    if (numSpidersMoved % 8 == 0 && spiderMoveDuration > 2.0f) {
        spiderMoveDuration -= 0.1f;
    }
    CGSize screenSize = [CCDirector sharedDirector].winSize;
    CGPoint hangInTherePosition = CGPointMake(spider.position.x, screenSize.height - 3 * spider.texture.contentSize.height);
    CGPoint belowScreenPosition = CGPointMake(spider.position.x, - (3 * spider.texture.contentSize.height));
    CCMoveTo *moveHang = [CCMoveTo actionWithDuration:4.0f position:hangInTherePosition];
    CCEaseElasticOut *easeHang = [CCEaseElasticOut actionWithAction:moveHang period:0.8f];
    CCMoveTo *moveEnd = [CCMoveTo actionWithDuration:spiderMoveDuration position:belowScreenPosition];
    CCEaseBackInOut *easeEnd = [CCEaseBackInOut actionWithAction:moveEnd];
    
    CCCallBlock *callDidDrop = [CCCallBlock actionWithBlock:^void(){
        CGPoint pos = spider.position;
        pos.y = screenSize.height + spider.texture.contentSize.height;
        spider.position = pos;
    }];
    CCSequence *sequence = [CCSequence actions:easeHang, easeEnd, callDidDrop, nil];
    [spider runAction:sequence];
}

- (void)runSpiderWiggleSequence:(CCSprite *)spider {

    CCScaleTo *scaleUp = [CCScaleTo actionWithDuration:CCRANDOM_0_1() * 2 + 1 scale:1.05f];
    CCEaseBackInOut *easeUp = [CCEaseBackInOut actionWithAction:scaleUp];
    CCScaleTo *scaleDown = [CCScaleTo actionWithDuration:CCRANDOM_0_1() * 2 + 1 scale:0.95f];
    CCEaseBackInOut *easeDown = [CCEaseBackInOut actionWithAction:scaleDown];
    CCSequence *scaleSequence = [CCSequence actions:easeUp, easeDown, nil];
    CCRepeatForever *repeatScals = [CCRepeatForever actionWithAction:scaleSequence];
    [spider runAction:repeatScals];
}

- (void)checkForCollision {

    float playerImageSize = player.texture.contentSize.width;
    CCSprite *spider = [spiders lastObject];
    float spiderImageSize = spider.texture.contentSize.width;
    float playerCollisionRadius = playerImageSize * 0.4f;
    float spiderCollisionRadius = spiderImageSize * 0.4f;
    float maxCollisionDistance = playerCollisionRadius + spiderCollisionRadius;
    int numSpiders = spiders.count;
    for (int i = 0; i < numSpiders; i++) {
        spider = [spiders objectAtIndex:i];
        if (spider.numberOfRunningActions == 0) {
            continue;
        }
        float actualDistance = ccpDistance(player.position, spider.position);
        if (actualDistance < maxCollisionDistance) {
            [[SimpleAudioEngine sharedEngine] playEffect:@"alien-sfx.caf"];
            [self showGameOver];
            break;
        }
    }
}

- (void)resetGame {

    [self setScreenSaverEnabled:NO];
    
    [self removeChildByTag:100 cleanup:YES];
    [self removeChildByTag:101 cleanup:YES];
    
    self.isAccelerometerEnabled = YES;
    self.isTouchEnabled = NO;
    [self resetSpiders];
    
    [self scheduleUpdate];
    score = 0;
    [scoreLabel setString:@"0"];
}

- (void)setScreenSaverEnabled:(BOOL)enable {
    UIApplication *thisApp = [UIApplication sharedApplication];
    thisApp.idleTimerDisabled = !enable;
}

- (void)showGameOver {

    [self setScreenSaverEnabled:YES];
    
    for (CCNode *node in self.children) {
        [node stopAllActions];
    }
    
    for (CCSprite *spider in spiders) {
        [self runSpiderWiggleSequence:spider];
    }
    
    self.isAccelerometerEnabled = NO;
    self.isTouchEnabled = YES;
    
    [self unscheduleAllSelectors];
    
    CGSize screenSize = [CCDirector sharedDirector].winSize;
    CCLabelTTF *gameOver = [CCLabelTTF labelWithString:@"GAME OVER!" fontName:@"Marker Felt" fontSize:60];
    gameOver.position = CGPointMake(screenSize.width / 2, screenSize.height / 3);
    [self addChild:gameOver z:100 tag:100];
    
    CCTintTo* tint1 = [CCTintTo actionWithDuration:2 red:255 green:0 blue:0];
	CCTintTo* tint2 = [CCTintTo actionWithDuration:2 red:255 green:255 blue:0];
	CCTintTo* tint3 = [CCTintTo actionWithDuration:2 red:0 green:255 blue:0];
	CCTintTo* tint4 = [CCTintTo actionWithDuration:2 red:0 green:255 blue:255];
	CCTintTo* tint5 = [CCTintTo actionWithDuration:2 red:0 green:0 blue:255];
	CCTintTo* tint6 = [CCTintTo actionWithDuration:2 red:255 green:0 blue:255];
	CCSequence* tintSequence = [CCSequence actions:tint1, tint2, tint3, tint4, tint5, tint6, nil];
	CCRepeatForever* repeatTint = [CCRepeatForever actionWithAction:tintSequence];
	[gameOver runAction:repeatTint];
    
    CCRotateTo* rotate1 = [CCRotateTo actionWithDuration:2 angle:3];
	CCEaseBounceInOut* bounce1 = [CCEaseBounceInOut actionWithAction:rotate1];
	CCRotateTo* rotate2 = [CCRotateTo actionWithDuration:2 angle:-3];
	CCEaseBounceInOut* bounce2 = [CCEaseBounceInOut actionWithAction:rotate2];
	CCSequence* rotateSequence = [CCSequence actions:bounce1, bounce2, nil];
	CCRepeatForever* repeatBounce = [CCRepeatForever actionWithAction:rotateSequence];
	[gameOver runAction:repeatBounce];
	
	CCJumpBy* jump = [CCJumpBy actionWithDuration:3 position:CGPointZero height:screenSize.height / 3 jumps:1];
	CCRepeatForever* repeatJump = [CCRepeatForever actionWithAction:jump];
	[gameOver runAction:repeatJump];
    
    CCLabelTTF* touch = [CCLabelTTF labelWithString:@"tap screen to play again" fontName:@"Arial" fontSize:20];
	touch.position = CGPointMake(screenSize.width / 2, screenSize.height / 4);
	[self addChild:touch z:100 tag:101];
	
	// did you try turning it off and on again?
	CCBlink* blink = [CCBlink actionWithDuration:10 blinks:20];
	CCRepeatForever* repeatBlink = [CCRepeatForever actionWithAction:blink];
	[touch runAction:repeatBlink];
}

- (void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {

    [self resetGame];
}

-(void) draw
{
	[super draw];
	
	// Only draw this debugging information in, well, debug builds.
#if DEBUG
	// Iterate through all nodes of the layer.
	for (CCNode* node in [self children])
	{
		// Make sure the node is a CCSprite and has the right tags.
		if ([node isKindOfClass:[CCSprite class]] && (node.tag == 1 || node.tag == 2))
		{
			// The sprite's collision radius is a percentage of its image width.
			// The same factor is used in the checkForCollision method above.
			CCSprite* sprite = (CCSprite*)node;
			float radius = sprite.texture.contentSize.width * 0.4f;
			float angle = 0;
			int numSegments = 10;
			bool drawLineToCenter = NO;
			ccDrawCircle(sprite.position, radius, angle, numSegments, drawLineToCenter);
		}
	}
#endif
	
	CGSize screenSize = [CCDirector sharedDirector].winSize;
	
	// always keep variables you have to calculate only once outside the loop
	float threadCutPosition = screenSize.height * 0.75f;
	
	// Draw a spider thread using OpenGL
	for (CCSprite* spider in spiders)
	{
		// only draw thread up to a certain point
		if (spider.position.y > threadCutPosition)
		{
			// vary thread position a little so it looks a bit more dynamic
			float threadX = spider.position.x + (CCRANDOM_0_1() * 2.0f - 1.0f);
			
			ccDrawColor4F(0.5f, 0.5f, 0.5f, 1.0f);
			ccDrawLine(spider.position, CGPointMake(threadX, screenSize.height));
		}
	}
}


@end
