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
# OS identification moved to recipes/default.rb
#    os = `lsb_release -d`.split(":")[1].chomp().lstrip()
#    if new_resource.support_os.include?(os)
    if new_resource.support_os.include?($gecos_os)

      require 'etc'
    
      users = new_resource.users
      users_to_add = []
      users_to_remove = []
    
      $required_pkgs['folder_sharing'].each do |pkg|
        Chef::Log.debug("folder_sharing.rb - REQUIRED PACKAGE = %s" % pkg)
        package pkg do
          action :nothing
        end.run_action(:install)
      end

    # Default Samba group
      GRP_SAMBA = 'sambashare'
      samba_members = Etc.getgrnam(GRP_SAMBA).mem
    
      users.each_key do |user_key|
        nameuser = user_key 
        username = nameuser.gsub('###','.')
        user = users[user_key]
        if user.can_share 
          users_to_add << username
        else
          users_to_remove << username
        end
      end

      samba_members = samba_members + users_to_add
      samba_members = samba_members - users_to_remove
      samba_members.uniq!

      if samba_members.empty?
        samba_members << 'nobody'
      end

      group GRP_SAMBA do
        members samba_members
        append false
        action :nothing
      end.run_action(:manage)

      # save current job ids (new_resource.job_ids) as "ok"
      job_ids = new_resource.job_ids
      job_ids.each do |jid|
        node.normal['job_status'][jid]['status'] = 0
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
      node.normal['job_status'][jid]['status'] = 1
      if not e.message.frozen?
        node.normal['job_status'][jid]['message'] = e.message.force_encoding("utf-8")
      else
        node.normal['job_status'][jid]['message'] = e.message
      end
    end
  ensure

    gecos_ws_mgmt_jobids "folder_sharing_res" do
       recipe "users_mgmt"
    end.run_action(:reset)
    
  end
end
