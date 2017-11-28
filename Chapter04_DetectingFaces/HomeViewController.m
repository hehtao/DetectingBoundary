
#import "HomeViewController.h"
#import "ViewController.h"

@interface HomeViewController ()
@property(nonatomic,strong) UILabel  *label;
@end

@implementation HomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.label = [[UILabel alloc] initWithFrame:CGRectMake(10, 100, 300, 100)];
    self.label.backgroundColor = [UIColor blackColor];
    self.label.textColor = [UIColor whiteColor];
    [self.view addSubview:self.label];
    
    // Do any additional setup after loading the view.
}


-(BOOL)shouldAutorotate{
    return YES;
}
//-(UIInterfaceOrientationMask)supportedInterfaceOrientations{
//    return UIInterfaceOrientationMaskPortrait;
//}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    ViewController *vc = [ViewController new];
    vc.block = ^(NSString *string){
        self.label.text = string;
    };
    [vc setBlock:^(NSString *string) {
        self.label.text = string;
    }];
    [self presentViewController:[ViewController new] animated:YES completion:^{
        
    }];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
