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
    if is_os_supported? &&
      (is_policy_active?('users_mgmt','folder_sharing_res') ||
       is_policy_autoreversible?('users_mgmt','folder_sharing_res'))
      require 'etc'

      users = new_resource.users
      users_to_add = []
      users_to_remove = []

      $required_pkgs['folder_sharing'].each do |pkg|
        Chef::Log.debug("folder_sharing.rb - REQUIRED PACKAGE = #{pkg}")
        package pkg do
          action :nothing
        end.run_action(:install)
      end

      # Default Samba group
      GRP_SAMBA = 'sambashare'.freeze
      samba_members = Etc.getgrnam(GRP_SAMBA).mem

      users.each_key do |user_key|
        nameuser = user_key
        username = nameuser.gsub('###', '.')
        user = users[user_key]
        if user.can_share
          users_to_add << username
        else
          users_to_remove << username
        end
      end

      samba_members += users_to_add
      samba_members -= users_to_remove
      samba_members.uniq!

      samba_members << 'nobody' if samba_members.empty?

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
    end
  rescue StandardError => e
    # just save current job ids as "failed"
    # save_failed_job_ids
    Chef::Log.error(e.message)
    Chef::Log.error(e.backtrace.join("\n"))

    job_ids = new_resource.job_ids
    job_ids.each do |jid|
      node.normal['job_status'][jid]['status'] = 1
      if !e.message.frozen?
        node.normal['job_status'][jid]['message'] =
          e.message.force_encoding('utf-8')
      else
        node.normal['job_status'][jid]['message'] = e.message
      end
    end
  ensure
    gecos_ws_mgmt_jobids 'folder_sharing_res' do
      recipe 'users_mgmt'
    end.run_action(:reset)
  end
end
