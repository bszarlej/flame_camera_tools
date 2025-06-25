## 3.0.1

* Fixed `stiffness` value in the example code

## 3.0.0

* Changed the `stiffness` parameter of `SmoothFollowBehavior` to be a value between 0.0 and 1.0, where a value of 0.0 means no movement at all and a value of 1.0 means immediate following.

## 2.0.0

* Merge `SmoothFollowBehavior` and `AreaFollowBehavior` into one class

## 1.2.0

* Added `moveAlongPath()` method for CameraComponent
* Adjusted effect duration defaults to 1 second

## 1.1.0

* Added demo GIFs

## 1.0.1

* Calling `complete()` on completers when duration is zero
* Cosmetic changes inside `README.md`

## 1.0.0

* Added `weakenOverTime` parameter to `shake()` method
* Using `double` instead of the `Duration` class for the duration of the effects

## 0.0.5+1

* fix: use `radians()` also when the duration is zero

## 0.0.5

* Added `rotateBy()` method for CameraComponent
* Refactor method parameter defaults

## 0.0.4

* Removed `stiffness` parameter from `areaFollow()`
* Added `maxSpeed` parameter to `areaFollow()` and `AreaFollowBehavior`

## 0.0.3

## 0.0.2

* Added `AreaFollowBehavior`
* Added `areaFollow()` method for CameraComponent
* Added Documentation

## 0.0.1

* Initial Release