#
# Cookbook Name:: gecos-ws-mgmt
# Provider:: local_groups
#
# Copyright 2013, Junta de Andalucia
# http://www.juntadeandalucia.es/
#
# All rights reserved - EUPL License V 1.1
# http://www.osor.eu/eupl
#

action :setup do
  begin
    if new_resource.support_os.include?($gecos_os)
      groups_list = new_resource.groups_list

      groups_list.each do |item|
        if item.action == 'add'
          group item.group.to_s do
            append true
            members item.user
            action :nothing
            not_if "grep %#{item.group} /etc/sudoers"
          end.run_action(:create)

        elsif item.action == 'remove'
          group item.group.to_s do
            append true
            excluded_members item.user
            action :nothing
            not_if "grep %#{item.group} /etc/sudoers"
          end.run_action(:modify)
        end
      end
    else
      Chef::Log.info('This resource is not supported in your OS')
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
    Chef::Log.error(e.backtrace)

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
    gecos_ws_mgmt_jobids 'local_groups_res' do
      recipe 'misc_mgmt'
    end.run_action(:reset)
  end
end
