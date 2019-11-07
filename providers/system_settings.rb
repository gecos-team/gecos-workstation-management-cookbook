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
    unless ::File.directory?('/etc/dconf/profile')
      FileUtils.mkdir_p '/etc/dconf/profile'
    end
    unless ::File.directory?("/etc/dconf/db/#{dconfdb}.d/locks")
      FileUtils.mkdir_p "/etc/dconf/db/#{dconfdb}.d/locks"
    end
  end

  schema_s = schema.tr('/', '-')
  file "user-dconf-profile-set-#{schema_s}-#{key}" do
    path '/etc/dconf/profile/user'
    backup false
    content "user-db:user\nsystem-db:#{dconfdb}\n"
    action :nothing
  end.run_action(:create)

  file "/etc/dconf/db/#{dconfdb}.d/#{schema_s}-#{key}.key" do
    backup false
    content "[#{schema}]\n#{key}=#{value}\n"
    action :nothing
  end.run_action(:create)

  execute "update-dconf-set-#{schema_s}-#{key}" do
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

  execute "update-dconf-unset-#{schema_s}-#{key}" do
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
    unless ::File.directory?('/etc/dconf/profile')
      FileUtils.mkdir_p '/etc/dconf/profile'
    end
    unless ::File.directory?("/etc/dconf/db/#{dconfdb}.d/locks")
      FileUtils.mkdir_p "/etc/dconf/db/#{dconfdb}.d/locks"
    end
  end

  file "user-dconf-profile-lock-#{key}" do
    path '/etc/dconf/profile/user'
    backup false
    content "system-db:#{dconfdb}\nuser-db:user\n"
  end.run_action(:create)

  key_path = '/' + schema.tr('.', '/') + '/' + key
  file "/etc/dconf/db/#{dconfdb}.d/locks/#{key}.lock" do
    backup false
    content "#{key_path}\n"
  end.run_action(:create)

  execute "update-dconf-lock-#{key}" do
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

  execute "update-dconf-unlock-#{key}" do
    action :nothing
    command 'dconf update'
  end.run_action(:run)
end

action :clear do
  dconfdb = 'gecos'
  schema = new_resource.schema
  regex = "#{schema.tr('/', '-')}*"

  # If /etc/dconf/db doesn't exist
  # "dconf update" command fails
  directory '/etc/dconf/db' do
    owner 'root'
    group 'root'
    mode '0755'
    recursive true
    action :nothing
  end.run_action(:create)

  # Delete all files of schema
  directory "/etc/dconf/db/#{dconfdb}.d/#{regex}" do
    recursive true
    action :nothing
  end.run_action(:delete)

  execute 'update-dconf-clear' do
    action :nothing
    command 'dconf update'
  end.run_action(:run)
end
