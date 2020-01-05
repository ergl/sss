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
