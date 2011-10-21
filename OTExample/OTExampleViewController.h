//
//  OTExampleViewController.h
//  OTExample
//
//  Created by Pavitra on 10/20/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OTExampleViewController : UIViewController{
    IBOutlet UISlider *slider;
}

-(IBAction)clickedButton :(id)sender;
-(IBAction)movedSlider:(id)sender;
@end
