//
//  CodeArea.swift
//  OpenLocationCode
//
//  Created by Eli Selkin on 7/27/17.
//  Copyright © 2017 curbmap. All rights reserved.
//

import Foundation
public struct CodeArea {
    let latitudeLow: Float64;
    let longitudeLow: Float64;
    let latitudeHigh: Float64;
    let longitudeHigh: Float64;
    let latitudeCenter: Float64;
    let longitudeCenter: Float64;
    let codeLength: Int;
    init(latitudeLow: Float64, longitudeLow: Float64, latitudeHigh: Float64, longitudeHigh: Float64, codeLength: Int) {
        self.latitudeLow = latitudeLow
        self.longitudeLow = longitudeLow
        self.latitudeHigh = latitudeHigh
        self.longitudeHigh = longitudeHigh
        self.latitudeCenter = min( (latitudeLow + latitudeHigh)/2, OpenLocationCode.LATITUDE_MAX )
        self.longitudeCenter = min( (longitudeLow + longitudeHigh)/2, OpenLocationCode.LONGITUDE_MAX )
        self.codeLength = codeLength
    }
    
    public func LatLng() -> (latitude: Float64, longitude: Float64){
        return (latitude: self.latitudeCenter, longitude: self.longitudeCenter)
    }
}
