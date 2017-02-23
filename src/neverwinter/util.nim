import streams, encodings

# -----------------------
#  IO and error handling
# -----------------------

proc readStrChunked*(io: Stream, size: int): TaintedString =
  ## Read size bytes from stream, in chunks as to avoid memory contention.

  result = ""
  var remaining = size

  while remaining > 0:
    let want = min(remaining, 1024)
    let buf = io.readStr(want)
    if buf.len == 0 or buf.len < want: raise newException(IOError,
      "wanted to read " & $want & " but only got " & $buf.len)
    remaining -= buf.len
    result &= buf

proc readStrOrErr*(io: Stream, size: int): string =
  ## Reads a string of exactly size bytes off io, or error out.
  result = io.readStrChunked(size)

template expect*(cond: bool, msg: string = "") =
  ## Expect `cond` to be true, otherwise raise a ValueError.
  ## This works analogous to doAssert, except for the error type.

  bind instantiationInfo
  {.line: instantiationInfo().}:
    if not cond:
      let expmsg =
        if msg != "": msg
        else: "Expectation failed: " & astToStr(cond)
      raise newException(ValueError, expmsg)



# ----------
#  Encoding
# ----------

const NwnEncoding = "windows-1252"
template toNwnEncoding*(s: string): string = s.convert(NwnEncoding, getCurrentEncoding())
template fromNwnEncoding*(s: string): string = s.convert(getCurrentEncoding(), NwnEncoding)

# --------------------------------
#  Other helpers/stdlib additions
# --------------------------------

proc map*[T, R](data: openArray[T],
                op: proc(idx: int, x: T): R {.closure.}): seq[R] {.inline.} =
  ## same as sequtil.map(), except that it yields the index too.
  newSeq[R](result, data.len)
  for i in 0..<data.len: result[i] = op(i, data[i])