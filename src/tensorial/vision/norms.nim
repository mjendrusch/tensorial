import tensorial
import math

proc minMax*[T; U: SomeFloat](input: TensorLike[T]; output: TensorLike[U]) {. inline .} =
  var
    min = U(1000000)
    max = U(0)
  for idx in 0 ..< input.len:
    if U(input[idx]) < min:
      min = U(input[idx])
    elif U(input[idx]) > max:
      max = U(input[idx])
  for idx in 0 || (input.len - 1):
    output[idx] = (U(input[idx]) - min) / (max - min)

proc minMax*[T: SomeFloat](input: TensorLike[T]) =
  var
    min = T(1000000)
    max = T(0)
  for idx in 0 ..< input.len:
    if input[idx] < min:
      min = input[idx]
    elif input[idx] > max:
      max = input[idx]
  for idx in 0 || (input.len - 1):
    input[idx] = (input[idx] - min) / (max - min)