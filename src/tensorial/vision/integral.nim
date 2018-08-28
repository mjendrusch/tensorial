import tensorial
import math

when defined(openmp):
  proc integrate*[T](input, output: TensorLike[T]) {. inline .} =
    ## Produces an integral output image from an input image,
    ## using OpenMP for parallelization.
    for idy in 0 || (input.size(1) - 1):
      output[0, idy] = input[0, idy]
      for idx in 1 ..< input.size(0):
        output[idx, idy] = input[idx, idy] + output[idx - 1, idy]
    for idx in 0 || (input.size(0) - 1):
      for idy in 1 ..< input.size(1):
        output[idx, idy] += output[idx, idy - 1]
else:
  proc integrate*[T](input, output: TensorLike[T]) =
    ## Produces an integral output image from an input image.
    output[0, 0] = input[0, 0]
    for idx in 1 ..< input.size(0):
      output[idx, 0] = input[idx, 0] + output[idx - 1, 0]
    for idy in 1 ..< input.size(1):
      output[0, idy] = input[0, idy] + output[0, idy - 1]
      for idx in 1 ..< input.size(0):
        output[idx, idy] = (
          input[idx, idy] +
          output[idx - 1, idy] +
          output[idx, idy - 1] +
          output[idx - 1, idy - 1]
        )

proc evalBoxCenter*[T](input: TensorLike[T];
                         idx, idy, n: int): float32 {. inline .} =
  ## Computes the value of a box in a difference-of-boxes
  ## at a given scale.
  result = float32(
    input[idx + n, idy + n] +
    input[idx - n, idy - n] -
    input[idx - n, idy + n] -
    input[idx + n, idy - n]
  )

proc evalBoxCorner*[T](input: TensorLike[T];
                       idx, idy, width, height: int): float32 {. inline .} =
  ## Computes the value of a box in a difference-of-boxes
  ## at a given scale.
  result = float32(
    input[idx, idy] +
    input[idx + width, idy + height] -
    input[idx, idy + height] -
    input[idx + width, idy]
  )
