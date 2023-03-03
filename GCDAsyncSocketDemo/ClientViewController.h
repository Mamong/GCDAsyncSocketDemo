//
//  ClientViewController.h
//  GCDAsyncSocketDemo
//
//  Created by tryao on 2022/6/15.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ClientViewController : UIViewController<UITableViewDelegate,UITableViewDataSource>

@property(nonatomic, strong) NSString *dataSavePath;

@property (nonatomic, weak) IBOutlet UILabel *statusLabel;
@property(nonatomic, weak) IBOutlet UITableView *filesTableView;

- (IBAction)reconnect:(id)sender;
- (IBAction)disconnect:(id)sender;
- (IBAction)reset:(id)sender;

@end

NS_ASSUME_NONNULL_END
