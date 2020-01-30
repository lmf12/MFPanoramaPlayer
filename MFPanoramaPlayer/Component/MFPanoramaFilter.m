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

#import "MFPanoramaFilter.h"

@import OpenGLES;
@import GLKit;

@interface MFPanoramaFilter ()

@property (nonatomic, strong) EAGLContext *context;
@property (nonatomic, assign) GLuint renderProgram;

@property (nonatomic, assign) CVPixelBufferRef resultPixelBuffer;

@property (nonatomic, strong) MFPixelBufferHelper *pixelBufferHelper;

@property (nonatomic, assign) float *vertices;
@property (nonatomic, assign) uint16_t *indices;
@property (nonatomic, assign) int verticesCount;
@property (nonatomic, assign) int indicesCount;

@property (nonatomic, assign) GLuint VBO;
@property (nonatomic, assign) GLuint EBO;

@property (nonatomic, strong) CMMotionManager *motionManager;
@property (nonatomic, assign) GLKQuaternion srcQuaternion;
@property (nonatomic, assign) GLKQuaternion desQuaternion;

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
    if (_VBO) {
        glDeleteBuffers(1, &_VBO);
    }
    if (_EBO) {
        glDeleteBuffers(1, &_EBO);
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
    self.srcQuaternion = GLKQuaternionIdentity;
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    [EAGLContext setCurrentContext:self.context];
    [self setupRenderProgram];
    self.pixelBufferHelper = [[MFPixelBufferHelper alloc] initWithContext:self.context];
    
    [self genSphereWithSlices:100
                       radius:1.0
                     vertices:&_vertices
                      indices:&_indices
                verticesCount:&_verticesCount
                 indicesCount:&_indicesCount];
    [self setupVBO];
    [self setupEBO];
}

- (void)setupRenderProgram {
    self.renderProgram = [MFShaderHelper programWithShaderName:@"Panorama"];
}

- (void)setupVBO {
    glGenBuffers(1, &_VBO);
    glBindBuffer(GL_ARRAY_BUFFER, _VBO);
    glBufferData(GL_ARRAY_BUFFER, sizeof(float) * self.verticesCount, self.vertices, GL_STATIC_DRAW);
}

- (void)setupEBO {
    glGenBuffers(1, &_EBO);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _EBO);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(uint16_t) * self.indicesCount, self.indices, GL_STATIC_DRAW);
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
    
    GLfloat aspect = [self inputSize].width / [self inputSize].height;
    GLKMatrix4 matrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(45), aspect, 0.1, 100.f);
    matrix = GLKMatrix4Scale(matrix, -1.0f, -1.0f, 1.0f);
    
    if (self.motionEnable) {
        GLKMatrix4 rotation = GLKMatrix4MakeWithQuaternion([self currentQuaternion]);
        matrix = GLKMatrix4Multiply(matrix, rotation);
    } else {
        matrix = GLKMatrix4RotateY(matrix, -self.angleX);
        matrix = GLKMatrix4RotateX(matrix, -self.angleY);
    }
    
    matrix = GLKMatrix4RotateX(matrix, M_PI_2);
    glUniformMatrix4fv(glGetUniformLocation(self.renderProgram, "matrix"), 1, GL_FALSE, matrix.m);
    
    // VBO
    glBindBuffer(GL_ARRAY_BUFFER, self.VBO);
    
    // EBO
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, self.EBO);
    
    // 深度缓存
    glEnable(GL_DEPTH_TEST);
    
    GLuint positionSlot = glGetAttribLocation(self.renderProgram, "position");
    glEnableVertexAttribArray(positionSlot);
    glVertexAttribPointer(positionSlot, 3, GL_FLOAT, GL_FALSE, 5 * sizeof(float), (void*)0);
    
    GLuint textureSlot = glGetAttribLocation(self.renderProgram, "inputTextureCoordinate");
    glEnableVertexAttribArray(textureSlot);
    glVertexAttribPointer(textureSlot, 2, GL_FLOAT, GL_FALSE, 5 * sizeof(float), (void*)(3* sizeof(float)));
    
    glDrawElements(GL_TRIANGLES, self.indicesCount, GL_UNSIGNED_SHORT, 0);
    
    glFlush();
 
    self.resultPixelBuffer = outputPixelBuffer;
    
    glDeleteFramebuffers(1, &frameBuffer);
    glDeleteTextures(1, &inputTextureID);
    CVPixelBufferRelease(outputPixelBuffer);
    
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
}

- (CGSize)inputSize {
    return CGSizeMake(CVPixelBufferGetWidth(self.pixelBuffer),
                      CVPixelBufferGetHeight(self.pixelBuffer));
}

/// 当前四元数，通过线性插值的方式，使镜头移动更平滑
- (GLKQuaternion)currentQuaternion {
    float distance = 0.35;   // 数字越小越平滑，同时移动也更慢
    
    CMQuaternion quaternion = self.motionManager.deviceMotion.attitude.quaternion;
    double w = quaternion.w;
    double wx = quaternion.x;
    double wy = quaternion.y;
    double wz = quaternion.z;
    self.desQuaternion = GLKQuaternionMake(-wx, wy, wz, w);
    
    self.srcQuaternion = GLKQuaternionNormalize(GLKQuaternionSlerp(self.srcQuaternion, self.desQuaternion, distance));
    
    return self.srcQuaternion;
}

/// 生成球体数据
/// @param slices 分割数，越多越平滑
/// @param radius 球半径
/// @param vertices 顶点数组
/// @param indices 索引数组
/// @param verticesCount 顶点数组长度
/// @param indicesCount 索引数组长度
- (void)genSphereWithSlices:(int)slices
                     radius:(float)radius
                   vertices:(float **)vertices
                    indices:(uint16_t **)indices
              verticesCount:(int *)verticesCount
               indicesCount:(int *)indicesCount {
    int numParallels = slices / 2;
    int numVertices = (numParallels + 1) * (slices + 1);
    int numIndices = numParallels * slices * 6;
    float angleStep = (2.0f * M_PI) / ((float) slices);
    
    if (vertices != NULL) {
        *vertices = malloc(sizeof(float) * 5 * numVertices);
    }
    
    if (indices != NULL) {
        *indices = malloc(sizeof(uint16_t) * numIndices);
    }
    
    for (int i = 0; i < numParallels + 1; i++) {
        for (int j = 0; j < slices + 1; j++) {
            int vertex = (i * (slices + 1) + j) * 5;
            
            if (vertices) {
                (*vertices)[vertex + 0] = radius * sinf(angleStep * (float)i) * sinf(angleStep * (float)j);
                (*vertices)[vertex + 1] = radius * cosf(angleStep * (float)i);
                (*vertices)[vertex + 2] = radius * sinf(angleStep * (float)i) * cosf(angleStep * (float)j);
                (*vertices)[vertex + 3] = (float)j / (float)slices;
                (*vertices)[vertex + 4] = 1.0f - ((float)i / (float)numParallels);
            }
        }
    }
    
    // Generate the indices
    if (indices != NULL) {
        uint16_t *indexBuf = (*indices);
        for (int i = 0; i < numParallels ; i++) {
            for (int j = 0; j < slices; j++) {
                *indexBuf++ = i * (slices + 1) + j;
                *indexBuf++ = (i + 1) * (slices + 1) + j;
                *indexBuf++ = (i + 1) * (slices + 1) + (j + 1);
                
                *indexBuf++ = i * (slices + 1) + j;
                *indexBuf++ = (i + 1) * (slices + 1) + (j + 1);
                *indexBuf++ = i * (slices + 1) + (j + 1);
            }
        }
    }
    
    if (verticesCount) {
        *verticesCount = numVertices * 5;
    }
    if (indicesCount) {
        *indicesCount = numIndices;
    }
}

@end
