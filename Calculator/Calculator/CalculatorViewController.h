//
//  CalculatorViewController.h
//  Calculator
//
//  Created by Ed Sibbald on 10/4/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CalculatorBrain.h"

@interface CalculatorViewController : UIViewController {
	UILabel *display;
	CalculatorBrain *brain;
	BOOL userIsTypingANumber;
}

@property (retain) IBOutlet UILabel *display;

- (IBAction)digitPressed:(UIButton *)sender;
- (IBAction)operationPressed:(UIButton *)sender;
- (IBAction)variablePressed:(UIButton*)sender;
- (IBAction)decimalPointPressed;
- (IBAction)solvePressed;

@end
