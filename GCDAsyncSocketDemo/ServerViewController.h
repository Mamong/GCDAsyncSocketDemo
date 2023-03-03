//
//  ServerViewController.h
//  GCDAsyncSocketDemo
//
//  Created by tryao on 2022/6/15.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ServerViewController : UIViewController<UITableViewDelegate,UITableViewDataSource>

@property(nonatomic, weak) IBOutlet UITextField *portField;
@property(nonatomic, weak) IBOutlet UILabel *statusLabel;
@property(nonatomic, weak) IBOutlet UIImageView *qrcodeImageView;
@property(nonatomic, weak) IBOutlet UITableView *filesTableView;

-(IBAction)startListen:(id)sender;
- (IBAction)disconnect:(id)sender;
- (IBAction)unbind:(id)sender;

//-(IBAction)sendFiles;
@end

NS_ASSUME_NONNULL_END
