use "term"
use "buffered"
use "encode/base64"

type Share is (U128, U128)

primitive Mersenne
  fun apply(): U128 =>
    // 12th Mersenne prime
    F64(2).pow(127.0).floor().u128() - 1

class ShareIO
  let _reader: Reader = Reader
  let _writer: Writer = Writer

  fun ref encode(share: Share): String iso^ =>
    _writer.u128_be(share._1)
    _writer.u128_be(share._2)
    Base64.encode(try _writer.done()(0)? else "" end)

  fun ref decode(str: String box): Share? =>
    let bytes = Base64.decode(str)?
    _reader.append(consume bytes)
    let x = _reader.u128_be()?
    let y = _reader.u128_be()?
    _reader.clear()
    (x, y)

actor Main
  new create(env: Env) =>
    try
      let config = Config(env)?
      let notify = match config.mode
      | Encrypt => Input.encrypt(env, config.threshold, config.shares)
      | Decrypt => Input.decrypt(env, config.threshold, config.shares)
      end
      env.input(consume notify)
    end
