use "buffered"
use "encode/base64"

primitive ShareEncoder
  fun encode(share: Share): String val =>
    let wb = Writer
    wb.u128_be(share._1)
    wb.u128_be(share._2)
    Base64.encode(try wb.done()(0)? else "" end)

  fun decode(str: String val): Share? =>
    let rb = Reader
    let bytes = Base64.decode(str)?
    rb.append(consume bytes)
    let x = rb.u128_be()?
    let y = rb.u128_be()?
    (x, y)

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
