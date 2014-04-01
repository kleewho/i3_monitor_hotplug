#!/usr/bin/env ruby

require 'json'
require 'yaml'
require 'logger'

$log = Logger.new('/var/log/hotplug_rb.log')

def i3_workspaces()
  JSON.parse(i3_msg 'get_workspaces')
end

def move_workspaces_from_disabled_outputs()
  all_outputs = i3_outputs
  active_outputs = all_outputs.reject {|o| o['active']}
    .map {|o| o['name']}
  disabled_outputs = all_outputs.select {|o| o['active']}
    .map {|o| o['name']}

  i3_workspaces.select {|ws| disabled_outputs.include? ws['output']}
    .each {|ws| move_workspace_to_output(ws, active_outputs.first)}
end

#def workspace_on_disabled_output?(workspace, active_outputs)

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
  JSON.parse(i3_msg 'get_outputs')
end

def i3_workspaces()
  JSON.parse(i3_msg 'get_workspaces')
end

def get_current_workspace()
  workspaces.select {|ws| ws['focused']} .first['name']
end

def preserve_current(&command)
  current_workspace = get_current_workspace
  result = command.call
  i3_set_current current_workspace
  result
end

def move_workspace_to_output(workspace, output)
  preserve_current {move_workspace_to_output!(workspace, output)}
end

def move_workspace_to_output!(workspace, output)
  i3_set_current workspace
  i3_command "move workspace to output #{output}"
end

def xrandr_outputs()
  `xrandr -q`.split("\n").select {|l| l.include? ' connected '}
    .map {|l| l.split().first}
end

def xrandr_disconnected_outputs()
  `xrandr -q`.split("\n").select {|l| l.include? ' disconnected '}
    .map {|l| l.split().first}
end

def i3_active_outputs()
  i3_outputs.select {|o| o['active']}
    .map{|o| o['name']}
end

def switch_off(outputs)
  cmd = 'xrandr' + outputs.map{|o| " --output #{o} --off"}.reduce(:+)
  `#{cmd}`
end

def switch_on(config)
  cmd = 'xrandr' + config.map do |output|
    name = output.keys.first
    ' --output ' + name + output[name]['options'].inject(''){|r, o| r + " --#{o}"}
  end.reduce(:+)
  `#{cmd}`
end

def read_xrandr_config()
  YAML.load_file('/home/lukasz/Dokumenty/Projekty/i3_monitor_hotplug/xrandr.yaml')
end

def init()
  $log.debug 'init'
  $log.debug 'Running hotplug.rb as ' + `whoami`

  xrandr_outputs_count = xrandr_outputs.count
  i3_active_outputs_count = i3_active_outputs.count
  if xrandr_outputs_count > i3_active_outputs_count

    $log.info 'switching on'
    switch_on read_xrandr_config['monitors'][xrandr_outputs_count]
  end

  if xrandr_outputs_count < i3_active_outputs_count
    $log.info 'switching off'
    switch_off xrandr_disconnected_outputs
  end
end

init
