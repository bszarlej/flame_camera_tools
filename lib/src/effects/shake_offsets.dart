import 'package:flame/components.dart';

/// The offset that running shakes add to the position of each target, summed
/// over all shakes on the same target.
///
/// `ShakeEffect` keeps this up to date. Followers like `ChaseBehavior`
/// subtract it to follow from where the target would be without shaking.
///
/// This is internal and not exported from the package.
final shakeOffsets = Expando<Vector2>();
