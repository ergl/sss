use cli = "cli"

primitive Encrypt
primitive Decrypt
type Mode is (Encrypt | Decrypt)

class val SSSConfig
  var mode: Mode = Encrypt
  var threshold: U64 = 0
  var shares: U64 = 0

primitive Config
  fun _spec(): cli.CommandSpec? =>
    cli.CommandSpec.leaf(
      "sss",
      "A simple Shamir's secret sharing program",
      [
        cli.OptionSpec.bool(
          "encrypt",
          "Tells sss to encrypt a secret",
          'e',
          true
        )
        cli.OptionSpec.bool(
          "decrypt",
          "Tells sss to decrypt a secret",
          'd',
          false
        )
        cli.OptionSpec.u64(
          "threshold",
          "Share threshold to recover the secret",
          't'
        )
        cli.OptionSpec.u64(
          "shares",
          "Number of shares to generate",
          'n'
        )
      ]
    )?.>add_help()?

  fun _parse(env: Env): cli.Command? =>
    let spec = _spec()?
    match cli.CommandParser(spec).parse(env.args)
    | let c: cli.Command => c
    | let  c: cli.CommandHelp =>
      c.print_help(env.out)
      env.exitcode(0)
      error
    | let err: cli.SyntaxError =>
      env.err.print(err.string())
      let help = cli.Help.general(spec)
      help.print_help(env.err)
      env.exitcode(1)
      error
    end

  fun apply(env: Env): SSSConfig? =>
    let cmd = _parse(env)?
    let config = SSSConfig

    let encrypt = cmd.option("encrypt").bool()
    let decrypt = cmd.option("decrypt").bool()

    config.mode = if decrypt == true then Decrypt else Encrypt end
    config.threshold = cmd.option("threshold").u64()
    config.shares = cmd.option("shares").u64()
    config
