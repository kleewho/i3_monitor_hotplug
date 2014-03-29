#!/usr/bin/env ruby

require 'json'

def move_workspaces_from_disabled_outputs()
  active_outputs = outputs

  workspaces.reject{ |ws|
    ws['output'] == active_outputs.first['name']
  }.each{ |ws|
    move_workspace_to_output(ws, active_outputs.first['name'])
  }
end

def workspaces()
  JSON.parse(i3_workspaces)
end

def outputs()
  JSON.parse(i3_outputs).reject{|output| output['active'] == false}
end

def i3_set_current(workspace)
  i3_command "workspace #{workspace}"
end

def i3_msg(command)
  `i3-msg -t #{command}`
end

def i3_command(command)
#  JSON.parse(i3_msg "command #{command}")[0]["success"]
  i3_msg "command #{command}"
end

def i3_outputs()
  i3_msg 'get_outputs'
end

def i3_workspaces()
  i3_msg 'get_workspaces'
end

def get_current_workspace()
  workspaces.select{ |ws| ws['focused'] }.first['name']
end

def preserve_current(command)
  current_workspace = get_current_workspace
  result = command.call
  i3_set_current current_workspace
  result
end

def move_workspace_to_output(workspace, output)
  preserve_current(lambda{move_workspace_to_output!(workspace, output)})
end

def move_workspace_to_output!(workspace, output)
  i3_set_current workspace
  i3_command "move workspace to output #{output}"
end

def init()
  puts "Init"
end

workspaces
outputs
init
