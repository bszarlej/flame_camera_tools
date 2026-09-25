## 5.2.0

### Features

* Added `camera.rotateTo` to rotate the camera to an absolute angle in degrees.

## 5.1.0

### Behavior changes

* `ShakeEffect` now reaches its full `amplitude` on each axis. Before, it only moved up to half of it, so shakes are now twice as strong. Halve your amplitudes to keep the previous feel.
* `ShakeEffect` is no longer a `MoveEffect`, so `camera.stop()`, `chase()` and `lookAt()` no longer cancel a running shake.
* `ShakeEffect` no longer implements `measure()`. Speed-based controllers (`EffectController(speed: ...)`) are not supported for shakes and now trigger an assertion in debug builds. Before, they silently ended the shake immediately.
* Futures returned by camera effects now complete when the effect is removed, one frame after it finishes.

### Fixes

* Futures returned by `shake`, `zoomBy`, `zoomTo`, `rotateBy` and `lookAt` now complete when the effect is cancelled, instead of never completing. `effectSequence` no longer gets stuck on a cancelled effect.
* Starting the same kind of effect twice in one frame now replaces the first one instead of running both. The same applies to calling `chase()` twice in one frame.
* `ShakeEffect` now adds its offset on top of the target's position, so the camera keeps following its target while shaking. The offset is undone if the shake is removed early.
* `ShakeEffect` can now be reset without throwing a `LateInitializationError`.
* `horizontalOnly` and `verticalOnly` now work with `CircularDeadZone`: the distance on the locked axis no longer pushes the target out of the dead zone.
* `chase(snap: true)` now snaps to the target plus `offset`.
* `zoomBy` now asserts that `value` is greater than `-1`.
* Setting both `horizontalOnly` and `verticalOnly` on `AdvancedFollowBehavior` now triggers an assertion.
* The documentation of `rotateBy` now correctly says the angle is in degrees.

### Deprecations

* Renamed `Deadzone`, `CircularDeadzone` and `RectangularDeadzone` to `DeadZone`, `CircularDeadZone` and `RectangularDeadZone`. The old names still work, but are deprecated and will be removed in 6.0.0.

### Other

* The minimum Flutter version is now 3.27.2, matching the existing Dart SDK constraint.
* Added tests and CI, including a check against the oldest supported versions.
* Updated the documentation, README and example.

## 5.0.2

* Updated Documentation.

## 5.0.1

* Updated Documentation.

## 5.0.0

* Renamed `SmoothFollowBehavior` to `AdvancedFollowBehavior`.
* Renamed `camera.smoothFollow` to `camera.chase` which now returns a `AdvancedFollowBehavior` instance,
  which allows to tweak options such as `offset`, `deadzone` or `stiffness` later on.
* All camera effect methods take now `EffectController` as a parameter, which adds even more modularity.
* Remove `weakenOverTime` parameter from `ShakeEffect` which is the default action now.
* Updated Documentation.

## 4.1.0

* The `stiffness` and `deadZone` parameters of `SmoothFollowBehavior` are now adjustable.
* Added the `offset` parameter to `SmoothFollowBehavior` and `camera.smoothFollow` to allow following a point offset from the target, enabling look-ahead or custom camera focus.
* Added `RectangularDeadzone.all` and `RectangularDeadzone.symmetric` constructors.

## 4.0.1

* Updated `README.md`

## 4.0.0

* Replaced `deadZone` parameter from a fixed rectangular Rect to a flexible Deadzone abstraction.
* Added new deadzone implementations: `RectangularDeadzone` and `CircularDeadzone`, allowing for customizable deadzone shapes.
* Updated `SmoothFollowBehavior` to use the new `Deadzone` system, enhancing how the camera follows targets based on configurable deadzone boundaries.
* Improved documentation

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