//
//  ViewController.h
//  meu9digito
//
//  Created by Felipe on 27/10/13.
//  Copyright (c) 2013 Felipe. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController <UIAlertViewDelegate>  {
    IBOutlet UITextView *txt;
    IBOutlet UIButton *btn;
    IBOutlet UIActivityIndicatorView *indView;
}

- (IBAction)btnTouched:(id)sender;

@end
