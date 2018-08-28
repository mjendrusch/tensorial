import ffts/fftsapi

type
  FFTContext* = FftsPlan
  FFTDirection* {. pure .} = enum
    forward, reverse
  FFTType* {. pure .} = enum
    real, complex

proc newContext*(typ: FFTType; direction: FFTDirection;
                 sizes: openarray[csize]): FFTContext =
  let
    sign = case direction
      of FFTDirection.forward:
        cint -1
      of FFTDirection.reverse:
        cint 1
  case typ
  of FFTType.real:
    result = initNDReal(sizes.len.cint, sizes[0].unsafeAddr, sign)
  of FFTType.complex:
    result = initND(sizes.len.cint, sizes[0].unsafeAddr, sign)

proc dispose*(ctx: FFTContext) =
  free ctx

proc perform*(ctx: FFTContext; input, output: pointer) =
  ctx.execute(input, output)