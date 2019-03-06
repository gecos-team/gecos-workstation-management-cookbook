#
# Cookbook Name:: gecos-ws-mgmt
# Provider:: appconfig_libreoffice
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
      (is_policy_active?('software_mgmt','appconfig_libreoffice_res') ||
       is_policy_autoreversible?('software_mgmt','appconfig_libreoffice_res'))
      unless new_resource.config_libreoffice.empty?
        app_update = new_resource.config_libreoffice['app_update']

        if app_update
          execute 'enable libreoffice upgrades' do
            command 'apt-mark unhold libreoffice libreoffice*'
            action :nothing
          end.run_action(:run)
        else
          execute 'disable libreoffice upgrades' do
            command 'apt-mark hold libreoffice libreoffice*'
            action :nothing
          end.run_action(:run)
        end
      end
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
    gecos_ws_mgmt_jobids 'appconfig_libreoffice_res' do
      recipe 'software_mgmt'
    end.run_action(:reset)
  end
end
