//
//  ViewController.m
//  meu9digito
//
//  Created by Felipe on 27/10/13.
//  Copyright (c) 2013 Felipe. All rights reserved.
//

#import "ViewController.h"
#import "AppDelegate.h"

@interface ViewController ()

@property ABAddressBookRef *addressBook;
@property NSArray *statesArray;
@property NSMutableArray *labelsToLookFor;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    self.labelsToLookFor = [[NSMutableArray alloc] init];
    self.statesArray = [[NSArray alloc] init];
    self.statesArray = [((AppDelegate *)[UIApplication sharedApplication].delegate).states componentsSeparatedByString:@";"];
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0) {
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:NO];
    } else {
        [[UIApplication sharedApplication] setStatusBarHidden:NO];
    }
    self.addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"9Added"]) {
        [txt setTextAlignment:NSTextAlignmentCenter];
        [txt setText:@"O nono dígito já foi adicionado! Se gostou do app, entre em contato com o desenvolvedor através do email:lfelipeas@gmail.com! Obrigado!"];
        [btn setTitle:@"Remover" forState:UIControlStateNormal];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [txt setFont:[UIFont fontWithName:@"HelveticaNeue-Thin" size:20.0]];
    [txt setTextColor:[UIColor whiteColor]];
    if (self.view.frame.size.height < 568) {
        [btn setFrame:CGRectMake(btn.frame.origin.x, (btn.frame.origin.y-80.0), btn.frame.size.width, btn.frame.size.height)];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

#pragma -mark Button Methods

- (void)btnTouched:(id)sender {
    [self checkAddressBookAccess];
}

- (void)checkAddressBookAccess {
    switch (ABAddressBookGetAuthorizationStatus()) {
        case kABAuthorizationStatusAuthorized: {
            [self accessGrantedForAddressBook];
            break;
        }
        case kABAuthorizationStatusNotDetermined: {
            [self requestAddressBookAccess];
            break;
        }
        case kABAuthorizationStatusDenied:
        case kABAuthorizationStatusRestricted: {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Meu9Digito" message:@"Permissão necessária não foi dada. Para que o app tenha permissão para alterar seus contatos, vá em Ajustes > Privacidade > Contatos." delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
            [alert show];
            break;
        }
        default:
            break;
    }
}

- (void)accessGrantedForAddressBook {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"9Added"]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Meu9digito" message:@"O nono dígito já foi adicionado. Deseja removê-lo?" delegate:self cancelButtonTitle:@"Não" otherButtonTitles:@"Sim", nil];
        alert.tag = 3;
        [alert show];
    } else {
        [indView startAnimating];
        [self add9digit];
    }
}

- (void)requestAddressBookAccess {
    ABAddressBookRequestAccessWithCompletion(self.addressBook, ^(bool granted, CFErrorRef error) {
        if (granted) {
            NSLog(@"Access Granted!");
            [self accessGrantedForAddressBook];
        }
    });
}

- (void)add9digit {
    [btn setEnabled:NO];
    NSArray *contactsArr = (NSArray *)CFBridgingRelease(ABAddressBookCopyArrayOfAllPeople(self.addressBook));
    for (int i = 0; i < [contactsArr count]; i++) {
        ABRecordRef personRecord = (__bridge ABRecordRef)[contactsArr objectAtIndex:i];
        //        ABPersonViewController *person = [[ABPersonViewController alloc] init];
        //        person.displayedPerson = personRecord;
        //        person.allowsEditing = YES;
        //    NSString *name = (__bridge_transfer NSString*)ABRecordCopyValue(personRecord, kABPersonFirstNameProperty);
        //    NSLog(@"%@", name);
        ABMultiValueRef phoneNumbers = ABRecordCopyValue(personRecord, kABPersonPhoneProperty);
        ABMutableMultiValueRef changedPhoneNumbers = ABMultiValueCreateMutable(kABMultiStringPropertyType);
        for (int j = 0; j < ABMultiValueGetCount(phoneNumbers); j++) {
            NSString *label = (__bridge_transfer NSString *)ABMultiValueCopyLabelAtIndex(phoneNumbers, j);
            NSString *number = (__bridge_transfer NSString *)ABMultiValueCopyValueAtIndex(phoneNumbers, j);
            if ([label isEqualToString:@"iPhone"] || [label isEqualToString:@"_$!<Mobile>!$_"] || [label isEqualToString:@"_$!<Work>!$_"]) {
                NSRange r;
                if ([self testPhone:[number substringToIndex:1]]) {
                    r = [number rangeOfString:@"-"];
                    if ((r.length == 0 && [number length] == 8) || (r.length > 0 && [number length] == 9)) {
                        number = [NSString stringWithFormat:@"9%@", number];
                    }
                } else {
                    r = [number rangeOfString:@"+55"];
                    if (r.length > 0) {
                        r = [number rangeOfString:@")"];
                        if (r.length > 0) {
                            NSString *prefix = [number substringToIndex:r.location];
                            if ([self testDDD:prefix]) {
                                NSString *nmbr = [number substringFromIndex:(r.location+1)];
                                if ([[nmbr substringToIndex:1] isEqualToString:@" "]) {
                                    nmbr = [nmbr substringFromIndex:1];
                                }
                                if ([self testPhone:[nmbr substringToIndex:1]]) {
                                    number = [NSString stringWithFormat:@"%@)9%@", prefix, nmbr];
                                }
                            }
                        } else {
                            NSString *prefix = [number substringToIndex:5];
                            if ([self testDDD:prefix]) {
                                NSString *nmbr = [number substringFromIndex:5];
                                if ([self testPhone:[nmbr substringToIndex:1]]) {
                                    number = [NSString stringWithFormat:@"%@9%@", prefix, nmbr];
                                }
                            }
                        }
                    } else {
                        r = [number rangeOfString:@"("];
                        if (r.length > 0) {
                            r = [number rangeOfString:@")"];
                            NSString *prefix = [number substringToIndex:r.location];
                            if ([self testDDD:prefix]) {
                                NSString *nmbr = [number substringFromIndex:(r.location+2)];
                                if ([self testPhone:[nmbr substringToIndex:1]]) {
                                    number = [NSString stringWithFormat:@"%@)9%@", prefix, nmbr];
                                }
                            }
                        }
                    }
                }
            }
            ABMultiValueAddValueAndLabel(changedPhoneNumbers, (__bridge CFTypeRef)(number), (__bridge CFStringRef)(label),NULL);
        }
        ABRecordSetValue(personRecord, kABPersonPhoneProperty, changedPhoneNumbers, nil);
        ABAddressBookAddRecord(self.addressBook, personRecord, nil);
    }
    ABAddressBookSave(self.addressBook, nil);
    [indView stopAnimating];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Meu9Digito" message:@"Nono dígito adicionado com sucesso!" delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
    alert.tag = 1;
    [alert show];
    [btn setEnabled:YES];
}

- (void)remove9digit {
    [btn setEnabled:NO];
    NSArray *contactsArr = (NSArray *)CFBridgingRelease(ABAddressBookCopyArrayOfAllPeople(self.addressBook));
    for (int i = 0; i < [contactsArr count]; i++) {
        ABRecordRef personRecord = (__bridge ABRecordRef)[contactsArr objectAtIndex:i];
        ABMultiValueRef phoneNumbers = ABRecordCopyValue(personRecord, kABPersonPhoneProperty);
        ABMutableMultiValueRef changedPhoneNumbers = ABMultiValueCreateMutable(kABMultiStringPropertyType);
        for (int j = 0; j < ABMultiValueGetCount(phoneNumbers); j++) {
            NSString *label = (__bridge_transfer NSString *)ABMultiValueCopyLabelAtIndex(phoneNumbers, j);
            NSString *number = (__bridge_transfer NSString *)ABMultiValueCopyValueAtIndex(phoneNumbers, j);
            if ([label isEqualToString:@"iPhone"] || [label isEqualToString:@"_$!<Mobile>!$_"] || [label isEqualToString:@"_$!<Work>!$_"]) {
                NSRange r = [number rangeOfString:@"+55"];
                if (r.length > 0) {
                    r = [number rangeOfString:@")"];
                    NSString *prefix = [number substringToIndex:(r.location+1)];
                    if ([self testDDD:prefix]) {
                        NSString *nmbr = [number substringFromIndex:(r.location+1)];
                        number = [NSString stringWithFormat:@"%@%@", prefix, [nmbr substringFromIndex:1]];
                    }
                } else {
                    r = [number rangeOfString:@"("];
                    if (r.length > 0) {
                        r = [number rangeOfString:@")"];
                        NSString *prefix = [number substringToIndex:(r.location+1)];
                        if ([self testDDD:prefix]) {
                            NSString *nmbr = [number substringFromIndex:(r.location+1)];
                            number = [NSString stringWithFormat:@"%@%@", prefix, [nmbr substringFromIndex:1]];
                        }
                    } else {
                        r = [number rangeOfString:@"-"];
                        if (r.length > 0) {
                            if (number.length == 10) {
                                number = [number substringFromIndex:1];
                            }
                        } else {
                            if (number.length >= 9) {
                                number = [number substringFromIndex:1];
                            }
                        }
                    }
                }
            }
            ABMultiValueAddValueAndLabel(changedPhoneNumbers, (__bridge CFTypeRef)(number), (__bridge CFStringRef)(label),NULL);
        }
        ABRecordSetValue(personRecord, kABPersonPhoneProperty, changedPhoneNumbers, nil);
        ABAddressBookAddRecord(self.addressBook, personRecord, nil);
    }
    ABAddressBookSave(self.addressBook, nil);
    [indView stopAnimating];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Meu9Digito" message:@"Nono dígito removido com sucesso!" delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
    alert.tag = 2;
    [alert show];
    [btn setEnabled:YES];
}

- (BOOL)testLabels:(NSString *)label {
    for (NSString *lbl in self.labelsToLookFor) {
        if ([lbl isEqualToString:label]) {
            return true;
        }
    }
    return false;
}

- (BOOL)testPhone:(NSString *)testStr {
    if ([testStr isEqualToString:@"6"] || [testStr isEqualToString:@"7"] ||
        [testStr isEqualToString:@"8"] || [testStr isEqualToString:@"9"]) {
        return true;
    } else {
        return false;
    }
}

- (BOOL)testDDD:(NSString *)testStr {
    NSRange r;
    for (NSString *ddd in self.statesArray) {
        r = [testStr rangeOfString:ddd];
        if (r.length > 0) {
            return true;
        }
    }
    return false;
}

#pragma -mark Alert View

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag == 1) {
        if (buttonIndex == alertView.cancelButtonIndex) {
            [txt setText:@"Nono dígito adicionado! Se gostou do app, entre em contato com o desenvolvedor através do email: lfelipeas@gmail.com! Obrigado!"];
            [[NSUserDefaults standardUserDefaults] setBool:TRUE forKey:@"9Added"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            [btn setTitle:@"Remover" forState:UIControlStateNormal];
        }
    }
    if (alertView.tag == 2) {
        if (buttonIndex == alertView.cancelButtonIndex) {
            [txt setText:@"Nono dígito removido! Se gostou do app, entre em contato com o desenvolvedor através do email: lfelipeas@gmail.com! Obrigado!"];
            [[NSUserDefaults standardUserDefaults] setBool:FALSE forKey:@"9Added"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            [btn setTitle:@"Adicionar" forState:UIControlStateNormal];
        }
    }
    if (alertView.tag == 3) {
        if (buttonIndex != alertView.cancelButtonIndex) {
            [indView startAnimating];
            [self remove9digit];
        }
    }
}

@end
