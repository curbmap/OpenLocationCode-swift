//
//  OpenLocationCodeTests.swift
//  OpenLocationCodeTests
//
//  Created by Eli Selkin on 7/25/17.
//  Copyright © 2017 Eli Selkin. All rights reserved.
//

import XCTest
@testable import OpenLocationCode

class OpenLocationCodeTests: XCTestCase {
    let epsilon = 1E-6
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testInitWithCode() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        let x:OpenLocationCode? = try? OpenLocationCode("85634RQ4+X37")
        assert(x != nil)
    }
    
    func testInitWithLatLng() {
        let x: OpenLocationCode? = try? OpenLocationCode(latitude: 34.139912, longitude: -118.194828, codeLength: 11)
        assert(x != nil)
        assert(x?.getCode() == "85634RQ4+X37")
        let y: OpenLocationCode? = try? OpenLocationCode(latitude: 34.139912, longitude: -118.194838, codeLength: 11)
        assert(y != nil)
        // should only differ in the last two characters
        let filtered = zip(x!.getCode().characters, y!.getCode().characters).filter{$0 != $1}
        assert(filtered.count <= 2)
        let z: OpenLocationCode? = try? OpenLocationCode(latitude: 90, longitude: 1, codeLength: 10)
        assert(z != nil)
        assert(z?.getCode() == "CFX3X2X2+X2")
        let a: OpenLocationCode? = try? OpenLocationCode(latitude: 1, longitude: 1 codeLength: 11)
        assert(a != nil)
        assert(a?.getCode() == "6FH32222+222")
    }
    
    func testDecode() {
        let codeArea: CodeArea = try! OpenLocationCode.decode(code: "85634RQ4+X37")
        let test = codeArea.LatLng()
        assert(fabs(fabs(test.latitude) - fabs(34.139912)) < epsilon)
        assert(fabs(fabs(test.longitude) - fabs(-118.194828)) < epsilon)
    }
    
    func testObjCreationWithCode() {
        let olc = try? OpenLocationCode("8FW4V75V+8Q")
        let test = olc?.getCodeArea()
        if (test != nil) {
            assert((test!.LatLng().latitude - 48.858313) < epsilon)
            assert((test!.LatLng().longitude - 2.294438) < epsilon)
        }
        
    }
    
    func testObjCreationWithLatLng() {
        // just testing the limits here
        let olc = try? OpenLocationCode(latitude: 48.858093, longitude: 2.294694, codeLength: 15)
        let test = olc?.getCodeArea()
        if (test != nil) {
            print(test!.LatLng()) // With a code length of 15 we should have resolution down to the 6th decimal place
            assert(fabs(test!.LatLng().latitude - 48.858093) < epsilon/10)
            assert(fabs(test!.LatLng().longitude - 2.294694) < epsilon/10)
        }
    }
    
    func testBoundingBox() {
        let a = "85634WR4+CM"
        let b = "85634W00+"
        let c = try? OpenLocationCode.smallestBoundingBox(a, b)
        assert(c != nil)
        print((c??.getCode())!)
    }
    
    func testPerformanceExample() {
        // See how long it takes to make a 1000 encoding and decodings (that's what this does behind the scenes)... the most complex of initializers with high resolution
        self.measure {
            for _ in 0...1000 {
                let _ = try? OpenLocationCode(latitude: 48.858093, longitude: 2.294694, codeLength: 15)
            }
        }
    }
    
}
