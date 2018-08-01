#
# Cookbook Name:: gecos-ws-mgmt
# Provider:: local_users
#
# Copyright 2013, Junta de Andalucia
# http://www.juntadeandalucia.es/
#
# All rights reserved - EUPL License V 1.1
# http://www.osor.eu/eupl
#
action :setup do
  begin
# We moved OS identification to recipes/default.rb
# But this recipe launches alone, and default.rb is not executed
#    os = `lsb_release -d`.split(":")[1].chomp().lstrip()
#    if new_resource.support_os.include?(os)
    if new_resource.support_os.include?($gecos_os)

      require 'etc'

      $required_pkgs['local_users'].each do |pkg|
        Chef::Log.debug("local_users.rb - REQUIRED PACKAGE = %s" % pkg)
        package pkg do
          action :nothing
        end.run_action(:install)
      end

      users = new_resource.users_list
      users.each do |usrdata| 
        username = usrdata.user
        fullname = usrdata.name
        passwd = usrdata.password
        actiontorun = usrdata.actiontorun
        user_home = "/home/#{username}"

        
        if actiontorun == "remove"
          Chef::Log.info("Removing local user #{username}")
          user username do
            action :nothing
            not_if "who | grep -q #{username}"
          end.run_action(:remove)
        else
          Chef::Log.info("Managing local user #{username}")
          user username do
            password passwd
            home user_home
            comment fullname
            shell "/bin/bash"
            manage_home true
            action :nothing
          end.run_action(:create)

          bash "copy skel to #{username}" do
	    user "#{username}"
            code <<-EOH
              export LC_ALL=$LANG
              /usr/bin/xdg-user-dirs-update --force
              EOH
            action :nothing
          end.run_action(:run)
        end
      end
    else
      Chef::Log.info("This resource is not support into your OS")
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
    
    gecos_ws_mgmt_jobids "local_users_res" do
       recipe "misc_mgmt"
    end.run_action(:reset) 
    
  end
end

