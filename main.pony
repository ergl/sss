use "collections"

type Share is (U128, U128)

primitive Mersenne
  fun apply(): U128 =>
    // 12th Mersenne prime
    F64(2).pow(127.0).floor().u128() - 1


actor Main
  new create(env: Env) =>
    try
      let t: USize = 3
      let n: USize = 6
      let secret: U128 = 1234567890
      let shares = SSS(secret, t, n)
      env.out.print("Secret is " + secret.string())
      env.out.print("Shares:")
      for i in Range(0, shares.size()) do
        (let idx, let value) = shares(i)?
        env.out.print("(" + idx.string() + "," + value.string() + ")")
      end

      let result_no_threshold = SSS.recover_secret(t, n, [shares(0)?; shares(1)?])?
      env.out.print("Result (under threshold): " + result_no_threshold.string())
      let result_threshold = SSS.recover_secret(t, n, [shares(0)?; shares(1)?; shares(2)?])?
      env.out.print("Result (with threshold): " + result_threshold.string())
      let result_all = SSS.recover_secret(t, n, shares)?
      env.out.print("Result (with all shares): " + result_all.string())
    end
