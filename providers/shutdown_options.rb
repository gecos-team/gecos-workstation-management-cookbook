#
# Cookbook Name:: gecos-ws-mgmt
# Provider:: shutdown_options
#
# Copyright 2013, Junta de Andalucia
# http://www.juntadeandalucia.es/
#
# All rights reserved - EUPL License V 1.1
# http://www.osor.eu/eupl
#

def dconf_lockdown (username, schema, key, value)
  p = package "dconf-tools" do
    action :nothing
  end
  p.run_action(:install) 

  if !key.nil? and !key.empty?
    ["/etc/dconf/profile", "/etc/dconf/db/#{username}.d/locks"].each do |dir|
      directory dir do
        recursive true
        action :create
      end
    end

    file "/etc/dconf/profile/#{username}" do
      backup false
      content <<-eof
system-db:#{username}
user-db:user
      eof
      action :create
    end

    key_path = '/' + File.join(schema.gsub('.','/'), key)
    file "/etc/dconf/db/#{username}.d/locks/#{key}.lock" do
      backup false
      content <<-eof
#{key_path}
      eof
      action :create
    end

    file "/etc/dconf/db/#{username}.d/#{key}.key" do
      backup false
      content <<-eof
[#{schema}]
#{key}='#{value}'
      eof
      action :create
      notifies :run, "execute[update-dconf]", :delayed
    end

    execute "update-dconf" do
      command "dconf update"
      action :nothing
    end
  end
end

action :setup do
  begin
    users = new_resource.users 

    users.each do |user|
      username = user.username     
      disable_log_out = user.disable_log_out

      gecos_ws_mgmt_desktop_settings "disable-log-out" do
        provider "gecos_ws_mgmt_gsettings"
        schema "org.cinnamon.desktop.lockdown"
        type "boolean"
        username username
        value "#{disable_log_out}"
        action :set
      end

      dconf_lockdown(username, "org.cinnamon.desktop.lockdown", "disable-log-out", disable_log_out)
    end
    
    # save current job ids (new_resource.job_ids) as "ok"
    job_ids = new_resource.job_ids
    job_ids.each do |jid|
      node.set['job_status'][jid]['status'] = 0
    end

  rescue Exception => e
    # just save current job ids as "failed"
    # save_failed_job_ids
    job_ids = new_resource.job_ids
    job_ids.each do |jid|
      node.set['job_status'][jid]['status'] = 1
      node.set['job_status'][jid]['message'] = e.message
    end
    Chef::Log.info(node['job_status'])
  end
end