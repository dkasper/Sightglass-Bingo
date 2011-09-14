//
//  RootViewController.m
//  sightglassbingo
//
//  Created by David Kasper on 8/22/11.
//  Copyright 2011 Yobongo. All rights reserved.
//

#import "RootViewController.h"
#import "sightglassbingoAppDelegate.h"
#import "constants.h"
#import "GameSquare.h"
#import "PFObject.h"
#import "PFQuery.h"

@implementation RootViewController

@synthesize buttons;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        buttons = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    CGFloat offset = 65;
    // Do any additional setup after loading the view from its nib.
    for(int i=0; i<GRID_SIZE; i++) {
        [buttons addObject:[[NSMutableArray alloc] initWithCapacity:GRID_SIZE]];
        for(int j=0; j<GRID_SIZE; j++) {
            GameSquare *square = [[GameSquare alloc] initWithFrame:CGRectMake(i*72 + 18, j*100 + offset, 72, 100) withX:i withY:j];
            square.delegate = self;
            [[buttons objectAtIndex:i] addObject:square];
            [self.view addSubview:square];
        }
    }

    [self newGame];
}

-(NSArray *)shuffle:(NSArray *)objects {
    NSMutableArray *orig = [objects mutableCopy];
    NSMutableArray *a = [[NSMutableArray alloc] initWithCapacity:[objects count]];
    while ([orig count] > 0) {
        int i = arc4random() % [orig count];
        [a addObject:[orig objectAtIndex:i]];
        [orig removeObjectAtIndex:i];
    }
    return a;
}

-(void)checkWin:(id)sender {
    BOOL columnWin, rowWin;
    
    //check columns
    for(int i=0; i<GRID_SIZE; i++) {
        columnWin = YES;
        rowWin = YES;
        for(int j=0; j<GRID_SIZE; j++) {
            GameSquare *square = [[buttons objectAtIndex:i] objectAtIndex:j];
            columnWin &= [square selected];
            
            GameSquare *square2 = [[buttons objectAtIndex:j] objectAtIndex:i];
            rowWin &= [square2 selected];
        }
        if(columnWin) {
            [self setWinShareTextForColumn:i];
            [self showWonAlert];
            return;
        }
        if(rowWin) {
            [self setWinShareTextForRow:i];
            [self showWonAlert];
            return;
        }
    }
}

-(void)setWinShareTextForColumn:(NSInteger)i {
    NSMutableString *str = [[NSMutableString alloc] init];
    for(int j=0; j<GRID_SIZE; j++) {
        GameSquare *square = [[buttons objectAtIndex:i] objectAtIndex:j];
        
        if(j == GRID_SIZE -1) {
            [str appendFormat:@"and %@",[square text]];
        } else {
            [str appendFormat:@"%@, ",[square text]];
        }
    }
    winShareText = [str retain];
}

-(void)setWinShareTextForRow:(NSInteger)i {
    NSMutableString *str = [[NSMutableString alloc] init];
    for(int j=0; j<GRID_SIZE; j++) {
        GameSquare *square = [[buttons objectAtIndex:j] objectAtIndex:i];
        
        if(j == GRID_SIZE -1) {
            [str appendFormat:@"and %@",[square text]];
        } else {
            [str appendFormat:@"%@, ",[square text]];
        }
    }
    winShareText = [str retain];
}

-(void)showWonAlert {
    [[[[UIAlertView alloc] initWithTitle:@"You Won!" message:@"Share Your Victory?" delegate:self cancelButtonTitle:@"New Game" otherButtonTitles:@"Facebook", @"Twitter", nil] autorelease] show];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {    
    if(buttonIndex == 1) {
        //share facebook
        sightglassbingoAppDelegate *del = (sightglassbingoAppDelegate *)[[UIApplication sharedApplication] delegate];
        
        if (![del.facebook isSessionValid]) {
            [del.facebook authorize:[NSArray arrayWithObject:@"publish_stream"]];
        } else {
            [self performSelector:@selector(facebookShare) withObject:nil afterDelay:0.1];
        }
        return;
        
    } else if(buttonIndex == 2) {
        //share twitter
        NSString *msgText = [self encodeURL:[NSString stringWithFormat:@"Just won at Sightglass Bingo by spotting %@! Get the app: http://bit.ly/oMzo2t",winShareText]];
        // prefer to use twitter app
        NSURL *tweetURL = [NSURL URLWithString:[NSString stringWithFormat:@"twitter://post?message=%@", msgText]];
        if (![[UIApplication sharedApplication] canOpenURL:tweetURL]) {
            // otherwise use safari
            tweetURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://twitter.com/intent/tweet?text=%@", msgText]];
        }
        [tweetURL retain];

        [[UIApplication sharedApplication] openURL:tweetURL];
        [self performSelector:@selector(showWonAlert) withObject:nil afterDelay:0.1];
    } else {    
        [self newGame];
    }
}

-(void)facebookShare {
    sightglassbingoAppDelegate *del = (sightglassbingoAppDelegate *)[[UIApplication sharedApplication] delegate];

    NSMutableDictionary* params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   @"http://bit.ly/oMzo2t", @"link",
                                   @"http://i.imgur.com/bsp4U.png", @"picture",
                                   @"I just won at Sightglass Bingo!", @"name",
                                   @"Sightglass Bingo", @"caption",
                                   [NSString stringWithFormat:@"Spotted %@",winShareText], @"description",
                                   nil];
    
    [del.facebook dialog:@"feed" andParams:params andDelegate:self];
}
                             
 - (NSString*)encodeURL:(NSString *)string {
     NSString *newString = NSMakeCollectable([(NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)string, NULL, CFSTR(":/?#[]@!$ &'()*+,;=\"<>%{}|\\^~`"), CFStringConvertNSStringEncodingToEncoding(NSASCIIStringEncoding)) autorelease]);
     if (newString) {
         return newString;
     }
     return @"";
 }

-(void)newGame {
    PFQuery *query = [PFQuery queryWithClassName:@"Board"];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        PFObject *squareLabels = [self shuffle:[[objects objectAtIndex:0] objectForKey:@"values"]];
        
        for(int i=0; i<GRID_SIZE; i++) {
            for(int j=0; j<GRID_SIZE; j++) {
                if([squareLabels count] > i*GRID_SIZE + j) {
                    [[[buttons objectAtIndex:i] objectAtIndex:j] setText:[squareLabels objectAtIndex:i*GRID_SIZE+j]];
                    [[[buttons objectAtIndex:i] objectAtIndex:j] setSelected:NO];
                }
            }
        }
    }];
}

////////////////////////////////////////////////////////////////////////////////
// FBDialogDelegate
- (void)dialogDidComplete:(FBDialog *)dialog {
    [self showWonAlert];
}

-(void)dialogDidNotComplete:(FBDialog *)dialog {
    [self showWonAlert];
}

- (void)dialog:(FBDialog*)dialog didFailWithError:(NSError *)error {
    [self showWonAlert];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
