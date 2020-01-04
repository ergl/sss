use "random"
use "collections"
use "debug"

type Share is (U128, U128)

primitive Mersenne
  fun apply(): U128 =>
    // 8th Mersenne prime is the last Mernsenne prime to fit into a U128
    F64(2).pow(61.0).floor().u128() - 1

class RandomP
  let _p: U128
  let _r: Rand

  new create(p: U128 = Mersenne()) =>
    _p = p
    _r = Rand

  fun ref apply(): U128 =>
    _r.u128().rem(_p)

primitive SSS
  fun apply(threshold: USize,
             shares: USize,
             prime: U128 = Mersenne()): (U128, Array[Share])? =>

    let repr = Array[U128].create(threshold)
    let r = RandomP(prime)
    for i in Range(0, threshold) do
      repr.push(r())
    end

    let points = Array[Share].create(shares)
    for i in Range[U128](1, shares.u128() + 1) do
      let secret = _eval_at(repr, i, prime)
      points.push((i, secret))
    end

    (repr(0)?, points)

  fun _eval_at(poly: Array[U128], x: U128, prime: U128): U128 =>
    var res: U128 = 0
    try
      for idx in Range(poly.size() - 1, -1, -1) do
        res = ((res * x) + poly(idx)?).rem(prime)
      end
    end
    res

  fun recover_secret(shares: Array[Share], prime: U128 = Mersenne()): U128? =>
    if shares.size() < 2 then
      error
    else
      _interpolate(shares, prime)?
    end

  fun _interpolate(shares: Array[Share], prime: U128): U128? =>
    var acc: U128 = 0
    for (x, y) in shares.values() do
      Debug.out("Calculating lagrange_" + x.string())
      let l_j = _lagrange_poly_at(x, shares, prime)?
      Debug.out("lagrange_" + x.string() + ": " + l_j.string())
      acc = acc + (y * l_j)
    end
    acc.rem(prime)

  fun _lagrange_poly_at(x_j: U128, xs: Array[Share], prime: U128): U128? =>
    var acc: U128 = 1
    for (x, _) in xs.values() do
      if x != x_j then
        Debug.out("x_m: " + x.string())
        let dem = if x > x_j then
          x - x_j
        else // x_j > x
          prime - (x_j - x)
        end
        Debug.out("x_m - x_j: " + x.string() + " - " + x_j.string() + " = " + dem.string())
        let div = _div_mod(x, dem, prime)?
        Debug.out("x_m / (x_m - x_j): " + div.string())
        acc = try (acc *? div).rem(prime) else Debug.out("Overflow during l"); error end
        // acc = (acc * div).rem(prime)
      end
    end

    acc.u128()

  // Since (n / m) is n * 1/m, (n / m) mod p is n * m^-1 mod p
  fun _div_mod(n: U128, m: U128, p: U128): U128? =>
    (n * _inverse(m, p)?).rem(p)

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


actor Main
  new create(env: Env) =>
    try
     (let secret, let shares) = SSS(3, 6)?
      env.out.print("Secret is " + secret.string())
      env.out.print("Shares:")
      for i in Range(0, shares.size()) do
        (let idx, let value) = shares(i)?
        env.out.print("(" + idx.string() + "," + value.string() + ")")
      end

      let result_no_threshold = SSS.recover_secret([shares(0)?; shares(1)?])?
      env.out.print("Result (under threshold): " + result_no_threshold.string())
      let result_threshold = SSS.recover_secret([shares(0)?; shares(1)?; shares(5)?])?
      env.out.print("Result (with threshold): " + result_threshold.string())
      let result_all = SSS.recover_secret(shares)?
      env.out.print("Result (with all shares): " + result_all.string())
    end