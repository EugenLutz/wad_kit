//
//  Mesh.swift
//  WADKit
//
//  Created by Eugen Lutz on 27.01.24.
//

import Foundation


public struct BoundingSphere {
    public internal(set) var rawCenterX: Int16
    public internal(set) var rawCenterY: Int16
    public internal(set) var rawCenterZ: Int16
    public internal(set) var rawRadius: UInt16
    public internal(set) var unknown: UInt16
}


public struct Vertex {
    public var rawX: Int16
    public var rawY: Int16
    public var rawZ: Int16
    
    public var x: Float { Float(rawX) / 1024 }
    public var y: Float { Float(rawY) / 1024 }
    public var z: Float { Float(rawZ) / 1024 }
}


public struct Normal {
    public var rawX: Int16
    public var rawY: Int16
    public var rawZ: Int16
    
    public var x: Float { Float(rawX) / 16300 }
    public var y: Float { Float(rawY) / 16300 }
    public var z: Float { Float(rawZ) / 16300 }
}


public struct Shade {
    private var _rawValue: Int16 = 0
    private var _value: Float = 0
    
    public var rawValue: Int16 {
        get { _rawValue }
        
        set {
            _rawValue = newValue
            _value = Float(_rawValue) / Float(0x1FFF)
        }
    }
    
    public var value: Float {
        get { _value }
        
        set {
            _value = newValue
            _rawValue = Int16(_value * Float(0x1FFF))
        }
    }
    
    public init() {
        _rawValue = 0x1FFF
        _value = 1
    }
    
    internal init(rawValue: Int16) {
        self.rawValue = rawValue
    }
}


public struct Polygon {
    struct Triangle {
        var v1: UInt16
        var v2: UInt16
        var v3: UInt16
    }
    
    struct Quad {
        var v1: UInt16
        var v2: UInt16
        var v3: UInt16
        var v4: UInt16
    }
    
    enum Shape {
        case triangle(value: Triangle)
        case quad(value: Quad)
    }
    var shape: Shape
    
    
    enum SampleShape {
        case topLeft
        case topRight
        case bottomRight
        case bottomLeft
        case quad
    }
    
    var flippedHorizontally: Bool
    var sampleShape: SampleShape
    var sampleIndex: UInt16
    
    var shineIntensity: UInt8
    var shiny: Bool
    var opaque: Bool
    
    var unknown: UInt8
}

extension DataReader {
    func read() throws -> Polygon {
        let shape: Polygon.Shape = try {
            let rawShapeType: UInt16 = try read()
            
            switch rawShapeType {
            case 8: return .triangle(
                value: .init(
                    v1: try read(),
                    v2: try read(),
                    v3: try read()
                )
            )
                
            case 9: return .quad(
                value: .init(
                    v1: try read(),
                    v2: try read(),
                    v3: try read(),
                    v4: try read()
                )
            )
                
            default: throw DataReaderError.other("Wrong shape type: \(rawShapeType)")
            }
        }()
        
        let textureFlags: UInt16 = try read()
        
        let flippedHorizontally: Bool = ((textureFlags & 0x8000) >> 15) == 1
        
        let sampleShape: Polygon.SampleShape = try {
            let rawSampleShape = ((textureFlags & 0x7000) >> 12)
            switch rawSampleShape {
            case 0: return .topLeft
            case 2: return .topRight
            case 4: return .bottomRight
            case 6: return .bottomLeft
            case 7: return .quad
            default: throw DataReaderError.other("Wrong texture sample shape: \(rawSampleShape)")
            }
        }()
        
        let sampleIndex: UInt16 = {
            if case .triangle(_) = shape {
                return textureFlags & 0x0fff
            }
            
            let index: Int16 = Int16(bitPattern: textureFlags & 0xffff)
            if flippedHorizontally && index < 0 {
                return UInt16(-index)
            }
            
            return UInt16(bitPattern: index)
        }()
        
        let attributes: UInt8 = try read()
        let shineIntensity: UInt8 = (attributes & 0x7c) >> 2
        let shiny: Bool = ((attributes & 0x02) >> 1) == 1
        let opaque: Bool = ((attributes & 0x01)) == 1
        
        let unknown: UInt8 = try read()
        
        return Polygon(
            shape: shape,
            flippedHorizontally: flippedHorizontally,
            sampleShape: sampleShape,
            sampleIndex: sampleIndex,
            shineIntensity: shineIntensity,
            shiny: shiny,
            opaque: opaque,
            unknown: unknown
        )
    }
}


public class Mesh {
    private (set) weak var owner: WAD?
    
    public var boundingSphere: BoundingSphere
    public var vertices: [Vertex]
    public var normals: [Normal]
    public var shades: [Shade]
    public var polygons: [Polygon]
    
    
    internal init(owner: WAD, boundingSphere: BoundingSphere, vertices: [Vertex], normals: [Normal], shades: [Shade], polygons: [Polygon]) {
        self.owner = owner
        self.boundingSphere = boundingSphere
        self.vertices = vertices
        self.normals = normals
        self.shades = shades
        self.polygons = polygons
    }
}



class DataWriter {
    private(set) var data = Data()
    
    func write<SomeType>(_ value: SomeType) where SomeType: BinaryInteger {
        withUnsafePointer(to: value) { pointer in
            data.append(Data(bytes: pointer, count: MemoryLayout<SomeType>.size))
        }
    }
    
    func write<SomeType>(_ value: SomeType) where SomeType: BinaryFloatingPoint {
        withUnsafePointer(to: value) { pointer in
            data.append(Data(bytes: pointer, count: MemoryLayout<SomeType>.size))
        }
    }
    
    func skip<SomeType>(_ bytesToSkip: SomeType) where SomeType: BinaryInteger {
        let numBytes = Int(bytesToSkip)
        guard numBytes > 0 else {
            return
        }
        
        data.append(Data(capacity: numBytes))
    }
}


//extension DataWriter {
//    func write(_ value: Float) {
//        write(Float32(value))
//    }
//}


public struct VertexBuffer {
    public enum LightingType {
        case normals
        case shades
    }
    
    public let textureIndex: Int
    public let lightingType: LightingType
    public let numVertices: Int
    public let data: Data
}


public struct TexturePageRemapInfo {
    public let pageIndex: Int
    public let textureIndex: Int
    public let uvMagnifier: Float
    public let offsetU: Float
    public let offsetV: Float
    
    
    public init(pageIndex: Int, textureIndex: Int, uvMagnifier: Float, offsetU: Float, offsetV: Float) {
        self.pageIndex = pageIndex
        self.textureIndex = textureIndex
        self.uvMagnifier = uvMagnifier
        self.offsetU = offsetU
        self.offsetV = offsetV
    }
}


extension Mesh {
    public func generateVertexBuffers(withRemappedTexturePages map: [TexturePageRemapInfo]) throws -> [VertexBuffer] {
        guard let owner else {
            throw WAD.LoadError.custom("Owner not found")
        }
        
//        guard map.count != owner.texturePages.count else {
//            throw WAD.LoadError.custom("Texture page remap info count doesn't match number of WAD's texture pages")
//        }
        
        // Layout 1 - 36 stride
        // vx, vy, vz   0   12
        // u, v         16  8
        // nx, ny, nz   24  12
        
        // Layout 2 - 28 stride
        // vx, vy, vz   0   12
        // u, v         16  8
        // shade        24  4
        
        
        /// Links a buffer with texture
        class BufferBuilder {
            let writer = DataWriter()
            let textureIndex: Int
            var numVertices: Int = 0
            
            init(textureIndex: Int) {
                self.textureIndex = textureIndex
            }
        }
        var buffers: [BufferBuilder] = []
        
        func getBufferBuilder(forTexturePage pageIndex: UInt16) throws -> BufferBuilder {
            guard let textureIndex = map.first(where: { $0.pageIndex == pageIndex })?.textureIndex else {
                throw WAD.LoadError.custom("Texture page remap info doesn't contain remap info for texture page \(pageIndex)")
            }
            
            if let contents = buffers.first(where: { $0.textureIndex == textureIndex }) {
                return contents
            }
            
            let contents = BufferBuilder(textureIndex: textureIndex)
            buffers.append(contents)
            return contents
        }
        
        
        let lightingType: VertexBuffer.LightingType = shades.isEmpty ? .normals : .shades
        
        
        for polygon in self.polygons {
            guard polygon.sampleIndex < owner.textureSamples.count else {
                throw WAD.LoadError.custom("Sample index is out of range \(polygon.sampleIndex) >= \(owner.textureSamples.count)")
            }
            let sample = owner.textureSamples[Int(polygon.sampleIndex)]
            let bufferBuilder = try getBufferBuilder(forTexturePage: sample.raw.page)
            let writer = bufferBuilder.writer
            
            enum UVIndex {
                case v1
                case v2
                case v3
                case v4
            }
            
            func writeVertex(_ index: UInt16, _ uvIndex: UVIndex) throws {
                let vertexIndex = Int(index)
                guard vertexIndex < vertices.count else {
                    throw WAD.LoadError.custom("Vertex index is out of range")
                }
                
                // Write vertex
                let vertex = vertices[vertexIndex]
                writer.write(vertex.x)
                writer.write(vertex.y)
                writer.write(vertex.z)
                
                // Write UV
                let correctedUVIndex = {
                    if !polygon.flippedHorizontally {
                        return uvIndex
                    }
                    
                    switch uvIndex {
                    case .v1: return .v2
                    case .v2: return .v1
                    case .v3: return .v4
                    case .v4: return .v3
                    }
                }()
                switch correctedUVIndex {
                case .v1:
                    writer.write(sample.raw.left)
                    writer.write(sample.raw.top)
                    
                case .v2:
                    writer.write(sample.raw.right)
                    writer.write(sample.raw.top)
                    
                case .v3:
                    writer.write(sample.raw.right)
                    writer.write(sample.raw.bottom)
                    
                case .v4:
                    writer.write(sample.raw.left)
                    writer.write(sample.raw.bottom)
                }
                
                // Write Normal/Shade
                if !normals.isEmpty {
                    guard vertexIndex < normals.count else {
                        throw WAD.LoadError.custom("Normal index is out of range")
                    }
                    let normal = normals[vertexIndex]
                    writer.write(normal.x)
                    writer.write(normal.y)
                    writer.write(normal.z)
                }
                else {
                    guard vertexIndex < shades.count else {
                        throw WAD.LoadError.custom("Shade index is out of range")
                    }
                    let shade = shades[vertexIndex]
                    writer.write(shade.value)
                }
                
                
                bufferBuilder.numVertices += 1
            }
            
            switch polygon.shape {
            case .triangle(let value):
                try writeVertex(value.v1, .v1)
                try writeVertex(value.v3, .v3)
                try writeVertex(value.v2, .v2)
                
            case .quad(let value):
                try writeVertex(value.v1, .v1)
                try writeVertex(value.v3, .v3)
                try writeVertex(value.v2, .v2)
                
                try writeVertex(value.v1, .v1)
                try writeVertex(value.v4, .v4)
                try writeVertex(value.v3, .v3)
            }
        }
        
        return buffers.map {
            VertexBuffer(
                textureIndex: $0.textureIndex,
                lightingType: lightingType,
                numVertices: $0.numVertices,
                data: $0.writer.data
            )
        }
    }
}