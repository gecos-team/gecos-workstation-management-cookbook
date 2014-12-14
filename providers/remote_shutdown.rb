#
# Cookbook Name:: gecos-ws-mgmt
# Provider:: remote_shutdown
#
# Copyright 2014, Junta de Andalucia
# http://www.juntadeandalucia.es/
#
# All rights reserved - EUPL License V 1.1
# http://www.osor.eu/eupl
#
require 'chef/mixin/shell_out'
require 'date'
include Chef::Mixin::ShellOut

action :setup do

  begin
    os = `lsb_release -d`.split(":")[1].chomp().lstrip()
    if new_resource.support_os.include?(os)

      if new_resource.shutdown_mode == "halt"
        shutdown_command = "/sbin/shutdown -r now"
      else 
        shutdown_command = "/sbin/reboot"
      end

      now = DateTime.now

      cron "remote shutdown" do
        minute "#{now.minute + 5}" # In 5 mins from now
        hour "#{now.hour}"
        day "#{now.day}"
        month "#{now.month}"
        command "#{shutdown_command}"
        action :nothing
      end.run_action(:create)

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
      node.set['job_status'][jid]['message'] = e.message.force_encoding("utf-8")
    end
  ensure
    gecos_ws_mgmt_jobids "remote_shutdown_res" do
      provider "gecos_ws_mgmt_jobids"
      recipe "mism_mgmt"
    end.run_action(:reset)
  end
end