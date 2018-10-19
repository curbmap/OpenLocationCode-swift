# OpenLocationCode-swift

Open location code framework for swift For original code, see @google
[Google's code](https://github.com/google/open-location-code)

**Make sure you follow all of the general installation procedures for CocoaPods**

**To install this framework for your project**

* add this line to your Podfile: `pod 'OpenLocationCode' '~>0.0.5.3'`
* follow that with a pod install (you may have to update if you don't have the newest spec list)

Then, in your project swift file.

```
import OpenLocationCode
```

Currently there are two public static methods which can be used from the class itself.

1. OpenLocationCode.encode which takes a latitude and longitude (Double/Float64s) named pair and a desired code length.
   It returns the string of a full Open Location Code.

```
OpenLocationCode.encode(LatLng: (latitude: y, longitude: x), codeLength: Int)
```

2. OpenLocationCode.decode which takes an Open Location Code string and returns a CodeArea. Open Location Codes aren't
   really meant for a point, but rather a region (even if it's a very small region) so there will necessarily be some
   range associated with decoding.

```
OpenLocationCode.decode(code: String)
```
** As of 0.5.3** 10/18/2018

Code is now strictly enforced to be less than or equal to 15 characters. 


** As of 0.5.1** 11/22/2017

Code is now compliant with Swift 4.0. If you need 3.2 compatible use release 0.0.4.7.

Code now inherits from NSObject so can be used in Objective-C projects. Not that I'd encourage anyone to use
Objective-C. Some of the functions will probably have to be modified for Objective-C use considering their use of the
struct CodeArea. I might make that a subclass of NSObject so that it can in the future be used as an Objective-C return
type.

In the near future I will add the recovery from short codes + Lat Lng. In my experience, I have not really used that.
