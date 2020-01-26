//
//  MFPanoramaFilter.m
//  MFPanoramaPlayerDemo
//
//  Created by Lyman Li on 2020/1/23.
//  Copyright © 2020 Lyman Li. All rights reserved.
//

#import "MFShaderHelper.h"
#import "MFPixelBufferHelper.h"

#import "MFPanoramaFilter.h"

@import OpenGLES;

@interface MFPanoramaFilter ()

@property (nonatomic, strong) EAGLContext *context;
@property (nonatomic, assign) GLuint renderProgram;

@property (nonatomic, assign) CVPixelBufferRef resultPixelBuffer;

@property (nonatomic, strong) MFPixelBufferHelper *pixelBufferHelper;

@property (nonatomic, assign) float *vertices;
@property (nonatomic, assign) int *indices;
@property (nonatomic, assign) int verticesCount;
@property (nonatomic, assign) int indicesCount;

@end

@implementation MFPanoramaFilter

- (void)dealloc {
    if (_pixelBuffer) {
        CVPixelBufferRelease(_pixelBuffer);
    }
    if (_resultPixelBuffer) {
        CVPixelBufferRelease(_resultPixelBuffer);
    }
    if (_renderProgram) {
        glDeleteProgram(_renderProgram);
    }
    if (_context) {
        [EAGLContext setCurrentContext:nil];
    }
    if (_vertices) {
        free(_vertices);
    }
    if (_indices) {
        free(_indices);
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
    [self setupRenderProgram];
    self.pixelBufferHelper = [[MFPixelBufferHelper alloc] initWithContext:self.context];
    self.vertices = [self createVertices:&_verticesCount];
    self.indices = [self createIndices:&_indicesCount];
}

- (void)setupRenderProgram {
    self.renderProgram = [MFShaderHelper programWithShaderName:@"Panorama"];
}

/// 开始渲染视频图像
- (void)startRendering {
    [EAGLContext setCurrentContext:self.context];
    
    CGSize textureSize = [self inputSize];
    GLuint inputTextureID = [self.pixelBufferHelper convertYUVPixelBufferToTexture:self.pixelBuffer];
    CVPixelBufferRef outputPixelBuffer = [self.pixelBufferHelper createPixelBufferWithSize:textureSize];
    GLuint outputTextureID = [self.pixelBufferHelper convertRGBPixelBufferToTexture:outputPixelBuffer];
    
    // FBO
    GLuint frameBuffer;
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
    glBufferData(GL_ARRAY_BUFFER, sizeof(float) * self.verticesCount, self.vertices, GL_DYNAMIC_DRAW);
    
    // EBO
    GLuint EBO;
    glGenBuffers(1, &EBO);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, EBO);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(int) * self.indicesCount, self.indices, GL_DYNAMIC_DRAW);
    
    GLuint positionSlot = glGetAttribLocation(self.renderProgram, "position");
    glEnableVertexAttribArray(positionSlot);
    glVertexAttribPointer(positionSlot, 3, GL_FLOAT, GL_FALSE, 5 * sizeof(float), (void*)0);
    
    GLuint textureSlot = glGetAttribLocation(self.renderProgram, "inputTextureCoordinate");
    glEnableVertexAttribArray(textureSlot);
    glVertexAttribPointer(textureSlot, 2, GL_FLOAT, GL_FALSE, 5 * sizeof(float), (void*)(3* sizeof(float)));
    
    glDrawElements(GL_TRIANGLES, self.indicesCount, GL_UNSIGNED_INT, 0);
    
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

/// 创建顶点数组
- (float *)createVertices:(int *)count {
    float a[] = {-1.0f, -1.0f, 0.0f, 0.0f, 0.0f,
                 -1.0f, 1.0f, 0.0f, 0.0f, 1.0f,
                 1.0f, -1.0f, 0.0f, 1.0f, 0.0f,
                 1.0f, 1.0f, 0.0f, 1.0f, 1.0f,};
    
    float *vertices = malloc(sizeof(float) * 5 * 4);
    *count = 20;
    
    for (int i = 0; i < 20; ++i) {
        vertices[i] = a[i];
    }
    
    return vertices;
}

/// 创建索引数组
- (int *)createIndices:(int *)count {
    int a[] = {
        0, 1, 2,
        1, 2, 3
    };
    
    int *indices = malloc(sizeof(int) * 6);
    *count = 6;
    
    for (int i = 0; i < 6; ++i) {
        indices[i] = a[i];
    }
    
    return indices;
}

@end
