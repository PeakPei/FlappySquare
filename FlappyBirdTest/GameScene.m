//
//  GameScene.m
//  FlappyBirdClone
//
//  Created by Romain Fillaudeau on 07/10/15.
//  Copyright (c) 2015 Romain Fillaudeau. All rights reserved.
//

#import "GameScene.h"

static const CGFloat kVerticalPipeGap = 100.0;
static const uint32_t birdCategory = 1 << 0;
static const uint32_t worldCategory = 1 << 1;
static const uint32_t pipeCategory = 1 << 2;
static const uint32_t scoreCategory = 1 << 3;

static const CGFloat groundHeight = 100;

static const CGFloat pipeWidth = 60;
static const CGFloat pipeHeight = 600;

@interface GameScene ()

@property (nonatomic) SKSpriteNode *bird;
@property (nonatomic) SKColor *skyColor;
@property (nonatomic) SKAction *moveAndRemovePipes;
@property (nonatomic) SKNode *moving;
@property (nonatomic) SKNode *pipes;
@property (nonatomic) BOOL canRestart;
@property (nonatomic) SKLabelNode *scoreLabelNode;
@property (nonatomic) NSInteger score;

@end

@implementation GameScene

#pragma mark -

- (void)didMoveToView:(SKView *)view {
    self.canRestart = NO;
    
    self.physicsWorld.gravity = CGVectorMake(0.0, -5.0);
    self.physicsWorld.contactDelegate = self;
    
    self.skyColor = [self hexToUIColor:@"#C5CAE9"];
    [self setBackgroundColor:self.skyColor];
    
    self.pipes = [SKNode node];
    self.moving = [SKNode node];
    self.moving.speed = 1.5;
    
    [self addChild:self.moving];
    [self.moving addChild:self.pipes];
    
    [self createBird];
    
    
    // Create ground physics container
    SKSpriteNode *ground = [SKSpriteNode spriteNodeWithColor:[self hexToUIColor:@"#1A237E"] size:CGSizeMake(self.frame.size.width * 2, groundHeight * 2)];
    ground.position = CGPointMake(0, 0);
    ground.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:ground.size];
    ground.physicsBody.dynamic = NO;
    
    [self addChild:ground];
    
    SKNode *dummyTop = [SKNode node];
    dummyTop.position = CGPointMake(0, self.frame.size.height);
    dummyTop.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:CGSizeMake(self.frame.size.width, 1)];
    dummyTop.physicsBody.dynamic = NO;
    [self addChild:dummyTop];
    
    // Create pipes
    
    
    // Pipes repetition
    CGFloat distanceToMove = self.frame.size.width + pipeWidth * 4;
    SKAction *movePipes = [SKAction moveByX:-distanceToMove y:0 duration:0.01 * distanceToMove];
    SKAction *removePipes = [SKAction removeFromParent];
    self.moveAndRemovePipes = [SKAction sequence:@[movePipes, removePipes]];
    
    SKAction *spawn = [SKAction performSelector:@selector(spawnPipes) onTarget:self];
    SKAction *delay = [SKAction waitForDuration:3.0];
    SKAction *spawnThenDelay = [SKAction sequence:@[spawn, delay]];
    SKAction *spawnThenDelayForever = [SKAction repeatActionForever:spawnThenDelay];
    [self runAction:spawnThenDelayForever];
    
    // Collisions
    self.bird.physicsBody.categoryBitMask = birdCategory;
    self.bird.physicsBody.collisionBitMask = worldCategory | pipeCategory;
    self.bird.physicsBody.contactTestBitMask = worldCategory | pipeCategory;
    
    ground.physicsBody.categoryBitMask = worldCategory;
    dummyTop.physicsBody.categoryBitMask = worldCategory;
    
    // Initialize label and create a label which holds the score
    self.score = 0;
    self.scoreLabelNode = [SKLabelNode labelNodeWithFontNamed:@"System"];
    self.scoreLabelNode.position = CGPointMake(CGRectGetMidX(self.frame), groundHeight / 2 - 10);
    self.scoreLabelNode.zPosition = 100;
    [self updateScore];
    [self addChild:self.scoreLabelNode];
}

- (void)spawnPipes {
    CGFloat y = 0;
    
    while (y < groundHeight * 2) {
        y = arc4random() % (NSInteger)(self.frame.size.height);
    }
    
    SKSpriteNode *pipeTop = [SKSpriteNode spriteNodeWithColor:[self hexToUIColor:@"#303F9F"] size:CGSizeMake(pipeWidth, pipeHeight)];
    pipeTop.position = CGPointMake(0, y + kVerticalPipeGap * 2);
    pipeTop.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:pipeTop.size];
    pipeTop.physicsBody.dynamic = NO;
    
    SKSpriteNode *pipeBottom = [SKSpriteNode spriteNodeWithColor:[self hexToUIColor:@"#303F9F"] size:CGSizeMake(pipeWidth, pipeHeight)];
    pipeBottom.position = CGPointMake(0, y - pipeBottom.size.height);
    pipeBottom.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:pipeBottom.size];
    pipeBottom.physicsBody.dynamic = NO;
    
    SKNode *pipePair = [SKNode node];
    pipePair.position = CGPointMake(self.frame.size.width + pipeBottom.size.width * 2, groundHeight * 2);
    pipePair.zPosition = -10;
    
    [pipePair addChild:pipeBottom];
    [pipePair addChild:pipeTop];
    
    SKNode *contactNode = [SKNode node];
    contactNode.position = CGPointMake(pipeBottom.size.width + self.bird.size.width / 2, CGRectGetMidY(self.frame));
    contactNode.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:CGSizeMake(pipeTop.size.width, self.frame.size.height)];
    contactNode.physicsBody.dynamic = NO;
    contactNode.physicsBody.categoryBitMask = scoreCategory;
    contactNode.physicsBody.contactTestBitMask = birdCategory;
    [pipePair addChild:contactNode];
    
    // Collisions
    pipeBottom.physicsBody.categoryBitMask = pipeCategory;
    pipeBottom.physicsBody.contactTestBitMask = birdCategory;
    
    pipeTop.physicsBody.categoryBitMask = pipeCategory;
    pipeTop.physicsBody.contactTestBitMask = birdCategory;
    
    [pipePair runAction:self.moveAndRemovePipes];
    
    [self.pipes addChild:pipePair];
}

- (void)createBird {
    // Create bird
    self.bird = [SKSpriteNode spriteNodeWithColor:[self hexToUIColor:@"#3F51B5"] size:CGSizeMake(25, 25)];
    self.bird.position = CGPointMake(self.frame.size.width / 4, CGRectGetMidY(self.frame));
    
    // SEt physics of the bird
    self.bird.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:self.bird.size];
    self.bird.physicsBody.dynamic = YES;
    self.bird.physicsBody.allowsRotation = YES;
    
    [self addChild:self.bird];
}

- (void)createGround {
    
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    /* Called when a touch begins */
    
    if (self.moving.speed > 0) {
        self.bird.physicsBody.velocity = CGVectorMake(0, 0);
        [self.bird.physicsBody applyImpulse:CGVectorMake(0, 10)];
    } else if (self.canRestart) {
        [self resetScene];
    }
}

CGFloat clamp(CGFloat min, CGFloat max, CGFloat value) {
    if (value > max) {
        return max;
    } else if (value < min) {
        return min;
    } else {
        return value;
    }
}

- (void)update:(CFTimeInterval)currentTime {
    /* Called before each frame is rendered */
    
    if (self.moving.speed > 0) {
        self.bird.zRotation = clamp(-1, 0.5, self.bird.physicsBody.velocity.dy * (self.bird.physicsBody.velocity.dy < 0 ? 0.003 : 0.001));
    }
}

- (void)didBeginContact:(SKPhysicsContact *)contact {
    if (self.moving.speed > 0) {
        if ((contact.bodyA.categoryBitMask & scoreCategory) == scoreCategory || (contact.bodyB.categoryBitMask & scoreCategory) == scoreCategory) {
            // Bird has contact with score entity
            
            self.score++;
            [self updateScore];
            
            // Add a little visual feedback for the score increment
            [self.scoreLabelNode runAction:[SKAction sequence:@[[SKAction scaleTo:1.5 duration:0.1], [SKAction scaleTo:1.0 duration:0.1]]]];
        } else {
            self.moving.speed = 0;
            
            // Flash background if contact is detected
            [self removeActionForKey:@"flash"];
            
            [self runAction:[SKAction sequence:@[[SKAction repeatAction:[SKAction sequence:@[[SKAction runBlock:^{
                self.backgroundColor = [SKColor redColor];
            }], [SKAction waitForDuration:0.05], [SKAction runBlock:^{
                self.backgroundColor = self.skyColor;
            }], [SKAction waitForDuration:0.05]]] count:3], [SKAction runBlock:^{
                self.canRestart = YES;
            }]]] withKey:@"flash"];
        }
    }
}

- (void)resetScene {
    // Move bird to original position and reset velocity
    self.bird.position = CGPointMake(self.frame.size.width / 4, CGRectGetMidY(self.frame));
    self.bird.physicsBody.velocity = CGVectorMake(0, 0);
    
    self.bird.physicsBody.collisionBitMask = worldCategory | pipeCategory;
    self.bird.speed = 1.0;
    self.bird.zRotation = 0.0;
    
    // Remove all existing pipes
    [self.pipes removeAllChildren];
    
    // Reset self.canRestart
    self.canRestart = NO;
    
    // Restart animation
    self.moving.speed = 1.5;
    
    // Reset score
    self.score = 0;
    [self updateScore];
}

- (void)updateScore {
    self.scoreLabelNode.text = [NSString stringWithFormat:@"%ld", (long)self.score];
}

- (UIColor *)hexToUIColor:(NSString *)hexString {
    unsigned rgbValue = 0;
    NSScanner *scanner = [NSScanner scannerWithString:hexString];
    [scanner setScanLocation:1]; // bypass '#' character
    [scanner scanHexInt:&rgbValue];
    return [UIColor colorWithRed:((rgbValue & 0xFF0000) >> 16)/255.0 green:((rgbValue & 0xFF00) >> 8)/255.0 blue:(rgbValue & 0xFF)/255.0 alpha:1.0];
}

@end
