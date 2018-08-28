{. compile: "pffft/pffft.c" .}

type
  Plan* = ptr object
  Direction* {. pure .} = enum
    forward, reverse
  Type* {. pure .} = enum
    real, complex
