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

      gecosV2 = $gecos_os == "GECOS V2"
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
      
      if not gecosV2 
        powermgmt_pkla = "/var/lib/polkit-1/localauthority/50-local.d/restrict-login-powermgmt.pkla"
        cookbook_file powermgmt_pkla do
          source "restrict-login-powermgmt.pkla"
          owner "root"
          group "root"
          mode "0644"
          action :nothing
        end.run_action(:create_if_missing)

        GRP_POWER = 'power'
        group GRP_POWER do
	  action :create
        end
      end

      # User-level key values
      users.each_key do |user_key|
        nameuser = user_key 
        username = nameuser.gsub('###','.')
        user = users[user_key]

	# Crear el grupo powwer si no existe y añadir al usuario

        disable_log_out = user.disable_log_out
	
	if gecosV2      	  
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
	      action  :modify
	      members [ username ]
	      append  true
	    end
	  else
	    require 'etc'
            power_members = Etc.getgrnam(GRP_POWER).mem
	    Chef::Log.debug("Power Group Members: #{power_members}")

	    if power_members.include?(username)
	      power_members.delete(username)
	      group GRP_POWER do
                action  :modify
                members power_members 
	        excluded_members username 
                append  true
	      end
	    end
	  end
        end
      end
    else
      Chef::Log.info("This resource is not support into your OS")
    end
    
    # save current job ids (new_resource.job_ids) as "ok"
    job_ids = new_resource.job_ids
    job_ids.each do |jid|
      node.set['job_status'][jid]['status'] = 0
    end

  rescue Exception => e
    # just save current job ids as "failed"
    # save_failed_job_ids
    Chef::Log.error(e.message)
    job_ids = new_resource.job_ids
    job_ids.each do |jid|
      node.set['job_status'][jid]['status'] = 1
      if not e.message.frozen?
        node.set['job_status'][jid]['message'] = e.message.force_encoding("utf-8")
      else
        node.set['job_status'][jid]['message'] = e.message
      end
    end
  ensure
    gecos_ws_mgmt_jobids "shutdown_options_res" do
      provider "gecos_ws_mgmt_jobids"
      recipe "users_mgmt"
    end.run_action(:reset)
  end
end
