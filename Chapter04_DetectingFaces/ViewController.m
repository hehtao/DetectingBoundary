
#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <CoreVideo/CoreVideo.h>
#import <CoreMedia/CoreMedia.h>
#import <opencv2/highgui/ios.h>
#import <TesseractOCRiOS/TesseractOCR/TesseractOCR.h>

@interface ViewController ()<AVCaptureVideoDataOutputSampleBufferDelegate>
@property (nonatomic, strong) AVCaptureSession          *captureSession;
@property (nonatomic, strong) UIImageView               *centerImageView;  //大的imageView
//@property (nonatomic, strong) CALayer                   *customLayer;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *prevLayer;
@property(nonatomic,strong) UIImageView                 *cutImageView;
@property(nonatomic,strong) UIImageView                 *selectedImageView;

@property(nonatomic,strong) CAShapeLayer                *topLineLayer;
@property(nonatomic,strong) CAShapeLayer                *rightLineLayer;
@property(nonatomic,strong) CAShapeLayer                *leftLineLayer;
@property(nonatomic,strong) CAShapeLayer                *bottomLineLayer;
@end

@implementation ViewController


CGFloat scale;
CGSize size ;
CGFloat imageWidth ;
CGFloat imageHeight ;
const float ration = 85.6/54.f;

NSInteger thresholdMin = 140;

CGColor *lineColor = [UIColor redColor].CGColor;
CGFloat lineWidth  = 5.f;

- (void)viewDidLoad{
    [super viewDidLoad];
    [self initCapture];
    scale = [UIScreen mainScreen].scale;
}

-(void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    NSLog(@"Size: %@",NSStringFromCGSize(size));
}

-(BOOL)shouldAutorotate{
    return YES;
}

-(UIInterfaceOrientationMask)supportedInterfaceOrientations{
    return UIInterfaceOrientationMaskLandscapeLeft;
}

- (void)initCapture {
    size = [UIScreen mainScreen].bounds.size;
    imageWidth = size.height / 2.f;
    imageHeight = imageWidth / ration;
    self.cutImageView = [[UIImageView alloc] initWithFrame:CGRectMake(10, 10, 300, 100)];

    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    NSError *inputDeviceError;
    AVCaptureDeviceInput *captureInput = [AVCaptureDeviceInput deviceInputWithDevice:device  error:&inputDeviceError];
    if (inputDeviceError) return;
    
    AVCaptureVideoDataOutput *captureOutput = [[AVCaptureVideoDataOutput alloc]  init];
    captureOutput.alwaysDiscardsLateVideoFrames = YES;
    captureOutput.minFrameDuration = CMTimeMake(1, 30); // 定义视频录入帧率 30帧
    dispatch_queue_t queue = dispatch_queue_create("cameraQueue", NULL);
    [captureOutput setSampleBufferDelegate:self queue:queue];
    NSString* key = (NSString*)kCVPixelBufferPixelFormatTypeKey;
    NSNumber* value = [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA];
    NSDictionary* videoSettings = [NSDictionary dictionaryWithObject:value forKey:key];
    [captureOutput setVideoSettings:videoSettings];
    self.captureSession = [[AVCaptureSession alloc] init];
    [self.captureSession addInput:captureInput];
    [self.captureSession addOutput:captureOutput];
    [self.captureSession startRunning];
    
    self.centerImageView = [[UIImageView alloc] init];
    self.centerImageView.backgroundColor = [UIColor clearColor];
    CGSize size = [UIScreen mainScreen].bounds.size;
    CGFloat imageWidth = size.height / 2.f;
    CGFloat imageHeight = imageWidth / ration;
    self.centerImageView.frame = CGRectMake(0, 0, size.height, size.width);
    [self.view addSubview:self.centerImageView];
    [self.view addSubview:self.cutImageView];
    
    self.selectedImageView = [[UIImageView alloc] init];
    self.selectedImageView.backgroundColor = [UIColor clearColor];
    self.selectedImageView.frame = CGRectMake(( size.height - imageHeight)/2.f -64 , size.width/4.f  ,imageWidth, imageHeight);
    [self.view addSubview:self.selectedImageView];
    
    [self drawRightangleAtView:self.selectedImageView ];
    
    UIButton *back = [[UIButton alloc]init];
    [back setTitle:@"Back" forState:UIControlStateNormal];
    [back setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [back sizeToFit];
    CGRect frame = self.view.bounds;
    frame = back.frame;
    frame.origin.y = 15;
    frame.origin.x = 15;
    back.frame = frame;
    [self.view addSubview:back];
    [back addTarget:self action:@selector(back:) forControlEvents:UIControlEventTouchUpInside];
    
    NSTimer *time = [NSTimer timerWithTimeInterval:0.5 target:self selector:@selector(detectFromOutputDevice) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:time forMode:NSRunLoopCommonModes];
}

-(void)drawRightangleAtView:(UIView *)view{
    CGFloat lineLength = imageHeight/4.f;
    [self drawLineAtView:self.selectedImageView
                   Begin:CGPointMake(0, lineLength)
                     end:CGPointZero];
    [self drawLineAtView:self.selectedImageView
                   Begin:CGPointZero
                     end:CGPointMake(lineLength, 0)];
    [self drawLineAtView:self.selectedImageView
                   Begin:CGPointMake(imageWidth - lineLength, 0)
                     end:CGPointMake(imageWidth, 0)];
    [self drawLineAtView:self.selectedImageView
                   Begin:CGPointMake(imageWidth, 0)
                     end:CGPointMake(imageWidth, lineLength)];
    [self drawLineAtView:self.selectedImageView
                   Begin:CGPointMake(imageWidth, imageHeight - lineLength)
                     end:CGPointMake(imageWidth, imageHeight)];
    [self drawLineAtView:self.selectedImageView
                   Begin:CGPointMake(imageWidth, imageHeight)
                     end:CGPointMake(imageWidth - lineLength, imageHeight)];
    [self drawLineAtView:self.selectedImageView
                   Begin:CGPointMake(lineLength, imageHeight)
                     end:CGPointMake(0, imageHeight)];
    [self drawLineAtView:self.selectedImageView
                   Begin:CGPointMake(0, imageHeight)
                     end:CGPointMake(0, imageHeight - lineLength)];
}


-(void)drawLineAtView:(UIView *)view Begin:(CGPoint)beginPoint end:(CGPoint)endPoint {
    UIBezierPath *bPath = [[UIBezierPath alloc] init];
    [bPath moveToPoint:beginPoint];
    [bPath addLineToPoint:endPoint];
    CAShapeLayer *rectLayer = [CAShapeLayer layer];
    rectLayer.path          = bPath.CGPath;
    rectLayer.lineWidth     = lineWidth;
    rectLayer.lineCap       = @"round";
    rectLayer.strokeColor   = lineColor;
    rectLayer.fillColor     = [UIColor clearColor].CGColor;
    [view.layer addSublayer:rectLayer];
}

-(void)back:(id)sender{
    [self dismissViewControllerAnimated:true completion:nil];
}

// 各种中间变量
CGRect cutBottomLineRect;
CGRect cutRightLineRect;
CGRect cutTopLineRect;
CGRect cutLeftLineRect;
CGFloat cutRatio = 0.2f; // 定义边框图像截取比例

UIImage *cutBottomImage;
UIImage *cutRightImage;
UIImage *cutTopImage;
UIImage *cutLeftImage;
CGImageRef newImage;
size_t width;
size_t height;

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection{
    
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CVPixelBufferLockBaseAddress(imageBuffer,0);
    uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddress(imageBuffer);
    size_t bytesPerRow   = CVPixelBufferGetBytesPerRow(imageBuffer);
    width                = CVPixelBufferGetWidth(imageBuffer);   // 1920  6S
    height               = CVPixelBufferGetHeight(imageBuffer); //  1080
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef newContext = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace,                                                  kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    
    newImage = CGBitmapContextCreateImage(newContext);
    CGContextRelease(newContext);
    CGColorSpaceRelease(colorSpace);
    
    id object = (__bridge id)newImage;
//    [self.customLayer performSelectorOnMainThread:@selector(setContents:) withObject: object waitUntilDone:YES];
    UIImage *image= [UIImage imageWithCGImage:newImage scale:scale orientation:UIImageOrientationDown];
    CGImageRelease(newImage);
    //截取相框 20% 的宽度,上下各浮动10% 用作边界侦测
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
         cutBottomLineRect = CGRectMake(width / 4.f ,
                                        height / 4.f - cutRatio * height/2.f,
                                        width/ 2.f ,
                                        cutRatio * height/2.f);
        
         cutRightLineRect  = CGRectMake(width / 4.f  - cutRatio * width /2.f / 2.f,
                                        height / 4.f,
                                        cutRatio * width /2.f ,
                                        height / 2.f);
        
         cutTopLineRect    = CGRectMake(width / 4.f,
                                        height * 3.f / 4.f - cutRatio * height /2.f / 2.f,
                                        width/ 2.f ,
                                        cutRatio * height/2.f);
        
         cutLeftLineRect   = CGRectMake(width * 3.f / 4.f - cutRatio * width /2.f / 2.f,
                                        height / 4.f,
                                        cutRatio * width /2.f ,
                                        height / 2.f);
    });
    
    CGImageRef cutBottomImageRef = CGImageCreateWithImageInRect(newImage, cutBottomLineRect);
    CGImageRef cutRightImageRef  = CGImageCreateWithImageInRect(newImage, cutRightLineRect);
    CGImageRef cutTopImageRef    = CGImageCreateWithImageInRect(newImage, cutTopLineRect);
    CGImageRef cutLeftImageRef   = CGImageCreateWithImageInRect(newImage, cutLeftLineRect);
    
    cutBottomImage = [UIImage imageWithCGImage:cutBottomImageRef];
    cutRightImage  = [UIImage imageWithCGImage:cutRightImageRef];
    cutTopImage    = [UIImage imageWithCGImage:cutTopImageRef];
    cutLeftImage   = [UIImage imageWithCGImage:cutLeftImageRef];
    
    CGImageRelease(cutLeftImageRef);
    CGImageRelease(cutTopImageRef);
    CGImageRelease(cutRightImageRef);
    CGImageRelease(cutBottomImageRef);
    
    if (thresholdMin < 190 ) {
        thresholdMin += 2;
    }else{
        thresholdMin = 160;
    }
    
    [self.centerImageView performSelectorOnMainThread:@selector(setImage:) withObject:image waitUntilDone:YES];
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);

}


-(void)detectFromOutputDevice{
    int bottomAlignment = detectionImageBoundary(cutBottomImage);
    int rightAlignment  = detectionImageBoundary(cutRightImage);
    int topAlignment    = detectionImageBoundary(cutTopImage);
    int leftAlignment   = detectionImageBoundary(cutLeftImage);
    
    if (leftAlignment) {
        if (!self.leftLineLayer.superlayer) {
            [self.selectedImageView.layer performSelectorOnMainThread:@selector(addSublayer:) withObject:self.leftLineLayer waitUntilDone:YES];
        }
    }else{
        if (self.leftLineLayer.superlayer) {
            [self.leftLineLayer performSelectorOnMainThread:@selector(removeFromSuperlayer) withObject:nil waitUntilDone:YES];
        }
    }

    if (bottomAlignment) {
        if (!self.bottomLineLayer.superlayer) {
            [self.selectedImageView.layer performSelectorOnMainThread:@selector(addSublayer:) withObject:self.bottomLineLayer waitUntilDone:YES];
        }
    }else{
        if (self.bottomLineLayer.superlayer) {
            [self.bottomLineLayer performSelectorOnMainThread:@selector(removeFromSuperlayer) withObject:nil waitUntilDone:YES];
        }
    }
    
    if (rightAlignment) {
        if (!self.rightLineLayer.superlayer) {
            [self.selectedImageView.layer performSelectorOnMainThread:@selector(addSublayer:) withObject:self.rightLineLayer waitUntilDone:YES];;
        }
    }else{
        if (self.rightLineLayer.superlayer) {
            [self.rightLineLayer performSelectorOnMainThread:@selector(removeFromSuperlayer) withObject:nil waitUntilDone:YES];
        }
    }

    if (topAlignment) {
        if (!self.topLineLayer.superlayer) {
             [self.selectedImageView.layer performSelectorOnMainThread:@selector(addSublayer:) withObject:self.topLineLayer waitUntilDone:YES ];
        }
    }else{
        if (self.topLineLayer.superlayer) {
            [self.topLineLayer performSelectorOnMainThread:@selector(removeFromSuperlayer) withObject:nil waitUntilDone:YES];
        }
    }

    if (bottomAlignment + rightAlignment + topAlignment + leftAlignment >= 3) {
        CGImageRef cardImageRef = CGImageCreateWithImageInRect(newImage, CGRectMake(width / 4.f, height / 4.f, width / 2.f, height / 2.f));
        UIImage *cardImage = [UIImage imageWithCGImage:cardImageRef];
        CGImageRelease(cardImageRef);
        [self tesseractRecognizeImage:scanCard(cardImage) compleate:^(NSString *text) {
            if (self.block) {
                self.block(text);
            }
        }];
        [self performSelectorOnMainThread:@selector(dismissModalViewControllerAnimated:) withObject:@(YES) waitUntilDone:YES];
    }
}


using namespace cv;
using namespace std;
double  minThreshold = 10;
double  ratioThreshold = 3;

int detectionImageBoundary(UIImage *image){
    
    int result = 0;
    Mat sourceMatImage;
    UIImageToMat(image, sourceMatImage);
    blur(sourceMatImage, sourceMatImage, cv::Size(3,3));
    cvtColor(sourceMatImage, sourceMatImage, CV_BGR2GRAY);
    // 二值化
    adaptiveThreshold(sourceMatImage, sourceMatImage, 255, ADAPTIVE_THRESH_GAUSSIAN_C, THRESH_BINARY, 41, 0);
//    threshold(sourceMatImage, sourceMatImage, 165 , 255, CV_THRESH_BINARY); //下边界动态改变增强环境适应性
    // 检测边界
    Canny(sourceMatImage, sourceMatImage, minThreshold * ratioThreshold, minThreshold);
    // 获取轮廓
    std::vector<std::vector<cv::Point>> contours;
    findContours(sourceMatImage, contours, CV_RETR_EXTERNAL, CV_CHAIN_APPROX_NONE);
    
    /*************重新绘制轮廓*************/
    Mat dstImg(sourceMatImage.size(), CV_8UC3, Scalar::all(0));     // 初始化一个8UC3的纯黑图像
    // 用于存放轮廓折线点集
    std::vector<std::vector<cv::Point>> contours_poly(contours.size());
    std::vector<std::vector<cv::Point>>::const_iterator itContours = contours.begin();
    std::vector<std::vector<cv::Point>>::const_iterator itContourEnd = contours.end();
    // ++i 比 i++ 少一次内存写入,性能更高
    for (int i=0 ; itContours != itContourEnd; ++itContours,++i) {
        approxPolyDP(Mat(contours[i]), contours_poly[i], 30, true);
    }
    // 绘制处理后的轮廓,一次性绘制
    drawContours(dstImg, contours_poly, -1, Scalar(208, 19, 29), 3, 8);
    cvtColor(dstImg, dstImg, CV_BGR2GRAY);
    
    std::vector<std::vector<cv::Point>> drawContours;
    findContours(dstImg, drawContours, CV_RETR_EXTERNAL, CV_CHAIN_APPROX_NONE);
    std::vector<std::vector<cv::Point>>::const_iterator drawContourItem = drawContours.begin();
    std::vector<std::vector<cv::Point>>::const_iterator drawContourEnd = drawContours.end();
    for (; drawContourItem != drawContourEnd; ++ drawContourItem) {
        cv::Rect  rect =  cv::boundingRect(* drawContourItem);
        // 此处简单的以长宽比做边界识别条件,若能结合曲线曲率可能会更高
        result = (rect.width/rect.height > 10.f | rect.height/rect.width > 10.f)?1:0;
    }
    return result;
}

/*如果C++ 基础不够,可以使用 for 循环
 *    for (int i = 0; i < contours.size(); i ++) {
 *        approxPolyDP(contours[i] , contours_poly[i], 5, YES);
 *    }
 */

//扫描身份证图片，并进行预处理，定位号码区域图片并返回
UIImage* scanCard(UIImage *image) {
    
    cv::Mat resultImage;
    UIImageToMat(image, resultImage);
    cvtColor(resultImage, resultImage, COLOR_BGR2GRAY);
    threshold(resultImage, resultImage, 100, 255, CV_THRESH_BINARY);
    //adaptiveThreshold(resultImage, resultImage, 255, ADAPTIVE_THRESH_MEAN_C, THRESH_BINARY, 41, 0);
    
    //获取制定样式内核,尺寸过小拖慢erode速度,过大会导致腐蚀过于严重 ,影响识别
    Mat erodeElement = getStructuringElement(cv::MORPH_RECT, cv::Size(26,26));
    erode(resultImage, resultImage, erodeElement);
 
    //定义一个容器来存储所有检测到的轮廊
    vector<std::vector<cv::Point>> contours;
    findContours(resultImage, contours, CV_RETR_TREE, CV_CHAIN_APPROX_SIMPLE, cvPoint(0, 0));
    //cv::drawContours(resultImage, contours, -1, cv::Scalar(255),4);
    
    //    vector<cv::Rect> rects;
    cv::Rect numberRect = cv::Rect(0,0,0,0);
    // 使用STL迭代器遍历
    std::vector<std::vector<cv::Point>>::const_iterator itContours = contours.begin();
    std::vector<std::vector<cv::Point>>::const_iterator itContourEnd = contours.end();
    for ( ; itContours != itContourEnd; ++itContours) { // ++i 比 i++ 少一次内存写入,性能更高
        cv::Rect rect = cv::boundingRect(*itContours);
        /* 根据需要的轮廓特征,制定轮廓判断标准
         * 身份证号码部分特征: 1.宽度大于 0
         *                 2.宽度大于高度的5倍
         */
        if (rect.width > numberRect.width && rect.width > rect.height * 5) {
            numberRect = rect;
        }
    }
    
    //身份证号码定位失败
    if (numberRect.width == 0 || numberRect.height == 0) {
        return nil;
    }
    
    //定位成功成功，去原图截取身份证号码区域，并转换成灰度图、进行二值化处理
    Mat matImage;
    UIImageToMat(image, matImage);
    resultImage = matImage(numberRect);
    cvtColor(resultImage, resultImage, cv::COLOR_BGR2GRAY);
    cv::threshold(resultImage, resultImage, 80, 255, CV_THRESH_BINARY);
    UIImage *numberImage = MatToUIImage(resultImage);
    return numberImage;
}

//利用TesseractOCR识别文字
- (void)tesseractRecognizeImage:(UIImage *)image compleate:(void(^)(NSString *text))compleate{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        
        G8Tesseract *tesseract = [[G8Tesseract alloc] initWithLanguage:@"eng"];
        tesseract.image = [image g8_blackAndWhite];
        tesseract.image = image;
        // Start the recognition
        [tesseract recognize];
        //执行回调
        dispatch_async(dispatch_get_main_queue(), ^{
            compleate(tesseract.recognizedText.length > 0 ? tesseract.recognizedText : @"");
        });
    });
}

-(CAShapeLayer *)topLineLayer{
    if (_topLineLayer == nil) {
        _topLineLayer = [self creatLineLayerLineBegin:CGPointMake(imageHeight / 4.f, 0) endPoint:CGPointMake(imageWidth -imageHeight /4.f, 0)];
    }
    return _topLineLayer;
}

-(CAShapeLayer *)rightLineLayer{
    if (_rightLineLayer == nil) {
        _rightLineLayer = [self creatLineLayerLineBegin:CGPointMake(imageWidth, imageHeight/4.f) endPoint:CGPointMake(imageWidth, imageHeight * 3.f /4.f)];
    }
    return _rightLineLayer;
}

-(CAShapeLayer *)bottomLineLayer{
    if (_bottomLineLayer == nil) {
        _bottomLineLayer = [self creatLineLayerLineBegin:CGPointMake(imageWidth - imageHeight / 4.f, imageHeight)  endPoint:CGPointMake(imageHeight / 4.f, imageHeight)];
    }
    return _bottomLineLayer;
}

-(CAShapeLayer *)leftLineLayer{
    if (_leftLineLayer == nil) {
        _leftLineLayer = [self creatLineLayerLineBegin:CGPointMake(0, imageHeight * 3.f/4.f) endPoint:CGPointMake(0, imageHeight / 4.f)];
    }
    return _leftLineLayer;
}

-(CAShapeLayer *)creatLineLayerLineBegin:(CGPoint)beginPoint  endPoint:(CGPoint) endPoint{
    UIBezierPath *bPath = [[UIBezierPath alloc] init];
    [bPath moveToPoint:beginPoint];
    [bPath addLineToPoint:endPoint];
    CAShapeLayer *rectLayer = [CAShapeLayer layer];
    rectLayer.path          = bPath.CGPath;
    rectLayer.lineWidth     = lineWidth;
    rectLayer.lineCap       = @"round";
    rectLayer.strokeColor   = lineColor;
    rectLayer.fillColor     = [UIColor clearColor].CGColor;
    return rectLayer;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
