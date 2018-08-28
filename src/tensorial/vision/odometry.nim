import tensorial

type
  Displacement* {. bycopy .} = object
    dx*, dy*, dz*: float32
    rx*, ry*, rz*: float32
  Velocity* {. bycopy .} = object
    vx*, vy*, vz*: float32
    wx*, wy*, wz*: float32
  Displacement2D* {. bycopy .} = object
    dx*, dy*: float32
    rz*: float32
  Velocity2D* {. bycopy .} = object
    vx*, vy*: float32
    wz*: float32

  SomeDisplacement* = Displacement or Displacement2D
  SomeVelocity* = Velocity or Velocity2D

  Odometry* = concept odometry
    var
      environment: auto
    odometry.position is SomeDisplacement
    odometry.velocity is SomeVelocity
    odometry.update(environment)

proc `+=`*(x: var Displacement, y: Displacement) =
  x.dx += y.dx
  x.dy += y.dy
  x.dz += y.dz
  x.rx += y.rx
  x.ry += y.ry
  x.rz += y.rz

proc `+=`*(x: var Velocity, y: Velocity) =
  x.vx += y.vx
  x.vy += y.vy
  x.vz += y.vz
  x.wx += y.wx
  x.wy += y.wy
  x.wz += y.wz

proc `+=`*(x: var Displacement2D, y: Displacement2D) =
  x.dx += y.dx
  x.dy += y.dy
  x.rz += y.rz

proc `+=`*(x: var Velocity2D, y: Velocity2D) =
  x.vx += y.vx
  x.vy += y.vy
  x.wz += y.wz

proc `-=`*(x: var Displacement, y: Displacement) =
  x.dx -= y.dx
  x.dy -= y.dy
  x.dz -= y.dz
  x.rx -= y.rx
  x.ry -= y.ry
  x.rz -= y.rz

proc `-=`*(x: var Velocity, y: Velocity) =
  x.vx -= y.vx
  x.vy -= y.vy
  x.vz -= y.vz
  x.wx -= y.wx
  x.wy -= y.wy
  x.wz -= y.wz

proc `-=`*(x: var Displacement2D, y: Displacement2D) =
  x.dx -= y.dx
  x.dy -= y.dy
  x.rz -= y.rz

proc `-=`*(x: var Velocity2D, y: Velocity2D) =
  x.vx -= y.vx
  x.vy -= y.vy
  x.wz -= y.wz

proc `+`*(x, y: SomeDisplacement): type x =
  result = x
  result += y

proc `-`*(x, y: SomeVelocity): type x =
  result = x
  result -= y
