#
# Cookbook Name:: gecos-ws-mgmt
# Provider:: local_admin_users
#
# Copyright 2013, Junta de Andalucia
# http://www.juntadeandalucia.es/
#
# All rights reserved - EUPL License V 1.1
# http://www.osor.eu/eupl
#

action :setup do
  require 'etc'
  begin
    if os_supported? &&
       (policy_active?('misc_mgmt', 'local_admin_users_res') ||
        policy_autoreversible?('misc_mgmt', 'local_admin_users_res'))
      local_admin_list = new_resource.local_admin_list
      admins_to_add = []
      admins_to_remove = []
      local_admin_list.each do |admin|
        begin
          Etc.getpwnam(admin.name)
          case admin.action
          when 'add'
            admins_to_add << admin.name
          when 'remove'
            admins_to_remove << admin.name
          else
            raise "Action for admin #{admin.name} is not add nor remove "\
            "(#{admin.action})"
          end
        rescue
          Chef::Log.error('#{admin.name} is not a valid username in this workstation')
        end
      end
      group 'sudo' do
        members admins_to_add
        excluded_members admins_to_remove
        append true
        action :nothing
      end.run_action(:modify)      
    end
    # save current job ids (new_resource.job_ids) as "ok"
    job_ids = new_resource.job_ids
    job_ids.each do |jid|
      node.normal['job_status'][jid]['status'] = 0
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
    gecos_ws_mgmt_jobids 'local_admin_users_res' do
      recipe 'misc_mgmt'
    end.run_action(:reset)
  end
end
