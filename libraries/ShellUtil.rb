#
# Cookbook Name:: gecos-ws-mgmt
# Class ShellUtil
#
# NOTE: this class depends on ShellOut module
#
# Copyright 2018, Junta de Andalucia
# http://www.juntadeandalucia.es/
#
# All rights reserved - EUPL License V 1.1
# http://www.osor.eu/eupl
#

require 'chef/shell_out'

# Utility class used to work with ShellOut module
class ShellUtil
  #
  # Invokes shell_out function
  #
  def self.shell(command)
    Chef::Log.debug("shell('#{command}')")
    cmd = Mixlib::ShellOut.new(command)
    cmd.environment = { 'HOME' => '/root', 'XAUTHORITY' => '' }
    cmd.run_command
    unless cmd.exitstatus.zero?
      Chef::Log.warn("Error #{cmd.exitstatus} "\
          "running command: #{command}\n"\
          "Stderr: #{cmd.stderr}")
    end
    cmd
  end
end
