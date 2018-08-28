import tensorial
import tensorial / lowlevel
import keypoints, integral
import math, macros, bitops

type
  Freak* = object
  FreakPreFeature = object
    data: array[6 * 7 + 1, float32]
  FreakFeature* = object
    data: array[16, uint64]

let
  pairIds {. compileTime .} = [
    404,431,818,511,181,52,311,874,774,543,719,230,417,205,11,
    560,149,265,39,306,165,857,250,8,61,15,55,717,44,412,
    592,134,761,695,660,782,625,487,549,516,271,665,762,392,178,
    796,773,31,672,845,548,794,677,654,241,831,225,238,849,83,
    691,484,826,707,122,517,583,731,328,339,571,475,394,472,580,
    381,137,93,380,327,619,729,808,218,213,459,141,806,341,95,
    382,568,124,750,193,749,706,843,79,199,317,329,768,198,100,
    466,613,78,562,783,689,136,838,94,142,164,679,219,419,366,
    418,423,77,89,523,259,683,312,555,20,470,684,123,458,453,833,
    72,113,253,108,313,25,153,648,411,607,618,128,305,232,301,84,
    56,264,371,46,407,360,38,99,176,710,114,578,66,372,653,
    129,359,424,159,821,10,323,393,5,340,891,9,790,47,0,175,346,
    236,26,172,147,574,561,32,294,429,724,755,398,787,288,299,
    769,565,767,722,757,224,465,723,498,467,235,127,802,446,233,
    544,482,800,318,16,532,801,441,554,173,60,530,713,469,30,
    212,630,899,170,266,799,88,49,512,399,23,500,107,524,90,
    194,143,135,192,206,345,148,71,119,101,563,870,158,254,214,
    276,464,332,725,188,385,24,476,40,231,620,171,258,67,109,
    844,244,187,388,701,690,50,7,850,479,48,522,22,154,12,659,
    736,655,577,737,830,811,174,21,237,335,353,234,53,270,62,
    182,45,177,245,812,673,355,556,612,166,204,54,248,365,226,
    242,452,700,685,573,14,842,481,468,781,564,416,179,405,35,
    819,608,624,367,98,643,448,2,460,676,440,240,130,146,184,
    185,430,65,807,377,82,121,708,239,310,138,596,730,575,477,
    851,797,247,27,85,586,307,779,326,494,856,324,827,96,748,
    13,397,125,688,702,92,293,716,277,140,112,4,80,855,839,1,
    413,347,584,493,289,696,19,751,379,76,73,115,6,590,183,734,
    197,483,217,344,330,400,186,243,587,220,780,200,793,246,824,
    41,735,579,81,703,322,760,720,139,480,490,91,814,813,163,
    152,488,763,263,425,410,576,120,319,668,150,160,302,491,515,
    260,145,428,97,251,395,272,252,18,106,358,854,485,144,550,
    131,133,378,68,102,104,58,361,275,209,697,582,338,742,589,
    325,408,229,28,304,191,189,110,126,486,211,547,533,70,215,
    670,249,36,581,389,605,331,518,442,822
  ]

macro createSamplePairs: untyped =
  var
    pairs = newSeq[tuple[x, y: int]]()
  result = newTree(nnkStmtList)
  for idx in 1 ..< 6 * 7 + 1:
    for idy in 0 ..< idx:
      pairs.add((idx, idy))
  var
    count = 0
  for idx in pairIds:
    let
      (x, y) = pairs[idx]
    result.add quote do:
      yield (`count`, `x`, `y`)
    inc count

iterator samplePairs(freak: Freak): tuple[k, idx, idy: int] {. inline .} =
  createSamplePairs()

proc `[]`(feature: var FreakPreFeature; index: int): float32 =
  feature.data[index]
proc `[]=`(feature: var FreakPreFeature; index: int; val: float32) =
  feature.data[index] = val
proc `[]`(feature: var FreakPreFeature; idx, idy: int): float32 =
  feature.data[(idx - 1) * 6 + idy + 1]
proc `[]=`(feature: var FreakPreFeature; idx, idy: int; val: float32) =
  feature.data[(idx - 1) * 6 + idy + 1] = val

proc receptiveField[T](integral: TensorLike[T]; idx, idy, size: int): T {. inline .} =
  integral.evalBoxCenter(idx, idy, size) / pow(float32(2 * size + 1), 2)

proc compare(x, y: float32): uint64 = uint64(x > y)

proc describe[T](freak: Freak; integral: TensorLike[T]; point: Keypoint): FreakFeature =
  ## Describes a single keypoint using ``Freak`` features.
  var
    preFeature: FreakPreFeature

  const
    bigR = 2.0'f32 / 3.0'f32
    smallR = 2.0'f32 / 24.0'f32
    unitSpace = (bigR - smallR) / 21.0'f32
    radiusConst = [
      bigR, bigR - 6 * unitSpace, bigR - 11 * unitSpace,
      bigR - 15 * unitSpace, bigR - 18 * unitSpace,
      bigR - 20 * unitSpace, smallR, 0.0
    ]
    sigmaConst = [
      radiusConst[0] / 2.0, radiusConst[1] / 2.0, radiusConst[2] / 2.0,
      radiusConst[3] / 2.0, radiusConst[4] / 2.0, radiusConst[5] / 2.0,
      radiusConst[6] / 2.0, radiusConst[6] / 2.0
    ]
    nOctaves = 4
    nscales = 64
  let
    scaleStep = pow(2'f32, float32(nOctaves) / nscales)
    patternScale = 22.0
  let
    firstSize = 1
    closestX = int round(point.x)
    closestY = int round(point.y)
  preFeature[0] = receptiveField(integral, closestX, closestY, int point.scale)
  for circle in 1 .. 7:
    let
      radius = patternScale * pow(scaleStep, float32(7 - circle)) * float32(radiusConst[7 - circle])# (1 shl circle) div 6
      size = int round(sigmaConst[7 - circle] * pow(scaleStep, float32(7 - circle)) * patternScale)#int round(radius / 2)
    for index in 0 ..< 6:
      let
        alpha = Pi / 3 * float32(index + circle)
        xOffset = cos(alpha) * float32(radius)
        yOffset = sin(alpha) * float32(radius)
        closestX = int round(point.x + xOffset)
        closestY = int round(point.y + yOffset)
      preFeature[circle, index] =
        receptiveField(integral, closestX, closestY, size)
  for k, idx, idy in freak.samplePairs:
    let
      index = k div 64
      shift = k mod 64
      value = compare(preFeature[idx], preFeature[idy])
    result.data[index] = result.data[index] or (value shl shift)

proc describe*[T](freak: Freak; integral: TensorLike[T]; points: openarray[Keypoint]): seq[Descriptor[FreakFeature]] =
  result = newSeq[Descriptor[FreakFeature]](points.len)
  for idx in 0 || points.high:
    result[idx] = descriptor(
      points[idx],
      freak.describe(integral, points[idx])
    )

proc distance(x, y: FreakFeature; qwords = 2): int =
  result = 0
  for idx in 0 ..< qwords:
    result += countSetBits(x.data[idx] xor y.data[idx])

proc matchKernel(res: var seq[Match];
                 x, y: seq[Descriptor[FreakFeature]];
                 index, threshold: int) {. inline .} =
  var
    minDist = 1000000
    minIdx = -1
  for idx in 0 ..< y.len:
    let
      dist = distance(x[index].feature, y[idx].feature, qwords = 16)
    if dist < minDist:
      minDist = dist
      minIdx = idx
  if minDist < threshold:
    res[index] = match(x[index].point, y[minIdx].point, float32 minDist)
  else:
    res[index] = match(x[index].point, y[minIdx].point, -1'f32)
  # var
  #   goodIndices = cast[ptr int](alloc0(y.len * sizeof(int)))
  #   newGoodIndices = cast[ptr int](alloc0(y.len * sizeof(int)))
  #   pos = 0
  # pointerArithmetic:
  #   for idx in 0 ..< y.len:
  #     if distance(x[index].feature, y[idx].feature, qwords = 2) < threshold:
  #       goodIndices[pos] = idx
  #       inc pos
  #   var
  #     currentQWord = 4
  #   while currentQWord <= 16:
  #     var
  #       newPos = 0
  #     for idGood in 0 ..< pos:
  #       let
  #         idx = goodIndices[idGood]
  #       if distance(x[index].feature, y[idx].feature, qwords = currentQWord) < threshold:
  #         newGoodIndices[newPos] = idx
  #         inc newPos
  #     if newPos == 0:
  #       res[index] = match(x[index].point, y[0].point, -1.0'f32)
  #       pos = -1
  #       break
  #     elif newPos == 1:
  #       res[index] = match(x[index].point, y[newGoodIndices[0]].point, float32 distance(
  #         x[index].feature, y[newGoodIndices[0]].feature, qwords = currentQWord)
  #       )
  #       pos = -1
  #       break
  #     let
  #       tmp = goodIndices
  #     goodIndices = newGoodIndices
  #     pos = newPos
  #     newGoodIndices = tmp
  #     currentQWord += 2
  #   if pos > 0:
  #     var
  #       minDist = 100000
  #       minIdx = -1
  #     for idGood in 0 ..< pos:
  #       let
  #         idx = goodIndices[idGood]
  #         dist = distance(
  #           x[index].feature, y[idx].feature, qwords = 16
  #         )
  #       if dist < minDist:
  #         minDist = dist
  #         minIdx = idx
  #     res[index] = match(x[index].point, y[minIdx].point, float32 minDist)
  #   dealloc goodIndices
  #   dealloc newGoodIndices

proc match*(x, y: seq[Descriptor[FreakFeature]];
            threshold: int = 10): seq[Match] =
  result = newSeq[Match](x.len)
  for idx in 0 || (x.len - 1):
    result.matchKernel(x, y, idx, threshold)