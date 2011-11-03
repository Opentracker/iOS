//
//  OTExampleViewController.h
//  OTExample
//
//  Created by Pavitra on 10/20/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OTExampleViewController : UIViewController{
    UILabel *sliderLabel;
    IBOutlet UISwitch *mySwitch;
}
@property (nonatomic,retain) IBOutlet UILabel *sliderLabel;

-(IBAction) sliderChanged:(id) sender;
-(IBAction)clickedButton :(id)sender;
-(IBAction)switchMoved:(id)sender;
@end
