import tensorconcept
import tensorcomplex

when true:
  import fft/ffts
  export ffts
when false:
  import fft/pffft
else:
  import fft/fftfallback

proc fft*(ctx: FftContext; input: TensorLike[float32];
             output: TensorLike[Complex64]) =
  ctx.perform(input.data, output.data)

proc fft*(ctx: FftContext; input: TensorLike[Complex64];
             output: TensorLike[Complex64]) =
  ctx.perform(input.data, output.data)

proc fft*(ctx: FftContext; input: TensorLike[Complex128];
             output: TensorLike[Complex128]) =
  ctx.perform(input.data, output.data)

proc fft*(ctx: FftContext; input: TensorLike[Complex64];
          output: TensorLike[float32]) =
  ctx.perform(input.data, output.data)

proc sameAs*[T](x: StackArray[T]; y: StackArray[T]): bool {. inline .} =
  result = true
  for idx in 0 ..< x.len:
    if x[idx] != y[idx]: return false

proc fft*(input: TensorLike[Complex64];
          output: TensorLike[Complex64];
          direction = FFTDirection.forward) =
  var
    sizes {. global .}: StackArray[int]
    ctx {. global .}: FFTContext
  if sizes.len == 0 or not sizes.sameAs(input.shape):
    sizes = input.shape
    ctx = newContext(FFTType.complex, direction, sizes.toOpenArray)
  ctx.fft(input, output)

proc fft*(input: TensorLike[Complex128];
          output: TensorLike[Complex128];
          direction = FFTDirection.forward) =
  var
    sizes {. global .}: seq[int]
    ctx {. global .}: FFTContext
  if sizes.len == 0 or not sizes.sameAs(input.shape):
    sizes = input.shape
    ctx = newContext(FFTType.complex, direction, sizes.toOpenArray)
  ctx.fft(input, output)

proc realFft*(input: TensorLike[float32];
              output: TensorLike[Complex64]) =
  var
    sizes {. global .}: StackArray[int]
    ctx {. global .}: FFTContext
  if sizes.len == 0 or not sizes.sameAs(input.shape):
    sizes = input.shape
    ctx = newContext(FFTType.real, FFTDirection.forward, sizes.toOpenArray)
  ctx.fft(input, output)

proc realInverseFft*(input: TensorLike[Complex64];
                     output: TensorLike[float32]) =
  var
    sizes {. global .}: StackArray[int]
    ctx {. global .}: FFTContext
  if sizes.len == 0 or not sizes.sameAs(input.shape):
    sizes = input.shape
    ctx = newContext(FFTType.real, FFTDirection.reverse, sizes.toOpenArray)
  ctx.fft(input, output)