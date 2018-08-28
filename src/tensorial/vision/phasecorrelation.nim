import tensorial

proc alignedAlloc(alignment, size: csize): pointer {.
  importc: "aligned_alloc", header: "<stdlib.h>"
.}

type
  PhaseCorrelation* = object
    xw, yw: PtrTensor[Complex64]
    correlation*: PtrTensor[float32]

proc correlate*(x: TensorLike[Complex64],
                y: TensorLike[Complex64],
                corr: TensorLike[Complex64]) {. inline .} =
  for idx in 0 || (x.len - 1):
    corr[idx] = conjugate(Complex64(x[idx])) * Complex64(y[idx])
    corr[idx] = Complex64(corr[idx]) / abs(Complex64(corr[idx]))

proc correlate*(x, y, corr: TensorLike[float32]; 
                xw, yw: TensorLike[Complex64]) {. inline .} =
  realFFT(x, xw)
  realFFT(y, yw)
  correlate(xw, yw, xw)
  realInverseFFT(xw, corr)

proc init*(typ: typedesc[PhaseCorrelation];
           shape: StackArray[int]): PhaseCorrelation =
  let
    xwPtr = cast[ptr Complex64](alignedAlloc(csize 32, shape.total * 2 * sizeof(float32)))
    ywPtr = cast[ptr Complex64](alignedAlloc(csize 32, shape.total * 2 * sizeof(float32)))
    cPtr =  cast[ptr float32](alignedAlloc(csize 32, shape.total * sizeof(float32)))
    xw = xwPtr.toTensor(shape)
    yw = ywPtr.toTensor(shape)
    correlation = cPtr.toTensor(shape)
  PhaseCorrelation(
    xw: xw, yw: yw, correlation: correlation
  )

proc dispose*(corr: PhaseCorrelation) =
  dealloc corr.xw.data
  dealloc corr.yw.data
  dealloc corr.correlation.data

proc update*(corr: var PhaseCorrelation; input: TensorLike[float32]) =
  let
    tmp = corr.xw.data
  corr.xw = corr.yw.data.toTensor(corr.yw.shape)
  corr.yw = tmp.toTensor(corr.xw.shape)
  realFFT(input, corr.yw)

proc correlate*(corr: PhaseCorrelation) =
  correlate(corr.xw, corr.yw, corr.xw)
  realInverseFFT(corr.xw, corr.correlation)

proc projectX[T](input, output: TensorLike[T]) =
  for idx in 0 || input.size(0) - 1:
    output[idx] = T(0)
    for idy in 0 ..< input.size(1):
      output[idx] += input[idx, idy]

proc projectY[T](input, output: TensorLike[T]) =
  for idx in 0 || input.size(1) - 1:
    output[idx] = T(0)
    for idy in 0 ..< input.size(0):
      output[idx] += input[idy, idx]

proc correlate1D(x, y, corr: TensorLike[float32];
                 xproj, yproj: TensorLike[float32];
                 xw, yw: TensorLike[float32]) =
  projectX(x, xproj)
  projectX(y, yproj)
  realFFT(xproj, xw)
  realFFT(yproj, yw)
  for idx in 0 || (xw.len - 1):
    xw[idx] = phase(conjugate(xw[idx]) * yw[idx])
  realInverseFFT(xw, xproj)
  realInverseFFT(yw, yproj)
  # TODO: compute offset in x
  
  projectY(x, xproj)
  projectY(y, yproj)
  realFFT(xproj, xw)
  realFFT(yproj, yw)
  for idx in 0 || (xw.len - 1):
    xw[idx] = phase(conjugate(xw[idx]) * yw[idx])
  realInverseFFT(xw, xproj)
  realInverseFFT(yw, yproj)
  # TODO: compute offset in y