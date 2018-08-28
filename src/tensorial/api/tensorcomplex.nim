import math

const
  EPS = 1.0e-7 ## Epsilon used for float comparisons.

type
  Complex*[T] = object
    re*, im*: T
  Complex64* = Complex[float32]
  Complex128* = Complex[float64]

proc complex*[T](re, im: T): Complex[T] = 
  result.re = re
  result.im = im

# proc toComplex*(x: SomeInteger): Complex =
#   ## Convert some integer ``x`` to a complex number.
#   result.re = x
#   result.im = 0

# proc `==` *(x, y: Complex): bool =
#   ## Compare two complex numbers `x` and `y` for equality.
#   result = x.re == y.re and x.im == y.im

# proc `=~` *(x, y: Complex): bool =
#   ## Compare two complex numbers `x` and `y` approximately.
#   result = abs(x.re-y.re)<EPS and abs(x.im-y.im)<EPS

# proc `+` *(x, y: Complex): Complex =
#   ## Add two complex numbers.
#   result.re = x.re + y.re
#   result.im = x.im + y.im

# proc `+` *(x: Complex, y: float): Complex =
#   ## Add complex `x` to float `y`.
#   result.re = x.re + y
#   result.im = x.im

# proc `+` *(x: float, y: Complex): Complex =
#   ## Add float `x` to complex `y`.
#   result.re = x + y.re
#   result.im = y.im


# proc `-` *(z: Complex): Complex =
#   ## Unary minus for complex numbers.
#   result.re = -z.re
#   result.im = -z.im

# proc `-` *(x, y: Complex): Complex =
#   ## Subtract two complex numbers.
#   result.re = x.re - y.re
#   result.im = x.im - y.im

# proc `-` *(x: Complex, y: float): Complex =
#   ## Subtracts float `y` from complex `x`.
#   result = x + (-y)

# proc `-` *(x: float, y: Complex): Complex =
#   ## Subtracts complex `y` from float `x`.
#   result = x + (-y)


# proc `/` *(x, y: Complex): Complex =
#   ## Divide `x` by `y`.
#   var
#     r, den: float
#   if abs(y.re) < abs(y.im):
#     r = y.re / y.im
#     den = y.im + r * y.re
#     result.re = (x.re * r + x.im) / den
#     result.im = (x.im * r - x.re) / den
#   else:
#     r = y.im / y.re
#     den = y.re + r * y.im
#     result.re = (x.re + r * x.im) / den
#     result.im = (x.im - r * x.re) / den

proc `/` *[T](x : Complex[T], y: T): Complex[T] =
  ## Divide complex `x` by float `y`.
  result.re = x.re/y
  result.im = x.im/y

# proc `/` *(x : float, y: Complex ): Complex =
#   ## Divide float `x` by complex `y`.
#   var num : Complex = (x, 0.0)
#   result = num/y


proc `*`*[T](x, y: Complex[T]): Complex[T] =
  ## Multiply `x` with `y`.
  result.re = x.re * y.re - x.im * y.im
  result.im = x.im * y.re + x.re * y.im

# proc `*` *(x: float, y: Complex): Complex =
#   ## Multiply float `x` with complex `y`.
#   result.re = x * y.re
#   result.im = x * y.im

# proc `*` *(x: Complex, y: float): Complex =
#   ## Multiply complex `x` with float `y`.
#   result.re = x.re * y
#   result.im = x.im * y


# proc `+=` *(x: var Complex, y: Complex) =
#   ## Add `y` to `x`.
#   x.re += y.re
#   x.im += y.im

# proc `+=` *(x: var Complex, y: float) =
#   ## Add `y` to the complex number `x`.
#   x.re += y

# proc `-=` *(x: var Complex, y: Complex) =
#   ## Subtract `y` from `x`.
#   x.re -= y.re
#   x.im -= y.im

# proc `-=` *(x: var Complex, y: float) =
#   ## Subtract `y` from the complex number `x`.
#   x.re -= y

# proc `*=` *(x: var Complex, y: Complex) =
#   ## Multiply `y` to `x`.
#   let im = x.im * y.re + x.re * y.im
#   x.re = x.re * y.re - x.im * y.im
#   x.im = im

# proc `*=` *(x: var Complex, y: float) =
#   ## Multiply `y` to the complex number `x`.
#   x.re *= y
#   x.im *= y

proc `/=`*[T](x: var Complex[T], y: Complex[T]) =
  ## Divide `x` by `y` in place.
  x = x / y

proc `/=`*[T](x : var Complex[T], y: float) =
  ## Divide complex `x` by float `y` in place.
  x.re /= y
  x.im /= y

proc abs*[T](z: Complex[T]): T =
  ## Return the distance from (0,0) to `z`.

  # optimized by checking special cases (sqrt is expensive)
  var x, y, temp: T

  x = abs(z.re)
  y = abs(z.im)
  if x == 0.0:
    result = y
  elif y == 0.0:
    result = x
  elif x > y:
    temp = y / x
    result = x * sqrt(1.0 + temp * temp)
  else:
    temp = x / y
    result = y * sqrt(1.0 + temp * temp)


proc conjugate*[T](z: Complex[T]): Complex[T] =
  ## Conjugate of complex number `z`.
  result.re = z.re
  result.im = -z.im


# proc sqrt*(z: Complex): Complex =
#   ## Square root for a complex number `z`.
#   var x, y, w, r: float

#   if z.re == 0.0 and z.im == 0.0:
#     result = z
#   else:
#     x = abs(z.re)
#     y = abs(z.im)
#     if x >= y:
#       r = y / x
#       w = sqrt(x) * sqrt(0.5 * (1.0 + sqrt(1.0 + r * r)))
#     else:
#       r = x / y
#       w = sqrt(y) * sqrt(0.5 * (r + sqrt(1.0 + r * r)))
#     if z.re >= 0.0:
#       result.re = w
#       result.im = z.im / (w * 2.0)
#     else:
#       if z.im >= 0.0: result.im = w
#       else:           result.im = -w
#       result.re = z.im / (result.im + result.im)


# proc exp*(z: Complex): Complex =
#   ## e raised to the power `z`.
#   var rho   = exp(z.re)
#   var theta = z.im
#   result.re = rho*cos(theta)
#   result.im = rho*sin(theta)


# proc ln*(z: Complex): Complex =
#   ## Returns the natural log of `z`.
#   result.re = ln(abs(z))
#   result.im = arctan2(z.im,z.re)

# proc log10*(z: Complex): Complex =
#   ## Returns the log base 10 of `z`.
#   result = ln(z)/ln(10.0)

# proc log2*(z: Complex): Complex =
#   ## Returns the log base 2 of `z`.
#   result = ln(z)/ln(2.0)


# proc pow*(x, y: Complex): Complex =
#   ## `x` raised to the power `y`.
#   if x.re == 0.0  and  x.im == 0.0:
#     if y.re == 0.0  and  y.im == 0.0:
#       result.re = 1.0
#       result.im = 0.0
#     else:
#       result.re = 0.0
#       result.im = 0.0
#   elif y.re == 1.0  and  y.im == 0.0:
#     result = x
#   elif y.re == -1.0  and  y.im == 0.0:
#     result = 1.0/x
#   else:
#     var rho   = sqrt(x.re*x.re + x.im*x.im)
#     var theta = arctan2(x.im,x.re)
#     var s     = pow(rho,y.re) * exp(-y.im*theta)
#     var r     = y.re*theta + y.im*ln(rho)
#     result.re = s*cos(r)
#     result.im = s*sin(r)


# proc sin*(z: Complex): Complex =
#   ## Returns the sine of `z`.
#   result.re = sin(z.re)*cosh(z.im)
#   result.im = cos(z.re)*sinh(z.im)

# proc arcsin*(z: Complex): Complex =
#   ## Returns the inverse sine of `z`.
#   var i: Complex = (0.0,1.0)
#   result = -i*ln(i*z + sqrt(1.0-z*z))

# proc cos*(z: Complex): Complex =
#   ## Returns the cosine of `z`.
#   result.re = cos(z.re)*cosh(z.im)
#   result.im = -sin(z.re)*sinh(z.im)

# proc arccos*(z: Complex): Complex =
#   ## Returns the inverse cosine of `z`.
#   var i: Complex = (0.0,1.0)
#   result = -i*ln(z + sqrt(z*z-1.0))

# proc tan*(z: Complex): Complex =
#   ## Returns the tangent of `z`.
#   result = sin(z)/cos(z)

# proc arctan*(z: Complex): Complex =
#   ## Returns the inverse tangent of `z`.
#   var i: Complex = (0.0,1.0)
#   result = 0.5*i*(ln(1-i*z)-ln(1+i*z))

# proc cot*(z: Complex): Complex =
#   ## Returns the cotangent of `z`.
#   result = cos(z)/sin(z)

# proc arccot*(z: Complex): Complex =
#   ## Returns the inverse cotangent of `z`.
#   var i: Complex = (0.0,1.0)
#   result = 0.5*i*(ln(1-i/z)-ln(1+i/z))

# proc sec*(z: Complex): Complex =
#   ## Returns the secant of `z`.
#   result = 1.0/cos(z)

# proc arcsec*(z: Complex): Complex =
#   ## Returns the inverse secant of `z`.
#   var i: Complex = (0.0,1.0)
#   result = -i*ln(i*sqrt(1-1/(z*z))+1/z)

# proc csc*(z: Complex): Complex =
#   ## Returns the cosecant of `z`.
#   result = 1.0/sin(z)

# proc arccsc*(z: Complex): Complex =
#   ## Returns the inverse cosecant of `z`.
#   var i: Complex = (0.0,1.0)
#   result = -i*ln(sqrt(1-1/(z*z))+i/z)


# proc sinh*(z: Complex): Complex =
#   ## Returns the hyperbolic sine of `z`.
#   result = 0.5*(exp(z)-exp(-z))

# proc arcsinh*(z: Complex): Complex =
#   ## Returns the inverse hyperbolic sine of `z`.
#   result = ln(z+sqrt(z*z+1))

# proc cosh*(z: Complex): Complex =
#   ## Returns the hyperbolic cosine of `z`.
#   result = 0.5*(exp(z)+exp(-z))

# proc arccosh*(z: Complex): Complex =
#   ## Returns the inverse hyperbolic cosine of `z`.
#   result = ln(z+sqrt(z*z-1))

# proc tanh*(z: Complex): Complex =
#   ## Returns the hyperbolic tangent of `z`.
#   result = sinh(z)/cosh(z)

# proc arctanh*(z: Complex): Complex =
#   ## Returns the inverse hyperbolic tangent of `z`.
#   result = 0.5*(ln((1+z)/(1-z)))

# proc sech*(z: Complex): Complex =
#   ## Returns the hyperbolic secant of `z`.
#   result = 2/(exp(z)+exp(-z))

# proc arcsech*(z: Complex): Complex =
#   ## Returns the inverse hyperbolic secant of `z`.
#   result = ln(1/z+sqrt(1/z+1)*sqrt(1/z-1))

# proc csch*(z: Complex): Complex =
#   ## Returns the hyperbolic cosecant of `z`.
#   result = 2/(exp(z)-exp(-z))

# proc arccsch*(z: Complex): Complex =
#   ## Returns the inverse hyperbolic cosecant of `z`.
#   result = ln(1/z+sqrt(1/(z*z)+1))

# proc coth*(z: Complex): Complex =
#   ## Returns the hyperbolic cotangent of `z`.
#   result = cosh(z)/sinh(z)

# proc arccoth*(z: Complex): Complex =
#   ## Returns the inverse hyperbolic cotangent of `z`.
#   result = 0.5*(ln(1+1/z)-ln(1-1/z))

proc phase*[T](z: Complex[T]): T =
  ## Returns the phase of `z`.
  arctan2(z.im, z.re)

# proc polar*(z: Complex): tuple[r, phi: float] =
#   ## Returns `z` in polar coordinates.
#   result.r = abs(z)
#   result.phi = phase(z)

# proc rect*(r: float, phi: float): Complex =
#   ## Returns the complex number with polar coordinates `r` and `phi`.
#   result.re = r * cos(phi)
#   result.im = r * sin(phi)


proc `$`*[T](z: Complex[T]): string =
  ## Returns `z`'s string representation as ``"(re, im)"``.
  result = "(" & $z.re & ", " & $z.im & ")"