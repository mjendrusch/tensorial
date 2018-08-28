import tensorial
import tables
import odometry, keypoints

type
  KeyPointOdometry*[
    Store, Detector, Descriptor, Relator
  ] = object
    keyframes: Store
    position: Displacement
    velocity: Displacement
    detector: Detector
    descriptor: Descriptor
    relator: Relator

  KeyPointOdometry2D*[
    Store, Detector, Descriptor, Relator
  ] = object
    keyframes: Store
    position: Displacement2D
    velocity: Velocity2D
    detector: Detector
    descriptor: Descriptor
    relator: Relator

  SomeKeyPointOdometry* = KeyPointOdometry or KeyPointOdometry2D

proc init*[A, B, C, D](
  typ: typedesc[KeyPointOdometry];
  store: A; detector: B; descriptor: C; relator: D
): KeyPointOdometry[Store, Detector, Descriptor, Relator] =
  

proc update*[T](odometry: var SomeKeyPointOdometry;
                image: TensorLike[T]) =
  let
    keypoints = odometry.detector.detect(image)
    descriptors = odometry.descriptor.describe(keypoints)
    matches = match(odometry.keyframes[^1], descriptors)
    offset = odometry.relator.estimate(matches)
  odometry.position += offset
