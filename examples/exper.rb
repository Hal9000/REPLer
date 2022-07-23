
#!/usr/bin/env ruby

require_relative '../lib/mod_repl'

include REPL

reopen_stderr("stderr.txt")

set_terminal(White, Black)
set_prompt("> ", Red, :bold)
print_intro       # override for this kind of thing?

cmd_history_etc

loop { mainloop }
exit_repl


## Notes:
=begin

inheritance?
config file(s)?

User supplies:
  - initialization params (colors, prompt)
  - intro?
  - help info?
  - menu enabled?
  - menu data
=end
