import tensorial

type
  KeyPoint* = object
    x*, y*: float32
    response*: float32
    scale*: uint8
  Descriptor*[Feature] = object
    point*: KeyPoint
    feature*: Feature
  Match* = object
    first*, second*: KeyPoint
    dx*, dy*: float32
    distance*: float32
  KeyPoints* = seq[KeyPoint]
  Descriptors* = seq[Descriptor]
  KeyPointMatcher*[
    KeyPointDetector,
    KeyPointDescriptor,
    KeyPointRelator
  ] = object
    detector: KeyPointDetector
    descriptor: KeyPointDescriptor
    relator: KeyPointRelator

proc matcher*[A, B, C](detector: A; descriptor: B; relator: C): KeyPointMatcher[A, B, C] =
  KeyPointMatcher[A, B, C](
    detector: detector,
    descriptor: descriptor,
    relator: relator
  )
proc descriptor*[Feature](
  point: Keypoint; feature: Feature
): Descriptor[Feature] {. inline .} =
  Descriptor[Feature](
    point: point,
    feature: feature
  )
proc match*(x, y: Keypoint; distance: float32): Match {. inline .} =
  Match(
    first: x, second: y,
    dx: y.x - x.x, dy: y.y - x.y,
    distance: distance
  )