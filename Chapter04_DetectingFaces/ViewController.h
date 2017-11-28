
#import <UIKit/UIKit.h>

@interface ViewController : UIViewController
@property(nonatomic,copy) void(^block)(NSString *string);

/**
 Description   识别图片

 @param image 识别对象
 @param compleate 完成回调,识别失败返回 @""
 */
- (void)tesseractRecognizeImage:(UIImage *)image compleate:(void(^)(NSString *text))compleate;


/**
 侦测图片图形边界

 @param image 侦测对象
 @return 侦测结果, NO/YES 未/侦测带有效边界
 */
int detectionImageBoundary(UIImage *image);


/**
 扫描获取侦测对象中的目标位置

 @param image 扫描对象
 @return 目标图像
 */
UIImage* scanCard(UIImage *image);

@end
