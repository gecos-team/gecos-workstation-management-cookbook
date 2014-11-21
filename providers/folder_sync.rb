#
# Cookbook Name:: gecos-ws-mgmt
# Provider:: folder_sharing
#
# Copyright 2013, Junta de Andalucia
# http://www.juntadeandalucia.es/
#
# All rights reserved - EUPL License V 1.1
# http://www.osor.eu/eupl
#
action :setup do
  begin

    os = `lsb_release -d`.split(":")[1].chomp().lstrip()
    if new_resource.support_os.include?(os)
    
      users = new_resource.users

      # TODO:  instalar package owncloud-client version 7

      package "owncloud-client" do
        action :install
        options "--force-yes"
      end

      username = users.username
      owncloud_authtype = users.owncloud_authtype
      owncloud_url = users.owncloud_url

      autostart_dir = "/home/#{username}/.config/autostart"
      home = "/home/#{username}"
      owncloud_dir = "#{home}/.local/share/data/ownCloud"

      directory  autostart_dir do
        recursive true
        owner username
        group username
        action :create
      end

      cookbook_file "owncloud.desktop" do
        path "#{autostart_dir}/ownCloud.desktop" 
        owner username
        group username
        action :create
      end

      directory owncloud_dir do
        recursive true
        owner username
        group username
        action :create
      end
  
      template "#{owncloud_dir}/owncloud.cfg" do
        source "owncloud.cfg.erb"
        owner "root"
        mode "0644"
        action :create
        variables({
          :username => username,
          :owncloud_authtype => owncloud_authtype,
          :owncloud_url => owncloud_url
        })
      end

      directory "#{owncloud_dir}/folders" do
        recursive true
        owner username
        group username
        action :create
      end
 
      template "#{owncloud_dir}/folders/ownCloud" do
        source "owncloud_folders.erb"
        owner "root"
        mode "0644"
        action :create
      end

       else
      Chef::Log.info("This resource is not support into your OS")
    end

  rescue Exception => e
    # just save current job ids as "failed"
    # save_failed_job_ids
    Chef::Log.error(e.message)
    job_ids = new_resource.job_ids
    job_ids.each do |jid|
      node.set['job_status'][jid]['status'] = 1
      node.set['job_status'][jid]['message'] = e.message
    end
  ensure
    gecos_ws_mgmt_jobids "folder_sync_res" do
      provider "gecos_ws_mgmt_jobids"
      recipe "users_mgmt"
    end.run_action(:reset)
  end
end
