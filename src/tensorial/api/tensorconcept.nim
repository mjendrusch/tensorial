type
  TensorLike*[T] = concept tensor
    ## Multidimensional array concept.
    var
      idx: int
    tensor.len is int
    tensor.dim is int
    # tensor.shape is seq[int]
    tensor.size(idx) is int
    tensor.reshape(openarray[int]) is type tensor
    tensor.data is ptr T
  StackArray*[T] = object
    length: int
    data: array[7, T]
  SeqTensor*[T] = object
    shape*: StackArray[int]
    stride*: StackArray[int]
    backing: seq[T]
  PtrTensor*[T] = object
    total: int
    shape*: StackArray[int]
    stride*: StackArray[int]
    backing: ptr T
  RGBTensor*[T: TensorLike[uint32]] = distinct T
  YCbCrTensor*[T: TensorLike[uint32]] = distinct T

template len*[T](x: StackArray[T]): int = x.length
template `[]`*[T](x: StackArray[T]; idx: untyped): T = x.data[idx]
template `[]=`*[T](x: StackArray[T]; idx: untyped; val: T) = x.data[idx] = val
proc toStackArray*[T](x: varargs[T]): StackArray[T] =
  result.length = x.len
  for idx in 0 ..< x.len:
    result.data[idx] = x[idx]
template toOpenArray*[T](x: StackArray[T]): openarray[T] =
  x.data.toOpenArray(0, x.len - 1)
iterator items*[T](x: StackArray[T]): T =
  for idx in 0 ..< x.len:
    yield x[idx]
iterator pairs*[T](x: StackArray[T]): tuple[idx: int; val: T] =
  for idx in 0 ..< x.len:
    yield (idx, x[idx])
proc total*[T](x: StackArray[T]): T =
  result = T(1)
  for val in x:
    result *= val

# procedures:
proc shapeToStride*(shape: StackArray[int]): StackArray[int] =
  result.length = shape.len
  result[0] = 1
  for idx in 1 ..< shape.len:
    result[idx] = result[idx - 1] * shape[idx - 1]
proc subToIdx*[T](tensor: TensorLike[T]; sub: varargs[int]): int {. inline .} =
  result = 0
  for idx in 0 ..< sub.len:
    result += tensor.stride[idx] * sub[idx]
proc `[]`*[T](tensor: TensorLike[T]; index: int): var T {. inline .} =
  cast[type tensor.data](cast[int](tensor.data) + index * sizeof(type tensor.data[]))[]
proc `[]=`*[T](tensor: TensorLike[T]; index: int; val: T) {. inline .} =
  cast[ptr T](cast[int](tensor.data) + index * sizeof(T))[] = val
proc `[]`*[T](tensor: TensorLike[T]; idx: varargs[int]): var T {. inline .} =
  var
    index = tensor.subToIdx idx
  tensor[index]
proc `[]=`*[T](tensor: TensorLike[T]; idx: varargs[int]; val: T) {. inline .} =
  var
    index = tensor.subToIdx idx
  tensor[index] = val

# implementation for SeqTensor:
proc len*[T](tensor: SeqTensor[T]): int =
  tensor.backing.len
proc dim*[T](tensor: SeqTensor[T]): int =
  tensor.shape.len
proc size*[T](tensor: SeqTensor[T]; idx: int): int {. inline .} =
  tensor.shape[idx]
proc data*[T](tensor: SeqTensor[T]): ptr T {. inline .} =
  tensor.backing[0].unsafeAddr
proc reshape*[T](tensor: SeqTensor[T]; shape: StackArray[int]): SeqTensor[T] =
  result = SeqTensor[T](shape: shape, stride: shapeToStride(shape), backing: nil)
  shallowCopy(result.backing, tensor.backing)
proc reshape*[T](tensor: SeqTensor[T]; shape: openarray[int]): SeqTensor[T] =
  result = tensor.reshape(shape.toStackArray)

# implementation for PtrTensor:
proc len*[T](tensor: PtrTensor[T]): int =
  tensor.total
proc dim*[T](tensor: PtrTensor[T]): int =
  tensor.shape.len
proc size*[T](tensor: PtrTensor[T]; idx: int): int {. inline .} =
  tensor.shape[idx]
proc data*[T](tensor: PtrTensor[T]): ptr T {. inline .} =
  tensor.backing
proc reshape*[T](tensor: PtrTensor[T]; shape: StackArray[int]): PtrTensor[T] =
  PtrTensor[T](total: tensor.total, shape: shape, stride: shapeToStride(shape), backing: tensor.backing)
proc reshape*[T](tensor: PtrTensor[T]; shape: openarray[int]): PtrTensor[T] =
  tensor.reshape(shape.toStackArray)

proc toTensor*[T](backing: ptr T; shape: StackArray[int]): PtrTensor[T] =
  var
    total = 1
  for elem in shape:
    total *= elem
  PtrTensor[T](total: total, shape: shape, stride: shapeToStride(shape), backing: backing)
proc toTensor*[T](backing: seq[T]; shape: StackArray[int]): SeqTensor[T] =
  result = SeqTensor[T](shape: shape, stride: shapeToStride(shape), backing: nil)
  shallowCopy(result.backing, backing)
proc toTensor*[T](backing: ptr T; shape: openarray[int]): PtrTensor[T] =
  backing.toTensor(shape.toStackArray)
proc toTensor*[T](backing: seq[T]; shape: openarray[int]): SeqTensor[T] =
  backing.toTensor(shape.toStackArray)
proc toRgb*[T: TensorLike[uint32]](tensor: T): auto =
  RGBTensor(tensor)
proc toYCbCr*[T: TensorLike[uint32]](tensor: T): auto =
  YCbCrTensor(tensor)
