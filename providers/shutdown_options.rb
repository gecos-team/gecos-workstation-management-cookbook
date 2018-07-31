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

GRP_POWER = 'power'

action :setup do
  begin
# OS identification moved to recipes/default.rb
#    os = `lsb_release -d`.split(":")[1].chomp().lstrip()
#    if new_resource.support_os.include?(os)
    if new_resource.support_os.include?($gecos_os)

      package "dconf-tools" do
       action :nothing
      end.run_action(:install) 

      systemlock = new_resource.systemlock
      systemset = new_resource.systemset
      users = new_resource.users

      lite = ($gecos_os == "Gecos V2 Lite" or $gecos_os == "GECOS V3 Lite")
      # System-level lock settings
      #system = gecos_ws_mgmt_system_settings "disable-log-out" do
      #    provider "gecos_ws_mgmt_system_settings"
      #    schema "org.cinnamon.desktop.lockdown"
      #    type "boolean"
      #    value "#{systemset}"
      #    action :nothing
      #end
      #system.run_action(:lock) if systemlock
      #system.run_action(:unlock) if !systemlock
      
      if lite 
        powermgmt_pkla = "/var/lib/polkit-1/localauthority/50-local.d/restrict-login-powermgmt.pkla"
        cookbook_file powermgmt_pkla do
          source "restrict-login-powermgmt.pkla"
          owner "root"
          group "root"
          mode "0644"
          action :nothing
        end.run_action(:create_if_missing)


        group GRP_POWER do
          action :create
        end
      end

      # User-level key values
      users.each_key do |user_key|
        nameuser = user_key 
        username = nameuser.gsub('###','.')
        user = users[user_key]

        disable_log_out = user.disable_log_out
	
	if not lite
          gecos_ws_mgmt_desktop_settings "disable-log-out" do
            provider "gecos_ws_mgmt_gsettings"
            schema "org.cinnamon.desktop.lockdown"
            type "boolean"
            username username
            value "#{disable_log_out}"
          end.run_action(:set)
	else
	  if disable_log_out
	    group GRP_POWER do
	      action  :manage
	      members [username]
	      append  true
	    end
	  else
	    group GRP_POWER do
              action  :manage
	          excluded_members [username]
              append  true
	    end
	  end
        end
      end
    else
      Chef::Log.info("Your operative system does not support this resource")
    end
    
    # save current job ids (new_resource.job_ids) as "ok"
    job_ids = new_resource.job_ids
    job_ids.each do |jid|
      node.normal['job_status'][jid]['status'] = 0
    end

  rescue Exception => e
    # just save current job ids as "failed"
    # save_failed_job_ids
    Chef::Log.error(e.message)
    job_ids = new_resource.job_ids
    job_ids.each do |jid|
      node.normal['job_status'][jid]['status'] = 1
      if not e.message.frozen?
        node.normal['job_status'][jid]['message'] = e.message.force_encoding("utf-8")
      else
        node.normal['job_status'][jid]['message'] = e.message
      end
    end
  ensure

    gecos_ws_mgmt_jobids "shutdown_options_res" do
       recipe "users_mgmt"
    end.run_action(:reset)
    
  end
end
