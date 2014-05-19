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
    users = new_resource.users 

    users.each do |user|
      username = user.username     
      disable_log_out = user.disable_log_out

      gecos_ws_mgmt_desktop_setting "disable-log-out" do
        provider "gecos_ws_mgmt_gsettings"
        schema "org.cinnamon.desktop.lockdown"
        type "boolean"
        username username
        value disable_log_out
        action :set
      end
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