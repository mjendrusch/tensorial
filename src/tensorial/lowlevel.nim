template pointerArithmetic*(body: untyped): untyped =
  template `[]`[T](p: ptr T; offset: int): var T {. inject .} =
    cast[ptr T](cast[int](p) + offset * sizeof(T))[]
  template `[]=`[T](p: ptr T; offset: int; val: T) {. inject .} =
    cast[ptr T](cast[int](p) + offset * sizeof(T))[] = val
  body