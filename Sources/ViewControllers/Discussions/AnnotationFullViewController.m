//
//  AnnotationFullViewController.m
//  Liri
//
//  Created by Ramani Arunachalam on 7/28/14.
//  Copyright (c) 2014 Vyaza. All rights reserved.
//

#import "AnnotationFullViewController.h"
#import "Flurry.h"

@interface AnnotationFullViewController ()
@property (weak, nonatomic) IBOutlet UIButton *closeBtn;

@property (weak, nonatomic) IBOutlet UIView *annotationFullView;
@end

@implementation AnnotationFullViewController

@synthesize imageView, imageToShow;
@synthesize annotationFullView = _annotationFullView;

- (void)initWithImage:(UIImage *)annotatedImage
{
    //imageToShow = annotatedImage;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    imageView.image = imageToShow;
    // Do any additional setup after loading the view.
    [Flurry logEvent:@"Annotation Full View Screen"];
}

- (void)viewDidLayoutSubviews
{
    if(IS_IPHONE_5) {
        //do stuff for 4 inch iPhone screen
    }
    else {
        //do stuff for 3.5 inch iPhone screen
        
            [self.imageView setFrame:CGRectMake(self.imageView.frame.origin.x, self.imageView.frame.origin.y, self.imageView.frame.size.width, 400)];
        
            [self.annotationFullView setFrame:CGRectMake(self.annotationFullView.frame.origin.x, self.annotationFullView.frame.origin.y, self.annotationFullView.frame.size.width, 420)];
    }
}

- (IBAction)closeAction:(id)sender {
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 8.0) {
        [self dismissViewControllerAnimated:NO completion:nil];
    } else {
        [self dismissViewControllerAnimated:NO completion:^{
            [[NSNotificationCenter defaultCenter]
             postNotificationName:kLightBoxFinishedAtDiscussionNotification
             object:self userInfo:@{@"className" : NSStringFromClass([self class])}];
        }];
    }
}
- (IBAction)annotate:(id)sender
{
    [[NSNotificationCenter defaultCenter]
     postNotificationName:kAnnotationOptionSelectedNotification
     object:self userInfo:@{@"pickedImage": imageView.image}];

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
