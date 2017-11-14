//
//  ViewController.m
//  GetRated
//
//  Created by Neil Morton on 11/14/2017.
//  Copyright (c) 2017 Neil Morton. All rights reserved.
//

#import "ViewController.h"
#import <GetRated/getRated.h>

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setTitle:@"Press Me" forState:UIControlStateNormal];
    [button sizeToFit];
    button.center = CGPointMake(
                                self.view.frame.size.width/2,
                                self.view.frame.size.height/2
                                );
    
    [button addTarget:self action:@selector(buttonPressed)
     forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:button];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)buttonPressed
{
    [[getRated sharedInstance] promptIfAllCriteriaMet];
}

@end
