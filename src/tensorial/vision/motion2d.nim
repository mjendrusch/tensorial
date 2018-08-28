import tensorial
import keypoints

type
  Displacement* = object
    dx*, dy*: float32
    alpha*: float32
  MeanTranslation* = object
  CorrelationTranslation* = object
  SubPixelCorrelationTranslation* = object

proc displacement*(dx, dy, alpha: float32): Displacement =
  Displacement(
    dx: dx, dy: dy, alpha: alpha
  )

proc `+`*(x, y: Displacement): Displacement =
  displacement(x.dx + y.dx, x.dy + y.dy, x.alpha + y.alpha)

proc `-`*(x, y: Displacement): Displacement =
  displacement(x.dx - y.dx, x.dy - y.dy, x.alpha - y.alpha)

proc `+=`*(x: var Displacement; y: Displacement): Displacement =
  x.dx += y.dx
  x.dy += y.dy
  x.alpha += y.alpha

proc `-=`*(x: var Displacement; y: Displacement): Displacement =
  x.dx -= y.dx
  x.dy -= y.dy
  x.alpha -= y.alpha

proc estimate*(context: MeanTranslation;
               matches: seq[Match]): Displacement =
  var
    dx, dy, alpha = 0.0'f32
    valid = 0
  for match in matches:
    if match.distance >= 0:
      dx += match.dx
      dy += match.dy
      valid += 1
  dx /= float32 valid
  dy /= float32 valid
  result = displacement(dx, dy, alpha)

proc estimate*(context: CorrelationTranslation;
               phaseCorrelation: TensorLike[float32]): Displacement =
  var
    max = 0'f32
    maxX, maxY = 0'f32
  for idy in 0 ..< phaseCorrelation.size(1):
    for idx in 0 ..< phaseCorrelation.size(0):
      let
        val = phaseCorrelation[idx, idy]
      if val > max:
        max = val
        maxX = float32(phaseCorrelation.size(0) - idx)
        maxY = float32(phaseCorrelation.size(1) - idy)
  displacement(maxX, maxY, 0'f32)

proc estimate*(context: SubPixelCorrelationTranslation;
               phaseCorrelation: TensorLike[float32]): Displacement =
  var
    max = 0'f32
    maxX, maxY = 0
    dXS, dYS = 0'f32
  for idy in 0 ..< phaseCorrelation.size(1):
    for idx in 0 ..< phaseCorrelation.size(0):
      let
        val = phaseCorrelation[idx, idy]
      if val > max:
        max = val
        maxX = idx
        maxY = idy
  let
    valXP = phaseCorrelation[maxX + 1, maxY]
    valXM = phaseCorrelation[maxX - 1, maxY]
    valYP = phaseCorrelation[maxX, maxY + 1]
    valYM = phaseCorrelation[maxX, maxY - 1]
  dXS =
    if valXP > valXM:
      valXP / (valXP + max)
    else:
      valXM / (valXM + max)
  dYS =
    if valYP > valYM:
      valYP / (valYP + max)
    else:
      valYM / (valYM + max)
  if not (-1 <= dXS and dXS <= 1):
    dXS =
      if valXP > valXM:
        valXP / (valXP - max)
      else:
        valXM / (valXM - max)
  if not (-1 <= dYS and dYS <= 1):
    dYS =
      if valYP > valYM:
        valYP / (valYP - max)
      else:
        valYM / (valYM - max)
  displacement(
    float32(phaseCorrelation.size(0)) - float32(maxX) + dXS,
    float32(phaseCorrelation.size(1)) - float32(maxY) + dYS,
    0'f32
  )
