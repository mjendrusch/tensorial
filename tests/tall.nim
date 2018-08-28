# import nimprof
import tensorial
import tensorial / vision / [censure, freak, keypoints, phasecorrelation, motion2d]

import times, math, strformat, random

proc alignedAlloc(alignment, size: csize): pointer {.
  importc: "aligned_alloc", header: "<stdlib.h>"
.}

proc makeRealPtrTensor(n, m: int): PtrTensor[float32] =
  var
    sq = cast[ptr float32](alignedAlloc(csize 32, csize(n * m) * sizeof(float32)))
    shape = [n, m]
  result = sq.toTensor(shape)

proc makePtrTensor(n, m: int): PtrTensor[Complex64] =
  var
    sq = cast[ptr Complex64](alignedAlloc(csize 32, csize(n * m) * 2 * sizeof(float32)))
    shape = [n, m]
  result = sq.toTensor(shape)

# proc makeRealTensor(n, m: int): SeqTensor[float32] =
#   var
#     sq = newSeq[float32](n * m)
#     shape = [n, m]
#   result = sq.toTensor(shape)

# proc makeTensor(n, m: int): SeqTensor[Complex64] =
#   var
#     sq = newSeq[Complex64](n * m)
#     shape = [n, m]
#   result = sq.toTensor(shape)

let
  base = makeRealPtrTensor(1024, 1024)
  input = makeRealPtrTensor(512, 512)
  another = makeRealPtrTensor(512, 512)
  # output = makePtrTensor(512, 512)
  # inputC = makePtrTensor(512, 512)
  # anotherC = makePtrTensor(512, 512)
  # outputC = makePtrTensor(512, 512)

# Prepare testing offsets:
for tx in 0 ..< 128:
  let
    randX = rand(10.0)
  for ty in 0 ..< 128:
    let
      randY = rand(10.0)
    for idx in tx * 8 ..< tx * 8 + 8:
      for idy in ty * 8 ..< ty * 8 + 8:
        base[idx, idy] = randX + randY + rand(5.0) * sin((float32 idx) * 2 * Pi / 23.0) * cos((float32 idy) * 2 * Pi / 23.0)
for idx in 0 ..< 512:
  for idy in 0 ..< 512:
    input[idx, idy] = base[idx, idy]
    # inputC[idx, idy] = complex(input[idx, idy], 0.0'f32)
for tx in 0 ..< 512:
  let
    idx = tx + 200
  for ty in 0 ..< 512:
    let
      idy = ty + 200
    another[tx, ty] = base[idx, idy]  +
                      0.5 * (base[idx + 1, idy] - base[idx, idy]) +
                      0.5 * 0.5 * (base[idx + 2, idy] - 2 * base[idx + 1, idy] + base[idx, idy]) / 2 +
                      0.5 * 0.5 * 0.5 * (base[idx + 3, idy] - 3 * base[idx + 2, idy] + 3 * base[idx + 1, idy] - base[idx, idy]) / 6

var
  correlator = PhaseCorrelation.init(input.shape)
  detector = CenSurE[float32].init(
    input.shape,
    1, 10,
    responseThreshold = 0.15
  )
  descriptor = Freak()
  keypointEstimator = MeanTranslation()
  correlationEstimator = SubPixelCorrelationTranslation()

correlator.update(input)

let
  kp = detector.keypoints(input)
  ll = descriptor.describe(detector.integral, kp)

var
  displacement: Displacement
timeIt 1:
  let
    ka = detector.keypoints(another)
    la = descriptor.describe(detector.integral, ka)
    matches = match(la, ll, threshold = 20)
  displacement = keypointEstimator.estimate(matches)

echo fmt"({displacement.dx}, {displacement.dy})"

timeIt 1:
  correlator.update(input)
  correlator.update(another)
  correlator.correlate()
  displacement = correlationEstimator.estimate(correlator.correlation)

echo fmt"({displacement.dx}, {displacement.dy})"

# timeit 50:
#   realFFT(input, output)
#   realInverseFFT(output, another)

# timeit 50:
#   fft(inputC, outputC, FFTDirection.forward)
#   fft(outputC, anotherC, FFTDirection.reverse)
