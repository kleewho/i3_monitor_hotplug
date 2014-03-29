#!/usr/bin/env ruby

require 'json'

def workspaces()
  workspaces = JSON.parse(i3_workspaces)
  puts workspaces
end

def outputs()
  outputs = JSON.parse(i3_outputs).reject{|output| output['active'] == false}
  puts outputs
  puts "Outputs"
end

def i3_msg(command)
  `i3-msg -t #{command}`
end

def i3_command(command)
  i3_msg "command #{command}"
end

def i3_outputs()
  i3_msg 'get_outputs'
end

def i3_workspaces()
  i3_msg 'get_workspaces'
end

def init()
  puts "Init"
end

workspaces
outputs
init
