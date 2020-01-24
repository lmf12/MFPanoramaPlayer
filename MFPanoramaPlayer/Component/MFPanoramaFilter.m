//
//  MFPanoramaFilter.m
//  MFPanoramaPlayerDemo
//
//  Created by Lyman Li on 2020/1/23.
//  Copyright © 2020 Lyman Li. All rights reserved.
//

#import "MFShaderHelper.h"

#import "MFPanoramaFilter.h"

@import OpenGLES;

@interface MFPanoramaFilter ()

@property (nonatomic, strong) EAGLContext *context;
@property (nonatomic, assign) GLuint yuvConversionProgram;
@property (nonatomic, assign) GLuint renderProgram;

@property (nonatomic, assign) CVOpenGLESTextureCacheRef textureCache;

@property (nonatomic, assign) CVOpenGLESTextureRef luminanceTexture;
@property (nonatomic, assign) CVOpenGLESTextureRef chrominanceTexture;
@property (nonatomic, assign) CVOpenGLESTextureRef renderTexture;

@property (nonatomic, assign) CVPixelBufferRef resultPixelBuffer;

@end

@implementation MFPanoramaFilter

- (void)dealloc {
    if (_pixelBuffer) {
        CVPixelBufferRelease(_pixelBuffer);
    }
    if (_resultPixelBuffer) {
        CVPixelBufferRelease(_resultPixelBuffer);
    }
    if (_yuvConversionProgram) {
        glDeleteProgram(_yuvConversionProgram);
    }
    if (_renderProgram) {
        glDeleteProgram(_renderProgram);
    }
    if (_luminanceTexture) {
        CFRelease(_luminanceTexture);
    }
    if (_chrominanceTexture) {
        CFRelease(_chrominanceTexture);
    }
    if (_renderTexture) {
        CFRelease(_renderTexture);
    }
    if (_textureCache) {
        CFRelease(_textureCache);
    }
    if (_context) {
        [EAGLContext setCurrentContext:nil];
    }
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self commonInit];
    }
    return self;
}

#pragma mark - Accessors

- (void)setPixelBuffer:(CVPixelBufferRef)pixelBuffer {
    if (_pixelBuffer &&
        pixelBuffer &&
        CFEqual(pixelBuffer, _pixelBuffer)) {
        return;
    }
    if (pixelBuffer) {
        CVPixelBufferRetain(pixelBuffer);
    }
    if (_pixelBuffer) {
        CVPixelBufferRelease(_pixelBuffer);
    }
    _pixelBuffer = pixelBuffer;
}

- (void)setResultPixelBuffer:(CVPixelBufferRef)resultPixelBuffer {
    if (_resultPixelBuffer &&
        resultPixelBuffer &&
        CFEqual(resultPixelBuffer, _resultPixelBuffer)) {
        return;
    }
    if (resultPixelBuffer) {
        CVPixelBufferRetain(resultPixelBuffer);
    }
    if (_resultPixelBuffer) {
        CVPixelBufferRelease(_resultPixelBuffer);
    }
    _resultPixelBuffer = resultPixelBuffer;
}

- (CVOpenGLESTextureCacheRef)textureCache {
    if (!_textureCache) {
        EAGLContext *context = self.context;
        CVReturn status = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, nil, context, nil, &_textureCache);
        if (status != kCVReturnSuccess) {
            NSLog(@"Can't create textureCache");
        }
    }
    return _textureCache;
}

- (void)setLuminanceTexture:(CVOpenGLESTextureRef)luminanceTexture {
    if (_luminanceTexture &&
        luminanceTexture &&
        CFEqual(luminanceTexture, _luminanceTexture)) {
        return;
    }
    if (luminanceTexture) {
        CFRetain(luminanceTexture);
    }
    if (_luminanceTexture) {
        CFRelease(_luminanceTexture);
    }
    _luminanceTexture = luminanceTexture;
}

- (void)setChrominanceTexture:(CVOpenGLESTextureRef)chrominanceTexture {
    if (_chrominanceTexture &&
        chrominanceTexture &&
        CFEqual(chrominanceTexture, _chrominanceTexture)) {
        return;
    }
    if (chrominanceTexture) {
        CFRetain(chrominanceTexture);
    }
    if (_chrominanceTexture) {
        CFRelease(_chrominanceTexture);
    }
    _chrominanceTexture = chrominanceTexture;
}

- (void)setRenderTexture:(CVOpenGLESTextureRef)renderTexture {
    if (_renderTexture &&
        renderTexture &&
        CFEqual(renderTexture, _renderTexture)) {
        return;
    }
    if (renderTexture) {
        CFRetain(renderTexture);
    }
    if (_renderTexture) {
        CFRelease(_renderTexture);
    }
    _renderTexture = renderTexture;
}

#pragma mark - Public

- (CVPixelBufferRef)outputPixelBuffer {
    if (!self.pixelBuffer) {
        return nil;
    }
    [self startRendering];
    return self.resultPixelBuffer;
}

#pragma mark - Private

- (void)commonInit {
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    [EAGLContext setCurrentContext:self.context];
    [self setupYUVConversionProgram];
    [self setupRenderProgram];
}

- (void)setupYUVConversionProgram {
    self.yuvConversionProgram = [MFShaderHelper programWithShaderName:@"YUVConversion"];
}

- (void)setupRenderProgram {
    self.renderProgram = [MFShaderHelper programWithShaderName:@"Panorama"];
}

/// 创建输出的 pixelBuffer
- (CVPixelBufferRef)createPixelBufferWithSize:(CGSize)size {
    CVPixelBufferRef pixelBuffer;
    NSDictionary *pixelBufferAttributes = @{(id)kCVPixelBufferIOSurfacePropertiesKey: @{}};
    CVReturn status = CVPixelBufferCreate(nil,
                                          size.width,
                                          size.height,
                                          kCVPixelFormatType_32BGRA,
                                          (__bridge CFDictionaryRef _Nullable)(pixelBufferAttributes),
                                          &pixelBuffer);
    if (status != kCVReturnSuccess) {
        NSLog(@"Can't create pixelbuffer");
    }
    return pixelBuffer;
}

/// YUV 格式的 PixelBuffer 转化为纹理
- (GLuint)convertYUVPixelBufferToTexture:(CVPixelBufferRef)pixelBuffer {
    if (!pixelBuffer) {
        return 0;
    }
    
    float vertices[] = {
        -1.0f, -1.0f, 0.0f, 0.0f, 0.0f,
        -1.0f, 1.0f, 0.0f, 0.0f, 1.0f,
        1.0f, -1.0f, 0.0f, 1.0f, 0.0f,
        1.0f, 1.0f, 0.0f, 1.0f, 1.0f,
    };
    
    CGSize textureSize = [self inputSize];

    [EAGLContext setCurrentContext:self.context];
    
    GLuint frameBuffer;
    GLuint textureID;
    
    // FBO
    glGenFramebuffers(1, &frameBuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, frameBuffer);
    
    // texture
    glGenTextures(1, &textureID);
    glBindTexture(GL_TEXTURE_2D, textureID);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, textureSize.width, textureSize.height, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    
    
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, textureID, 0);
    
    glViewport(0, 0, textureSize.width, textureSize.height);
    
    // program
    glUseProgram(self.yuvConversionProgram);
    
    // texture
    CVOpenGLESTextureRef luminanceTextureRef = nil;
    CVOpenGLESTextureRef chrominanceTextureRef = nil;

    CVReturn status = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                                   self.textureCache,
                                                                   pixelBuffer,
                                                                   nil,
                                                                   GL_TEXTURE_2D,
                                                                   GL_LUMINANCE,
                                                                   textureSize.width,
                                                                   textureSize.height,
                                                                   GL_LUMINANCE,
                                                                   GL_UNSIGNED_BYTE,
                                                                   0,
                                                                   &luminanceTextureRef);
    if (status != kCVReturnSuccess) {
        NSLog(@"Can't create luminanceTexture");
    }
    
    status = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                          self.textureCache,
                                                          pixelBuffer,
                                                          nil,
                                                          GL_TEXTURE_2D,
                                                          GL_LUMINANCE_ALPHA,
                                                          textureSize.width / 2,
                                                          textureSize.height / 2,
                                                          GL_LUMINANCE_ALPHA,
                                                          GL_UNSIGNED_BYTE,
                                                          1,
                                                          &chrominanceTextureRef);
    
    if (status != kCVReturnSuccess) {
        NSLog(@"Can't create chrominanceTexture");
    }
    
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, CVOpenGLESTextureGetName(luminanceTextureRef));
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glUniform1i(glGetUniformLocation(self.yuvConversionProgram, "luminanceTexture"), 0);
    
    glActiveTexture(GL_TEXTURE1);
    glBindTexture(GL_TEXTURE_2D, CVOpenGLESTextureGetName(chrominanceTextureRef));
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glUniform1i(glGetUniformLocation(self.yuvConversionProgram, "chrominanceTexture"), 1);
    
    GLfloat kXDXPreViewColorConversion601FullRange[] = {
        1.0,    1.0,    1.0,
        0.0,    -0.343, 1.765,
        1.4,    -0.711, 0.0,
    };
    
    GLuint yuvConversionMatrixUniform = glGetUniformLocation(self.yuvConversionProgram, "colorConversionMatrix");
    glUniformMatrix3fv(yuvConversionMatrixUniform, 1, GL_FALSE, kXDXPreViewColorConversion601FullRange);
    
    // VBO
    GLuint VBO;
    glGenBuffers(1, &VBO);
    glBindBuffer(GL_ARRAY_BUFFER, VBO);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
    
    GLuint positionSlot = glGetAttribLocation(self.yuvConversionProgram, "position");
    glEnableVertexAttribArray(positionSlot);
    glVertexAttribPointer(positionSlot, 3, GL_FLOAT, GL_FALSE, 5 * sizeof(float), (void*)0);
    
    GLuint textureSlot = glGetAttribLocation(self.yuvConversionProgram, "inputTextureCoordinate");
    glEnableVertexAttribArray(textureSlot);
    glVertexAttribPointer(textureSlot, 2, GL_FLOAT, GL_FALSE, 5 * sizeof(float), (void*)(3* sizeof(float)));
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    glDeleteFramebuffers(1, &frameBuffer);
    glDeleteBuffers(1, &VBO);
    
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    
    glFlush();
    
    self.luminanceTexture = luminanceTextureRef;
    self.chrominanceTexture = chrominanceTextureRef;
    
    CFRelease(luminanceTextureRef);
    CFRelease(chrominanceTextureRef);
    
    return textureID;
}

/// RBG 格式的 PixelBuffer 转化为纹理
- (GLuint)convertRGBPixelBufferToTexture:(CVPixelBufferRef)pixelBuffer {
    if (!pixelBuffer) {
        return 0;
    }
    
    CGSize textureSize = [self inputSize];
    CVOpenGLESTextureRef texture = nil;
    
    CVReturn status = CVOpenGLESTextureCacheCreateTextureFromImage(nil,
                                                                   self.textureCache,
                                                                   pixelBuffer,
                                                                   nil,
                                                                   GL_TEXTURE_2D,
                                                                   GL_RGBA,
                                                                   textureSize.width,
                                                                   textureSize.height,
                                                                   GL_BGRA,
                                                                   GL_UNSIGNED_BYTE,
                                                                   0,
                                                                   &texture);
    
    if (status != kCVReturnSuccess) {
        NSLog(@"Can't create texture");
    }
    
    self.renderTexture = texture;
    CFRelease(texture);
    return CVOpenGLESTextureGetName(texture);
}

/// 开始渲染视频图像
- (void)startRendering {
    float vertices[] = {
        -1.0f, -1.0f, 0.0f, 0.0f, 0.0f,
        -1.0f, 1.0f, 0.0f, 0.0f, 1.0f,
        1.0f, -1.0f, 0.0f, 1.0f, 0.0f,
        1.0f, 1.0f, 0.0f, 1.0f, 1.0f,
    };
    
    [EAGLContext setCurrentContext:self.context];
    
    GLuint inputTextureID = [self convertYUVPixelBufferToTexture:self.pixelBuffer];
    CVPixelBufferRef outputPixelBuffer = [self createPixelBufferWithSize:[self inputSize]];
    GLuint outputTextureID = [self convertRGBPixelBufferToTexture:outputPixelBuffer];
    
    GLuint frameBuffer;
    
    // FBO
    glGenFramebuffers(1, &frameBuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, frameBuffer);
        
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, outputTextureID, 0);
    
    glViewport(0, 0, [self inputSize].width, [self inputSize].height);
    
    // program
    glUseProgram(self.renderProgram);
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, inputTextureID);
    glUniform1i(glGetUniformLocation(self.renderProgram, "renderTexture"), 0);
    
    // VBO
    GLuint VBO;
    glGenBuffers(1, &VBO);
    glBindBuffer(GL_ARRAY_BUFFER, VBO);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
    
    GLuint positionSlot = glGetAttribLocation(self.yuvConversionProgram, "position");
    glEnableVertexAttribArray(positionSlot);
    glVertexAttribPointer(positionSlot, 3, GL_FLOAT, GL_FALSE, 5 * sizeof(float), (void*)0);
    
    GLuint textureSlot = glGetAttribLocation(self.yuvConversionProgram, "inputTextureCoordinate");
    glEnableVertexAttribArray(textureSlot);
    glVertexAttribPointer(textureSlot, 2, GL_FLOAT, GL_FALSE, 5 * sizeof(float), (void*)(3* sizeof(float)));
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    glFlush();
 
    self.resultPixelBuffer = outputPixelBuffer;
    
    glDeleteFramebuffers(1, &frameBuffer);
    glDeleteBuffers(1, &VBO);
    glDeleteTextures(1, &inputTextureID);
    CVPixelBufferRelease(outputPixelBuffer);
    
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    glBindVertexArray(0);
}

- (CGSize)inputSize {
    return CGSizeMake(CVPixelBufferGetWidth(self.pixelBuffer),
                      CVPixelBufferGetHeight(self.pixelBuffer));
}

@end
