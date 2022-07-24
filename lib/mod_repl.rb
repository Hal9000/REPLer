##  require 'runeblog'
##  require 'ostruct'
##  require 'helpers-repl'  # FIXME structure
##  require 'pathmagic'
##  require 'exceptions'
##  
##  require 'menus'
##  
##  Signal.trap("INT") { puts "Don't  :)" }

require 'rubytext'

### Menu...

require 'ostruct'

module REPL
  Menu = OpenStruct.new

  def topmenu=(bool)
    @topmenu = bool
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
      Quit:   proc { REPL.cmd_quit }
    }

  def show_top_menu
    r, c = STDSCR.rc
    STDSCR.topmenu(items: Menu.top_items)
    STDSCR.go r-1, 0
  end

# require 'exceptions'

  Patterns = 
    {"help"              => :cmd_help, 
     "h"                 => :cmd_help,
     "version"           => :cmd_version,
     "v"                 => :cmd_version,
     "clear"             => :cmd_clear,
     "q"                 => :cmd_quit,
     "quit"              => :cmd_quit
   }

  Abbr = {
     "h"                 => :cmd_help,
     "v"                 => :cmd_version,
     "q"                 => :cmd_quit
     }
  
  Regexes = {}
  Patterns.each_pair do |pat, meth|
    rx = "^" + pat
    rx.gsub!(/ /, " +")
    rx.gsub!(/\$(\w+) */) { " *(?<#{$1}>\\w+)" }
    # FIXME - detect when command is missing an arg
    # How to handle multiple optional args?
    rx.sub!(/>(\w+)$/) { "(.+)" }
    rx << "$"
    rx = Regexp.new(rx)
    Regexes[rx] = meth
  end

  def self.choose_method(cmd)
    cmd = cmd.strip
    found = nil
    params = nil
    Regexes.each_pair do |rx, meth|
      m = cmd.match(rx)
      result = m ? m.to_a : nil
      next unless result
      found = meth
      params = m[1]
    end
    meth = found || :cmd_INVALID
    params = cmd if meth == :cmd_INVALID
    result = [meth]
    result << params unless params.nil?
    result
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

  def fresh?(src, dst)
    return false unless File.exist?(dst)
    File.mtime(src) <= File.mtime(dst)
  end

  def cmd_INVALID(arg)
    print fx("\n  Command ", :bold)
    print fx(arg, Red, :bold)
    puts fx(" was not understood.\n ", :bold)
  end

  Help = <<-EOS

  {Basics:}                                         {Views:}
  -------------------------------------------       -------------------------------------------
  {h, help}           This message                  {change view VIEW}  Change current view
  {q, quit}           Exit the program              {cv VIEW}           Change current view
  {v, version}        Print version information     {new view}          Create a new view
  {clear}             Clear screen                  {list views}        List all views available
                                                    {lsv}               Same as: list views
                   

  {Posts:}                                          {Advanced:}
  -------------------------------------------       -------------------------------------------
  {p, post}           Create a new post             {config}            Edit various system files
  {new post}          Same as p, post                
  {lsp, list posts}   List posts in current view    {preview}           Look at current (local) view in browser
  {lsd, list drafts}  List all drafts (all views)   {browse}            Look at current (published) view in browser
  {delete ID [ID...]} Remove multiple posts         {rebuild}           Regenerate all posts and relink
  {undelete ID}       Undelete a post               {publish}           Publish (current view)
  {edit ID}           Edit a post                   {ssh}               Login to remote server
  {import ASSETS}     Import assets (images, etc.)  


  {Widgets:}
  -------------------------------------------       
  {lsw, list widgets} List all known widgets
  {install WIDGET}    Install a widget
  {enable WIDGET}     Use widget in this view
  {disable WIDGET}    Don't use in this view
  {update WIDGET}     Update code (this view)
  {manage WIDGET}     Manage content/layout 

  EOS

  def cmd_help
    msg = Help
    msg.each_line do |line|
      e = line.each_char
      first = true
      loop do
        s1 = ""
        c = e.next
        if c == "{"
          s2 = first ? "" : "  "
          first = false
          loop do 
            c = e.next
            break if c == "}"
            s2 << c
          end
          print fx(s2, :bold)
          s2 = ""
        else
          s1 << c
        end
        print s1
      end
    end
    puts
  end

## Other stuff...

  def set_prompt(str, color = Red, style = :bold)
    @prompt = fx(str, color, style)
  end

  def mainloop
    print @prompt
    cmd = STDSCR.gets(history: @cmdhist, tab: @tabcom, capture: [" "])
    case cmd
      when " ", RubyText::Keys::Escape
        # FIXME - do nothing if menu not enabled
        show_top_menu
        puts
        return
      when RubyText::Keys::CtlD    # ^D
        REPL.cmd_quit
      when String
        cmd.chomp!
        return if cmd.empty?  # CR does nothing
        invoking = REPL.choose_method(cmd)
        ret = send(*invoking)
    else
      puts "Don't understand '#{cmd.inspect}'\n "
    end
  rescue => err
    # log!(str: err.to_s)
    # log!(str: err.backtrace.join("\n")) if err.respond_to?(:backtrace)
    puts "Current dir = #{Dir.pwd}"
    puts err
    puts err.backtrace.join("\n")
    puts "Pausing..."; gets
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
    print fx("  For help", :bold)
    puts ", type h or help.\n "
  end

  def cmd_history_etc
    @cmdhist = []
    @tabcom = REPL::Patterns.keys.uniq - REPL::Abbr.keys
    @tabcom.map! {|x| x.sub(/ [\$\>].*/, "") + " " }
    @tabcom.sort!
  end

  def exit_repl
    sleep 0.2
    puts
  end

end
