use "random"
use "collections"

type Share is (U128, U128)

primitive Mersenne
  fun apply(): U128 =>
    // 12th Mersenne prime
    F64(2).pow(127.0).floor().u128() - 1

class _RandomP
  let _p: U128
  let _r: Rand

  new create(p: U128 = Mersenne()) =>
    _p = p
    _r = Rand

  fun ref apply(): U128 =>
    _r.u128().rem(_p)

primitive SSS
  fun _easy_generate(secret: U128, shares: USize, random: _RandomP): Array[Share] =>
    // If t = n, we can use modular arithmetic to divide the secret into
    // n-1 numbers (v_i, i = 1..n-1), and then v_n = (secret - v_1 - ... - v_{n-1})
    // After that, we know that secret = \sum_0^{n-1} v_i
    // This works because overflow semantics are well defined modulo 2^128
    let repr = Array[Share].create(shares)
    let shares' = shares.u128()

    var remaining = secret
    for i in Range[U128](1, shares' - 1) do // Skip secret
      let v_secret = secret + random()
      repr.push((i, v_secret))
      remaining = remaining - v_secret
    end
    repr.push((shares', remaining))
    repr

  fun apply(secret: U128,
            threshold: USize,
            shares: USize,
            prime: U128 = Mersenne()): Array[Share] =>

    let random = _RandomP(prime)
    if (threshold == shares) then
      return _easy_generate(secret, shares, random)
    end

    // First, generate t random numbers, with the secret at repr(0)
    let repr = Array[U128].create(threshold)
    repr.push(secret)
    for i in Range(1, threshold) do
      repr.push(random())
    end

    // Next, we evaluate the polynomial at x \in {1..t}
    // (skip x=0, as that is secret)
    let points = Array[Share].create(shares)
    for x in Range[U128](1, shares.u128() + 1) do
      let y = _eval_at(repr, x, prime)
      points.push((x, y))
    end

    points

  fun _eval_at(poly: Array[U128], x: U128, prime: U128): U128 =>
    var res: U128 = 0
    try
      for idx in Range(poly.size() - 1, -1, -1) do
        res = _mul_mod(res, x, prime)
        // Ignore error because index is always well defined
        res = _add_mod(res, poly(idx)?, prime)
      end
    end
    res

  fun _easy_recover(shares: Array[Share]): U128 =>
    // See _easy_generate
    var secret: U128 = 0
    for v in shares.values() do
      secret = secret + v._2
    end
    secret

  fun recover_secret(threshold: USize,
                     share_s: USize,
                     shares: Array[Share],
                     prime: U128 = Mersenne()): U128? =>

    if threshold == share_s then
      return _easy_recover(shares)
    end

    if shares.size() == 1 then
      // If there's one share, then shares[0] == secret
      error
    else
      _interpolate(shares, prime)?
    end

  fun _interpolate(shares: Array[Share], prime: U128): U128? =>
    var acc: U128 = 0
    for (x_j, y_j) in shares.values() do
      let l_j = _lagrange_poly_at(x_j, shares, prime)?
      acc = _add_mod(acc, _mul_mod(y_j, l_j, prime), prime)
    end
    acc

  fun _lagrange_poly_at(x_j: U128, xs: Array[Share], prime: U128): U128? =>
    var acc: U128 = 1
    for (x, _) in xs.values() do
      if x != x_j then
        let dem = _sub_mod(x, x_j, prime)
        let div = _div_mod(x, dem, prime)?
        acc = _mul_mod(acc, div, prime)
      end
    end
    acc

    // _add_mod and _sub_mod implementations come from
    // Arndr, Jörg - Matters Computational
    // https://www.jjj.de/fxt/fxtbook.pdf
    fun _add_mod(a: U128, b: U128, p: U128): U128 =>
      let b' = p - b
      if (a >= b') then
        a - b'
      else
        (p - b') + a
      end

    fun _sub_mod(a: U128, b: U128, p: U128): U128 =>
      if (a >= b) then
        a - b
      else
        (p - b) + a
      end

    // _mul_mod taken from https://stackoverflow.com/a/20975702
    fun _mul_mod(a: U128, b: U128, p: U128): U128 =>
      if (a == 0) or (b == 0) then
        return 0
      end

      if (a == 1) then
        return b
      end

      if (b == 1) then
        return a
      end

      let a' = _mul_mod(a, b/2, p)
      if (b.rem(2) == 0) then // Even
        _add_mod(a', a', p)
      else
        _add_mod(a, _add_mod(a', a', p), p)
      end

  // Since (n / m) is n * 1/m, (n / m) mod p is n * m^-1 mod p
  fun _div_mod(n: U128, m: U128, p: U128): U128? =>
    _mul_mod(n, _inverse(m, p)?, p)

  // Implementation taken from
  // https://en.wikipedia.org/wiki/Extended_Euclidean_algorithm#Modular_integers
  fun _inverse(m: U128, p: U128): U128? =>
    (var t, var new_t) = (I128(0), I128(1))
    (var r, var new_r) = (p.i128(), m.i128()) // So we don't underflow
    while new_r != 0 do
      let quot = r / new_r
      (t, new_t) = (new_t, t - (quot * new_t))
      (r, new_r) = (new_r, r - (quot * new_r))
    end

    if r > 1 then
      error // No inverse in P
    end

    if t < 0 then
      t = t + p.i128()
    end

    t.u128().rem(p)
