//
//  MFPanoramaFilter.m
//  MFPanoramaPlayerDemo
//
//  Created by Lyman Li on 2020/1/23.
//  Copyright © 2020 Lyman Li. All rights reserved.
//

#import <CoreMotion/CoreMotion.h>

#import "MFShaderHelper.h"
#import "MFPixelBufferHelper.h"

#import "CMAttitude+MFPanoramaPlayer.h"

#import "MFPanoramaFilter.h"

@import OpenGLES;
@import GLKit;

static NSInteger const kSizePerVertex = 5;  // 每个顶点的数据量大小

@interface MFPanoramaFilter ()

@property (nonatomic, strong) EAGLContext *context;
@property (nonatomic, assign) GLuint renderProgram;

@property (nonatomic, assign) CVPixelBufferRef resultPixelBuffer;

@property (nonatomic, strong) MFPixelBufferHelper *pixelBufferHelper;

@property (nonatomic, assign) float *vertices;
@property (nonatomic, assign) int *indices;
@property (nonatomic, assign) int verticesCount;
@property (nonatomic, assign) int indicesCount;

@property (nonatomic, strong) CMMotionManager *motionManager;

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

- (CMMotionManager *)motionManager {
    if (!_motionManager) {
        _motionManager = [[CMMotionManager alloc] init];
    }
    return _motionManager;
}

- (void)setMotionEnable:(BOOL)motionEnable {
    _motionEnable = motionEnable;
    if (![self.motionManager isDeviceMotionAvailable]) {
        return;
    }
    if (motionEnable) {
        [self.motionManager startDeviceMotionUpdates];
    } else {
        [self.motionManager stopDeviceMotionUpdates];
    }
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
    
    if (self.motionEnable) {
        GLKVector3 eulerianAngle = self.motionManager.deviceMotion.attitude.mf_eulerianAngle;
        self.angleX = -eulerianAngle.z;
        self.angleY = -eulerianAngle.x;
    } else {
        self.angleX = 0;
        self.angleY = 0;
    }
    
    GLfloat aspect = [self inputSize].width / [self inputSize].height;
    GLKMatrix4 matrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(45), aspect, 0.1, 100.f);

    matrix = GLKMatrix4RotateY(matrix, self.angleX - M_PI_2);
    matrix = GLKMatrix4RotateZ(matrix, self.angleY + M_PI_2);
    
    glUniformMatrix4fv(glGetUniformLocation(self.renderProgram, "matrix"), 1, GL_FALSE, matrix.m);
    
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
    
    // 深度缓存
    glEnable(GL_DEPTH_TEST);
    
    GLuint positionSlot = glGetAttribLocation(self.renderProgram, "position");
    glEnableVertexAttribArray(positionSlot);
    glVertexAttribPointer(positionSlot, 3, GL_FLOAT, GL_FALSE, 5 * sizeof(float), (void*)0);
    
    GLuint textureSlot = glGetAttribLocation(self.renderProgram, "inputTextureCoordinate");
    glEnableVertexAttribArray(textureSlot);
    glVertexAttribPointer(textureSlot, 2, GL_FLOAT, GL_FALSE, 5 * sizeof(float), (void*)(3* sizeof(float)));
    
    glDrawElements(GL_TRIANGLE_STRIP, self.indicesCount, GL_UNSIGNED_INT, 0);
    
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
    int segment = 80;  // 纹理的横向分割数
    
    float pointX;
    float pointY;
    float pointZ;
    float textureX;
    float textureY;
    
    float ballRaduis = 0.8;  // 球体半径
     
    float deltaRadian = 2 * M_PI / segment;  // 弧度的增量
    float deltaTextureX = 1.0 / segment;  // 纹理横向增量
    float deltaTextureY = 1.0 / (segment / 2);  // 纹理纵向增量
    
    int layerNum = segment / 2 + 1;  // 纵向分割数
    float perLayerNum = segment + 1;  // 每一层的点数
    
    *count = kSizePerVertex * perLayerNum * layerNum;
    
    float size = sizeof(float) * (*count);
    float *vertices = malloc(size);
    memset(vertices, 0x00, size);
    
    for (int i = 0; i < layerNum; i++) {
        pointY = -ballRaduis * cos(deltaRadian * i);
        float layerRaduis = ballRaduis * sin(deltaRadian * i);
        for (int j = 0; j < perLayerNum; j++) {
            pointX = layerRaduis * cos(deltaRadian * j);
            pointZ = layerRaduis * sin(deltaRadian * j);
            textureX = deltaTextureX * j;
            textureY = deltaTextureY * i;

            int index = (i * perLayerNum + j) * kSizePerVertex;
            vertices[index] = pointX;
            vertices[index + 1] = pointY;
            vertices[index + 2] = pointZ;
            vertices[index + 3] = textureX;
            vertices[index + 4] = textureY;
        }
    }
    
    return vertices;
}

/// 创建索引数组
- (int *)createIndices:(int *)count {
    int segment = 80;  // 纹理的横向分割数
    
    int perLayerNum = segment + 1;  // 每一层的点数
    *count = perLayerNum * perLayerNum;
    
    int size = sizeof(int) * (*count);
    int* indices = malloc(size);
    memset(indices, 0x00, size);
    
    int layerNum = segment / 2 + 1;
    
    for (int i = 0; i < layerNum; i++) {
        if (i + 1 < layerNum) {
            for (int j = 0; j < perLayerNum; j++) {
                indices[(i * perLayerNum * 2) + (j * 2)] = i * perLayerNum + j;
                indices[(i * perLayerNum * 2) + (j * 2 + 1)] = (i + 1) * perLayerNum + j;
            }
        } else {
            for (int j = 0; j < perLayerNum; j++) {
                indices[i * perLayerNum * 2 + j] = i * perLayerNum + j;
            }
        }
    }
    return indices;
}

@end
