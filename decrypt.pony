use "term"
use "promises"

primitive Input
  fun encrypt(env: Env, threshold: U64, total: U64): InputNotify iso^ =>
    let term = _make_ansiterm(env, recover _EncryptNotify(env.out, threshold, total) end)
    env.out.print("Generating shares using a (" + threshold.string() + "," + total.string() + ") scheme.")
    term.prompt("Enter the secret, at most 16 ASCII characters: ")
    _to_notify(term)

  fun decrypt(env: Env, threshold: U64, total: U64): InputNotify iso^ =>
    let term = _make_ansiterm(env, recover _DecryptNotify(env.out, threshold, total) end)
    env.out.print("Enter " + threshold.string() + " shares below")
    term.prompt("Share [1/" + threshold.string() + "]: ")
    _to_notify(term)

  fun _make_ansiterm(env: Env, notify: ReadlineNotify iso): ANSITerm =>
    ANSITerm(Readline(consume notify, env.out), env.input)

  fun _to_notify(term: ANSITerm): InputNotify iso^ =>
    object iso
      let term: ANSITerm = term
      fun ref apply(data: Array[U8] iso) => term(consume data)
      fun ref dispose() => term.dispose()
    end

primitive StringToUInt
  fun encode(str: String val): U128? =>
    let bytes = str.array()
    let limit = bytes.size().min(16)
    var acc: U128 = 0
    var offset: U128 = 0
    var idx: USize = 0
    while idx < limit do
      acc = acc + (bytes(((limit - 1) - idx))?.u128() << offset)
      idx = idx + 1
      offset = offset + 8
    end
    acc

  fun decode(n: U128): String val =>
    let bytes = recover Array[U8].create(16) end
    var offset: U128 = 0
    while offset <= 120 do
      let value = (n >> offset).u8()
      if value == 0 then
        break
      else
        bytes.unshift(value)
      end
      offset = offset + 8
    end
    String.from_array(consume bytes)

class _EncryptNotify is ReadlineNotify
  let _out: OutStream
  let _threshold: USize
  let _total: USize

  new create(out: OutStream, threshold: U64, total: U64) =>
    _out = out
    _threshold = threshold.usize()
    _total = total.usize()

  fun ref apply(line: String val, prompt: Promise[String val] tag) =>
    prompt.reject()
    if line.size() > 16 then
      _out.print("Error: Line too long")
      return
    end

    try
      let secret = StringToUInt.encode(line)?
      let shares = SSS(secret, _threshold, _total)
      for share in shares.values() do
        _out.print(ShareIO.encode(share))
      end
    else
      _out.print("Invalid secret, please use only valid ASCII characters")
    end

  fun ref tab(line: String val): Seq[String val] box => []

class _DecryptNotify is ReadlineNotify
  embed _shares: Array[Share]
  var _current_share: USize
  let _threshold: USize
  let _share_total: USize
  let _out: OutStream

  new create(out: OutStream, threshold: U64, total: U64) =>
    _out = out
    _current_share = 1
    _threshold = threshold.usize()
    _share_total = total.usize()

    _shares = Array[Share].create(threshold.usize())

  fun ref apply(line: String val, prompt: Promise[String val] tag) =>
    try _shares.push(ShareIO.decode(line)?) end
    if _current_share == _threshold then
      prompt.reject()
      try
        let result = SSS.recover_secret(_threshold, _share_total, _shares)?
        let str = StringToUInt.decode(result)
        _out.print("Resulting secret: " + str)
      end
    else
      _current_share = _current_share + 1
      prompt("Share [" + _current_share.string() + "/" + _threshold.string() + "]: ")
    end

  fun ref tab(line: String val): Seq[String val] box => []
