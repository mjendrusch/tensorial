##
##
##  This file is part of FFTS.
##
##  Copyright (c) 2012, Anthony M. Blake
##  All rights reserved.
##
##  Redistribution and use in source and binary forms, with or without
##  modification, are permitted provided that the following conditions are met:
##  Redistributions of source code must retain the above copyright
##  		notice, this list of conditions and the following disclaimer.
##  Redistributions in binary form must reproduce the above copyright
##  		notice, this list of conditions and the following disclaimer in the
##  		documentation and/or other materials provided with the distribution.
##  Neither the name of the organization nor the
## 	  names of its contributors may be used to endorse or promote products
##  		derived from this software without specific prior written permission.
##
##  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
##  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
##  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
##  DISCLAIMED. IN NO EVENT SHALL ANTHONY M. BLAKE BE LIABLE FOR ANY
##  DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
##  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
##  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
##  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
##  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
##  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
##
##

{. passL: "-lffts" .}

const
  FFTS_FORWARD* = (-1)
  FFTS_BACKWARD* = (+1)

type
  FftsPlan* = ptr object

##  Complex data is stored in the interleaved format
##    (i.e, the real and imaginary parts composing each
##    element of complex data are stored adjacently in memory)
##
##    The multi-dimensional arrays passed are expected to be
##    stored as a single contiguous block in row-major order
##

proc init1d*(n: csize; sign: cint): FftsPlan {. importc: "ffts_init_1d", cdecl .}
proc init2d*(n1: csize; n2: csize; sign: cint): FftsPlan {. importc: "ffts_init_2d", cdecl .}
proc initNd*(rank: cint; ns: ptr csize; sign: cint): FftsPlan {. importc: "ffts_init_nd", cdecl .}
##  For real transforms, sign == FFTS_FORWARD implies a real-to-complex
##    forwards tranform, and sign == FFTS_BACKWARD implies a complex-to-real
##    backwards transform.
##
##    The output of a real-to-complex transform is N/2+1 complex numbers,
##    where the redundant outputs have been omitted.
##

proc init1dReal*(n: csize; sign: cint): FftsPlan {. importc: "ffts_init_1d_real", cdecl .}
proc init2dReal*(n1: csize; n2: csize; sign: cint): FftsPlan {. importc: "ffts_init_2d_real", cdecl .}
proc initNdReal*(rank: cint; ns: ptr csize; sign: cint): FftsPlan {. importc: "ffts_init_nd_real", cdecl .}
proc execute*(p: FftsPlan; input: pointer; output: pointer) {. importc: "ffts_execute", cdecl .}
proc free*(p: FftsPlan) {. importc: "ffts_free", cdecl .}
