//
//  ViewController.swift
//  MetalTest
//
//  Created by Zedd on 2020/06/12.
//  Copyright © 2020 Zedd. All rights reserved.
//

import UIKit
import Metal

class ViewController: UIViewController {

    var device: MTLDevice!
    var metalLayer: CAMetalLayer!
    
    var vertexBuffer: MTLBuffer!
    var pipelineState: MTLRenderPipelineState!
    var commandQueue: MTLCommandQueue!
    var timer: CADisplayLink!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.device = MTLCreateSystemDefaultDevice()
        
        self.metalLayer = CAMetalLayer()                // 1
        self.metalLayer.device = self.device            // 2
        self.metalLayer.pixelFormat = .bgra8Unorm       // 3
        self.metalLayer.framebufferOnly = true          // 4
        self.metalLayer.frame = self.view.layer.frame   // 5
        self.view.layer.addSublayer(self.metalLayer)    // 6
        
        let vertexData: [Float] = [
           0.0,  1.0, 0.0,
          -1.0, -1.0, 0.0,
           1.0, -1.0, 0.0
        ]
        
        let dataSize = vertexData.count * MemoryLayout.size(ofValue: vertexData[0]) // 1
        self.vertexBuffer = self.device.makeBuffer(bytes: vertexData, length: dataSize, options: []) // 2
        
        // 1
        let defaultLibrary = self.device.makeDefaultLibrary()!
        let fragmentProgram = defaultLibrary.makeFunction(name: "basic_fragment")
        let vertexProgram = defaultLibrary.makeFunction(name: "basic_vertex")
            
        // 2
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexProgram
        pipelineStateDescriptor.fragmentFunction = fragmentProgram
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
            
        // 3
        self.pipelineState = try! self.device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
        
        self.commandQueue = self.device.makeCommandQueue()
        
        self.timer = CADisplayLink(target: self, selector: #selector(gameloop))
        self.timer.add(to: RunLoop.main, forMode: .default)
    }
    
    func render() {
        guard let drawable = self.metalLayer?.nextDrawable() else { return }
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = drawable.texture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(
            red: 0.0,
            green: 104.0/255.0,
            blue: 55.0/255.0,
            alpha: 1.0)
        
        let commandBuffer = self.commandQueue.makeCommandBuffer()!
        let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
        renderEncoder.setRenderPipelineState(self.pipelineState)
        renderEncoder.setVertexBuffer(self.vertexBuffer, offset: 0, index: 0)
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3, instanceCount: 1)
        renderEncoder.endEncoding()
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }

    @objc func gameloop() {
      autoreleasepool {
        self.render()
      }
    }
}

