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

# It sets a fixed value for a dconf key at system level
action :set do
  dconfdb = 'gecos'
  schema = new_resource.schema
  key = new_resource.name
  value = if new_resource.value.is_a? String
          then %('#{new_resource.value}')
          else new_resource.value
          end

  Chef::Log.debug("system_settings.rb - value:#{value}")

  if !key.nil? && !key.empty?
    dirs = ['/etc/dconf/profile', "/etc/dconf/db/#{dconfdb}.d/locks"]
    dirs.each do |dir|
      directory dir do
        recursive true
        action :nothing
      end.run_action(:create)
    end
  end

  file '/etc/dconf/profile/user' do
    backup false
    content "user-db:user\nsystem-db:#{dconfdb}\n"
    action :nothing
  end.run_action(:create)

  schema_s = schema.tr('/', '-')
  file "/etc/dconf/db/#{dconfdb}.d/#{schema_s}-#{key}.key" do
    backup false
    content "[#{schema}]\n#{key}=#{value}\n"
    action :nothing
  end.run_action(:create)

  execute 'update-dconf' do
    action :nothing
    command 'dconf update'
  end.run_action(:run)
end

# Removes a system-level dconf fixed value
action :unset do
  dconfdb = 'gecos'
  schema = new_resource.schema
  key = new_resource.name

  schema_s = schema.tr('/', '-')
  file "/etc/dconf/db/#{dconfdb}.d/#{schema_s}-#{key}.key" do
    action :nothing
  end.run_action(:delete)

  execute 'update-dconf' do
    action :nothing
    command 'dconf update'
  end.run_action(:run)
end

# It prevents users for changing the value of a dconf key
action :lock do
  dconfdb = 'gecos'
  schema = new_resource.schema
  key = new_resource.name

  if !key.nil? && !key.empty?
    dirs = ['/etc/dconf/profile', "/etc/dconf/db/#{dconfdb}.d/locks"]
    dirs.each do |dir|
      directory dir do
        recursive true
      end.run_action(:create)
    end
  end

  file '/etc/dconf/profile/user' do
    backup false
    content "system-db:#{dconfdb}\nuser-db:user\n"
  end.run_action(:create)

  key_path = '/' + schema.tr('.', '/') + '/' + key
  file "/etc/dconf/db/#{dconfdb}.d/locks/#{key}.lock" do
    backup false
    content "#{key_path}\n"
  end.run_action(:create)

  execute 'update-dconf' do
    action :nothing
    command 'dconf update'
  end.run_action(:run)
end

# It removes the dconf key system-level locking
action :unlock do
  dconfdb = 'gecos'
  key = new_resource.name

  file "/etc/dconf/db/#{dconfdb}.d/locks/#{key}.lock" do
    action :nothing
  end.run_action(:delete)

  execute 'update-dconf' do
    action :nothing
    command 'dconf update'
  end.run_action(:run)
end

action :clear do
  dconfdb = 'gecos'
  schema = new_resource.schema
  regex = "#{schema.tr('/', '-')}*"

  # Delete all files of schema
  Dir["/etc/dconf/db/#{dconfdb}.d/#{regex}"].each do |fe|
    Chef::Log.debug("system_settings.rb - fe:#{fe}")
    file fe.to_s do
      backup false
      action :nothing
    end.run_action(:delete)
  end

  execute 'update-dconf' do
    action :nothing
    command 'dconf update'
  end.run_action(:run)
end
