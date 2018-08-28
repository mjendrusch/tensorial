# tensorial
# Copyright Michael
# Algorithms for a simple tensor concept.
import tensorial/api/[tensorconcept, tensorfft, tensorcomplex]
export tensorconcept, tensorfft, tensorcomplex
import times

when defined(openmp):
  {. passC: "-fopenmp" .}
  {. passL: "-fopenmp" .}

template timeit*(ntimes, body: untyped): untyped =
  body
  block:
    let
      repeatCount = ntimes
      current = epochTime()
    for idx in 0 ..< repeatCount:
      body
    echo (epochTime() - current) / float(repeatCount)