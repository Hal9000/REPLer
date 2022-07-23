#!/usr/bin/env ruby

require_relative '../lib/repl'
require 'stringio'

class MyREPL < REPL
  Commands["hmm"] = {}
  Intro = "This is just an intro..."
  Version = "0.0.0"
  Help  = <<~EOS
    If this had been
    actual help information,
    it might have been helpful.
  EOS

  def cmd_hmm
   # num, fname = STDSCR.menu(title: "Edit page:", items: hash.keys + [new_item])
   hash = {"this" => "yo this", "that" => "yo that", "other" => "something else"}
   num, str = STDSCR.menu(title: "Just pick one...", items: hash.keys)
   puts [num, str].inspect
  end

  def self.say_what?
    user = `whoami`
    time = `date`
    pwd  = `pwd`
    box  = `hostname`
    io = StringIO.new
    RubyText.splash do |io|
      io.puts "You are #{user} on #{box}"
      io.puts "in directory #{pwd}"
      io.puts "at #{time}."
      io.puts "That is all."
      io.puts " "
    end
  end

  Menu_items = {
      About:  NotImp,
      Huh:    proc { say_what? },
      Help:   proc { RubyText.splash("No soup for you!") },
      Quit:   proc { exit }
    }

  def cmd_foo
    puts "Aha! I see you have issued the foo command!\n "
  end

  def cmd_bar
    NotImp.call
  end

  def cmd_hmmm(*args)
    puts "Hmmm... I got some arguments! #{args.inspect}\n "
  end
end

x = MyREPL.new
x.topmenu = true

x.run

