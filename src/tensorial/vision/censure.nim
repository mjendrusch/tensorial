import tensorial
import math, algorithm
import keypoints, integral, norms
import tensorial / lowlevel

import typetraits

{. passC: "-fopenmp" .}
{. passL: "-fopenmp" .}
{. experimental .}

type
  CenSurE*[T] = object
    start, stop: int
    responseThreshold: float32
    lineThresholdProjected: int
    lineThresholdBinarized: int
    nonMaxSize: int
    integral*: PtrTensor[T]
    responses: PtrTensor[float32]
    scales: PtrTensor[uint8]

proc init*[T](typ: typedesc[CenSurE[T]];
              shape: StackArray[int];
              start, stop: int;
              responseThreshold = 0.15'f32;
              lineThresholdProjected = 10;
              lineThresholdBinarized = 8;
              nonMaxSize = 2): CenSurE[T] =
  let
    imsize = shape[0] * shape[1]
    integralPointer = cast[ptr T](alloc0(imsize * sizeof(T)))
    responsesPointer = cast[ptr float32](alloc0(imsize * sizeof(float32)))
    scalesPointer = cast[ptr uint8](alloc0(imsize * sizeof(uint8)))
  result.start = start
  result.stop = stop
  result.responseThreshold = responseThreshold
  result.lineThresholdProjected = lineThresholdProjected
  result.lineThresholdBinarized = lineThresholdBinarized
  result.nonMaxSize = nonMaxSize
  result.integral = integralPointer.toTensor(shape)
  result.responses = responsesPointer.toTensor(shape)
  result.scales = scalesPointer.toTensor(shape)

proc dispose*[T](censure: CenSurE[T]) =
  dealloc(censure.integral.data)
  dealloc(censure.responses.data)
  dealloc(censure.scales.data)

proc innerFactor(n: int): float32 {. inline .} =
  ## Computes the normalization factor of the
  ## inner box in a difference-of-boxes at a given scale.
  1.0'f32 / pow(2 * n.float32 + 1, 2)
proc outerFactor(n: int): float32 {. inline .} =
  ## Computes the normalization factor of the
  ## outer box in a difference-of-boxes at a given scale.
  1.0'f32 / pow(4 * n.float32 + 1, 2)

proc dobKernel[T](input: TensorLike[T]; idx, idy, n: int): float32 {. inline .} =
  ## Computes the value of the difference-of-boxes
  ## normalized to the previous scale.
  let
    inner = innerFactor(n)
    outer = outerFactor(n)
    largeBox = evalBoxCenter(input, idx, idy, 2 * n) 
    innerBox = evalBoxCenter(input, idx, idy, n)
    outerBox = largeBox# - innerBox
  result += outer * outerBox
  result -= (inner + outer) * innerBox

proc dobLoop[T](input, work: TensorLike[T];
                responses: TensorLike[float32];
                scales: TensorLike[uint8];
                start, stop: int) {. inline .} =
  ## Detects keypoints in input using the censure algorithm.
  ## NOTE: STAR-detector maximum-projects over scale. (makes sense,
  ## as this explicitly enforces scale invariance!)
  let
    border = stop
  minMax(input)
  integrate(input, work)

  for idy in border || (input.size(1) - border - 1):
    for idx in border .. (input.size(0) - border - 1):
      var
        bestResponse: float32 = 0.0
        bestScale: uint8 = 0
      for n in start .. stop:
        let
          response = dobKernel(work, idx, idy, n)
        if abs(response) > abs(bestResponse):
          bestResponse = response
          bestScale = uint8 n
      responses[idx, idy] = bestResponse
      scales[idx, idy] = bestScale

proc suppressLine(responses: TensorLike[float32];
                  scales: TensorLike[uint8];
                  idx, idy: int;
                  lineThresholdProjected = 10;
                  lineThresholdBinarized = 8): bool =
  ## Checks, whether a point is to be suppressed
  ## due to residing on a line.
  result = false
  let
    scale = scales[idx, idy]
    delta0 = int scale div 4
    delta =
      if delta0 == 0:
        1
      else:
        delta0
    radius = int delta * 4
  var
    dx2, dy2, dxy = 0.0'f32
    dbx2, dby2, dbxy = 0

  for wx in countup(idx - radius, idx + radius, delta):
    for wy in countup(idy - radius, idy + radius, delta):
      let
        dx = responses[wx + 1, wy] - responses[wx - 1, wy]
        dy = responses[wx, wy + 1] - responses[wx, wy - 1]
        # dbx = int(scales[wx + 1, wy] == scale) -
        #       int(scales[wx - 1, wy] == scale)
        # dby = int(scales[wx, wy + 1] == scale) -
        #       int(scales[wx, wy - 1] == scale)
      dx2 += dx * dx
      dy2 += dy * dy
      dxy += dx * dy
      # dbx2 += dbx * dbx
      # dby2 += dby * dby
      # dbxy += dbx * dby
  
  if (dx2 + dy2) * (dx2 + dy2) >= (float32 lineThresholdProjected) * (dx2 * dy2 - dxy * dxy):
    return true

  for wx in countup(idx - radius, idx + radius, delta):
    for wy in countup(idy - radius, idy + radius, delta):
      let
        dbx = int(scales[wx + 1, wy] == scale) -
              int(scales[wx - 1, wy] == scale)
        dby = int(scales[wx, wy + 1] == scale) -
              int(scales[wx, wy - 1] == scale)
      dbx2 += dbx * dbx
      dby2 += dby * dby
      dbxy += dbx * dby

  # echo (dbx2 + dby2) * (dbx2 + dby2), " : ", lineThresholdBinarized * (dbx2 * dby2 - dbxy * dbxy)
  if (dbx2 + dby2) * (dbx2 + dby2) >= lineThresholdBinarized * (dbx2 * dby2 - dbxy * dbxy):
    return true

proc detectKeypoints(responses: TensorLike[float32];
                     scales: TensorLike[uint8];
                     keypoints: var Keypoints;
                     responseThreshold = 30'f32;
                     lineThresholdProjected = 10;
                     lineThresholdBinarized = 8;
                     size = 5) =
  const
    minFeature = uint8 1
    maxFeature = uint8 7
  let
    border = size
    xSteps = (responses.size(0) - 2 * border) div size
    ySteps = (responses.size(1) - 2 * border) div size
  for sY in 0 .. (ySteps - 1):
    let
      idy = border + sY * (size + 1)
      yEnd = min(idy + size, responses.size(1) - border)
    for sX in 0 .. (xSteps - 1):
      let
        idx = border + sX * (size + 1)
        xEnd = min(idx + size, responses.size(0) - border)
      var
        maxResponse = responseThreshold
        minResponse = -responseThreshold
        minX, maxX, minY, maxY = -1
      
      # Tiling kernel:
      for tdy in idy .. yEnd:
        for tdx in idx .. xEnd:
          let
            val = responses[tdx, tdy]
          if maxResponse < val:
            maxResponse = val
            maxX = tdx
            maxY = tdy
          elif minResponse > val:
            minResponse = val
            minX = tdx
            minY = tdy
      
      # non maximum suppression:
      block byMax:
        if maxX > 0:
          for tdy in maxY - size .. maxY + size:
            for tdx in maxX - size .. maxX + size:
              let
                val = responses[tdx, tdy]
              if val >= maxResponse and ((tdy != maxY) or (tdx != maxX)):
                break byMax
          
          let
            featureSize = scales[idx, idy]
          if featureSize >= minFeature and (not suppressLine(
            responses, scales, maxX, maxY,
            lineThresholdProjected = lineThresholdProjected,
            lineThresholdBinarized = lineThresholdBinarized
          )):
            let
              keypoint = KeyPoint(
                x: float32 maxX, y: float32 maxY,
                scale: featureSize,
                response: maxResponse
              )
            # keypoints[sY * ySteps + sX] = keypoint
            keypoints.add keypoint

      # non minimum suppression
      block byMin:
        if minX > 0:
          for tdy in minY - size .. minY + size:
            for tdx in minX - size .. minX + size:
              let
                val = responses[tdx, tdy]
              if val <= minResponse and (tdy != minY or tdx != minX):
                break byMin
          
          let
            featureSize = scales[idx, idy]
          if featureSize >= minFeature and (not suppressLine(
            responses, scales, minX, minY,
            lineThresholdProjected = lineThresholdProjected,
            lineThresholdBinarized = lineThresholdBinarized
          )):
            let
              keypoint = KeyPoint(
                x: float32 minX, y: float32 minY,
                scale: featureSize,
                response: maxResponse
              )
            # keypoints[sY * ySteps + sX] = keypoint
            keypoints.add keypoint

proc keypoints*[T](censure: CenSurE[T]; image: TensorLike[T]): KeyPoints =
  dobLoop(
    image,
    censure.integral,
    censure.responses,
    censure.scales,
    censure.start,
    censure.stop
  )
  detectKeypoints(censure.responses,
                  censure.scales,
                  result,
                  responseThreshold = censure.responseThreshold,
                  lineThresholdProjected = censure.lineThresholdProjected,
                  lineThresholdBinarized = censure.lineThresholdBinarized,
                  size = censure.nonMaxSize)
