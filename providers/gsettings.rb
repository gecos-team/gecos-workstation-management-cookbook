#
# Cookbook Name:: gecos-ws-mgmt
# Provider:: gsettings
#
# Copyright 2013, Junta de Andalucia
# http://www.juntadeandalucia.es/
#
# All rights reserved - EUPL License V 1.1
# http://www.osor.eu/eupl
#


require 'etc'
def initialize(*args)
  super
  @action = :set
  package 'xvfb' do
    action :nothing
  end.run_action(:install)

  dconf_cache_dir = "/home/#{new_resource.username}/.cache/dconf"
  unless Kernel::test('d', dconf_cache_dir)
    FileUtils.mkdir_p dconf_cache_dir
    
    gid = 0
    begin
        gid = Etc.getpwnam(new_resource.username).gid
    rescue Exception => e
        gid = 0
        Chef::Log.warn("Error getting GID for user: #{new_resource.username}")
    end
    
    if gid > 0
        FileUtils.chown(new_resource.username, gid, "/home/#{new_resource.username}/.cache")
        FileUtils.chown(new_resource.username, gid, dconf_cache_dir)
    end
  end
  begin
    output = %x[ps -ef | grep #{new_resource.username} | grep dbus-daemon | grep session | grep -v "ps -ef"]
    values = output.split()
    pid = values[1]
    
    dbus_file = nil
    Dir["/home/#{new_resource.username}/.dbus/session-bus/*0"].each do |file|
        file_pid = open(file).grep(/^DBUS_SESSION_BUS_PID=(.*)/){$1}[0]
        if pid == file_pid
            dbus_file = file
        end
    end

    @dbus_address = open(dbus_file).grep(/^DBUS_SESSION_BUS_ADDRESS=(.*)/){$1}[0]
  rescue Exception => e
    @dbus_address = nil
  end

end

action :set do
  dbus_address = @dbus_address
  unless dbus_address.nil?
    puts "sudo -iu #{new_resource.username} DBUS_SESSION_BUS_ADDRESS=\"#{dbus_address}\" gsettings set #{new_resource.schema} #{new_resource.name} #{new_resource.value}"
    execute "set key" do
      command "sudo -iu #{new_resource.username} DBUS_SESSION_BUS_ADDRESS=\"#{dbus_address}\" gsettings set #{new_resource.schema} #{new_resource.name} #{new_resource.value}"
      action :nothing
    end.run_action(:run)
  else
    puts "xvfb-run -w 0 sudo -iu #{new_resource.username} gsettings set #{new_resource.schema} #{new_resource.name} #{new_resource.value}"
    execute "set key" do
      action :nothing
      command "xvfb-run -w 0 sudo -iu #{new_resource.username} gsettings set #{new_resource.schema} #{new_resource.name} #{new_resource.value}"
    end.run_action(:run)
  end
end

action :unset do
  dbus_address = @dbus_address
  unless dbus_address.nil?
    execute "unset key" do
      action :nothing
      command "sudo -iu #{new_resource.username} DBUS_SESSION_BUS_ADDRESS=\"#{@dbus_address}\" gsettings reset #{new_resource.schema} #{new_resource.name}"
    end.run_action(:run)
  else
    execute "unset key" do
      action :nothing
      command "xvfb-run -w 0 sudo -iu #{new_resource.username} gsettings reset #{new_resource.schema} #{new_resource.name}"
    end.run_Action(:run)
  end
end

