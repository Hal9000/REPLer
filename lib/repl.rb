##  Signal.trap("INT") { puts "Don't  :)" }

require 'rubytext'

### Menu...

require 'ostruct'

class REPL
  Menu = OpenStruct.new
  BlankLine = "\n "

  def retrieve(sym)  # const or class instance variable
    name = sym.to_s
    if name =~ /^[A-Z]/
      self.class.const_get(sym)
    else
      self.class.class_eval("@" + sym.to_s)
    end
  rescue 
    "Error: '#{sym}' is undefined"
  end

  def initialize
    @topmenu = false
    @stderr = STDERR
  end

  def topmenu=(bool)
    @topmenu = bool
  end

  def stderr=(where)
    if where == STDERR
      @stderr = STDERR
    else
      fd = File.new(where, "w")
      @stderr = STDERR.reopen(fd)
    end
  end

  def edit(str)
    proc { edit_file(str) }
  end

  NotImp = proc { RubyText.splash("Not implemented yet") }

  TopHelp = proc do 
    RubyText.splash <<~EOS
      This is help info...
      Blah blah blah...
      The end.
    EOS
  end

  Menu.top_items = {
      About:  NotImp,
      Help:   TopHelp,
      Quit:   proc { cmd_quit }
    }

  def show_top_menu
    r, c = STDSCR.rc
    items = retrieve(:Menu_items)
    return(puts "No menu items") if items.nil?
    result = STDSCR.topmenu(items: items)
    STDSCR.go r+1, 0
    result
  end

# require 'exceptions'

  Commands = {
#   "foo"  => {abbr: "f", method: sym_or_proc, param: {[:optional, :list], list: list_or_proc}}
# add desc: later?
    "help"     => {abbr: "h"},    # method: defaults to :cmd_foo
    "version"  => {abbr: "v"},
    "clear"    => {},
    "quit"     => {abbr: "q"}
   }

  Patterns = {}
  Abbr = {}


#   Patterns = 
#     {"help"              => :cmd_help, 
#      "h"                 => :cmd_help,
#      "version"           => :cmd_version,
#      "v"                 => :cmd_version,
#      "clear"             => :cmd_clear,
#      "q"                 => :cmd_quit,
#      "quit"              => :cmd_quit
#    }
# 
#   Abbr = {
#      "h"                 => :cmd_help,
#      "v"                 => :cmd_version,
#      "q"                 => :cmd_quit
#      }
  
  def choose_method(cmdline)
    verb, *args = cmdline.strip.split
    meth = Patterns[verb]
    return [:cmd_INVALID, verb] if meth.nil?
    return [meth, *args] if self.respond_to?(meth)
    return [:cmd_INVALID, verb]
  end

  def ask(prompt, meth = :to_s)
    print prompt
    gets.chomp.send(meth)
  end

  def ask!(prompt, meth = :to_s)
    ask(fx(prompt, :bold), meth)
  end

  def get_integer(arg)
    Integer(arg) 
  rescue 
    raise ArgumentError, "'#{arg}' is not an integer"
  end

  def check_file_exists(file)
    raise FileNotFound(file) unless File.exist?(file)
  end

  def error_cant_delete(files)
    case files
      when String
        raise CantDelete(files)
      when Array
        raise CantDelete(files.join("\n"))
    end
  end

  def cmd_help
    puts retrieve(:Help) + BlankLine
  end

  def cmd_quit
    STDSCR.rows.times { puts " "*(STDSCR.cols-1) }
    STDSCR.clear
    sleep 0.1
    RubyText.stop
    sleep 0.1
    # system("clear")
    exit
  end

  def cmd_clear
    STDSCR.rows.times { puts " "*(STDSCR.cols-1) }
    # sleep 0.1
    STDSCR.clear
  end

  def cmd_version
    puts retrieve(:Version) + BlankLine
  end

  def fresh?(src, dst)
    return false unless File.exist?(dst)
    File.mtime(src) <= File.mtime(dst)
  end

  def cmd_INVALID(arg)
    print fx("\n  Command ", :bold)
    print fx(arg, Red, :bold)
    puts fx(" was not understood.\n ", :bold)
  end

## Other stuff...

  def set_prompt(str, color = Red, style = :bold)
    @prompt = fx(str, color, style)
  end

  private def dunno(cmd)
    print "\n  Invalid command "
    print fx(cmd.inspect, Red, :bold)
    puts  "\n "
  end

  private def loop_logic
    print @prompt
    cmd = STDSCR.gets(history: @cmdhist, tab: @tabcom, capture: [" "])
    case cmd
      when " ", RubyText::Keys::Escape
        show_top_menu if @topmenu  # Do nothing if menu not enabled
        puts
        return
      when RubyText::Keys::CtlD    # ^D
        cmd_quit
      when String
        cmd.chomp!
        return if cmd.empty?  # CR does nothing
        invoking = choose_method(cmd)
        dunno(cmd) if invoking.nil?
        begin
          ret = send(*invoking) 
        rescue => e
          puts "Error: #{e}\n "
        end
    else
      dunno(cmd)
    end
  rescue => err
    puts "Error in loop_logic: Current dir = #{Dir.pwd}"
    puts err
    puts err.backtrace.join("\n")
    puts "Pausing..."; gets
  end

  def mainloop
    loop { loop_logic }
    exit_repl
  end

  def check_ruby_version(needed)
    major, minor = RUBY_VERSION.split(".").values_at(0, 1)
    ver = major.to_i*10 + minor.to_i
    need1, need2 = needed.split(".").values_at(0, 1)
    need = major.to_i*10 + minor.to_i
    unless ver >= need
      RubyText.stop
      sleep 0.2
      puts "Needs Ruby #{need1}.#{need2} or greater" 
      exit
    end
  end

  def reopen_stderr(name)
    errfile = File.new(name, "w")
    STDERR.reopen(errfile)
  end

  def set_terminal(fg = Blue, bg = Black)
    @fg = fg.downcase.to_sym
    @bg = bg.downcase.to_sym
    RubyText.start(:_echo, :keypad, :cbreak, scroll: true, fg: @fg, bg: @bg, log: "rtlog.txt")
  end

  def print_intro
    text = retrieve(:Intro)
    puts retrieve(:Intro) + "\n"
  end

  def command_history_etc
    Commands.each_pair do |verb, hash|
      meth =  "cmd_#{verb}".to_sym
      Patterns[verb] = meth
      abbr = hash[:abbr]
      if abbr
        Patterns[abbr] = meth
        Abbr[abbr] = meth
      end
    end

    @cmdhist = []
    @tabcom = Patterns.keys.uniq - Abbr.keys
    @tabcom.map! {|x| x.sub(/ [\$\>].*/, "") + " " }
    @tabcom.sort!
  end

  def exit_repl
    sleep 0.2
    puts
  end

  def run
    @stderr = "stderr.txt"
    set_terminal(White, Black)
    set_prompt("> ", Red, :bold)
    print_intro
    command_history_etc
    mainloop
  end

end
