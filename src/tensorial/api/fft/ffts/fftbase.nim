when true:
  import ffts
else:
  import fftfallback

type
  Plan* = ref object
    data*: ptr FftsPlan
  Sign* = enum
    Forward = -1, Reverse = 1

proc dispose(pln: Plan) = free(pln.data)

proc plan*(sizes: seq[csize]; sign: Sign): Plan =
  new result, dispose
  result.data = initND(sizes.len.cint, sizes[0].unsafeAddr, sign.cint)

proc planReal*(sizes: varargs[csize]; sign: Sign): Plan =
  new result, dispose
  result.data = initNDReal(sizes.len.cint, sizes[0].unsafeAddr, sign.cint)

proc execute*(pln: Plan; input, output: pointer) =
  GC_ref pln
  execute(pln.data, input, output)
  GC_unref pln

proc sameAs*[T](x: varargs[T]; y: openarray[T]): bool {. inline .} =
  result = true
  for idx in 0 ..< x.len:
    if x[idx] != y[idx]: return false

template executeCache*(sizes: varargs[csize]; sign: Sign; input, output: pointer): untyped =
  var
    cachedSizes {. global .}: seq[csize]
    cachedPlan {. global .}: Plan
  if cachedSizes.isNil or not sizes.sameAs cachedSizes:
    cachedSizes = @sizes
    cachedPlan = plan(sizes, sign)
  execute(cachedPlan, input, output)

template cachePlan*(sizes: varargs[csize]; sign: Sign): untyped =
  ## Creates variables and functions for dft execution with a cached plan.
  mixin sameAs
  var
    cachedSizes {. global .}: seq[csize]
    cachedPlan {. global .}: Plan
  if cachedSizes.isNil or not (sizes.sameAs cachedSizes):
    cachedSizes = @sizes
    cachedPlan = plan(cachedSizes, sign)
  template execute(input, output: pointer): untyped =
    execute(cachedPlan, input, output)
