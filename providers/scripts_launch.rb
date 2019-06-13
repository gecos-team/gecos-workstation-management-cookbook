#
# Cookbook Name:: gecos-ws-mgmt
# Provider:: scripts_launch
#
# Copyright 2013, Junta de Andalucia
# http://www.juntadeandalucia.es/
#
# All rights reserved - EUPL License V 1.1
# http://www.osor.eu/eupl
#

action :setup do
  begin
    if os_supported? &&
       (policy_active?('misc_mgmt', 'scripts_launch_res') ||
        policy_autoreversible?('misc_mgmt', 'scripts_launch_res'))
      on_startup = new_resource.on_startup.select do |script|
        ::File.exist?(script) && ::File.executable?(script)
      end
      on_shutdown = new_resource.on_shutdown.select do |script|
        ::File.exist?(script) && ::File.executable?(script)
      end

      Chef::Log.debug("scripts_launch ::: on_startup  = #{on_startup}")
      Chef::Log.debug("scripts_launch ::: on_shutdown = #{on_shutdown}")

      if !on_startup.nil? || !on_startup.empty?
        var_hash = { startup: on_startup }
        template '/etc/init.d/scripts-onstartup' do
          source 'scripts_onstartup.erb'
          mode '0755'
          owner 'root'
          variables var_hash
          action :nothing
        end.run_action(:create)

        bash 'enable on start scripts' do
          action :nothing
          code "update-rc.d scripts-onstartup start 60 2 .\n"
        end.run_action(:run)
      else
        file '/etc/init.d/scripts-onstartup' do
          action :nothing
        end.run_action(:delete)

        link '/etc/rc2.d/S60scripts-onstartup' do
          only_if 'test -L /etc/rc2.d/S60scripts-onstartup'
          action :nothing
        end.run_action(:delete)
      end

      if !on_shutdown.nil? || !on_shutdown.empty?
        var_hash = { shutdown: on_shutdown }
        template '/etc/init.d/scripts-onshutdown' do
          source 'scripts_onshutdown.erb'
          mode '0755'
          owner 'root'
          variables var_hash
          action :nothing
        end.run_action(:create)

        bash 'enable on shutdown scripts' do
          action :nothing
          code "update-rc.d scripts-onshutdown stop 15 6 0 .\n"
        end.run_action(:run)
      else
        file '/etc/init.d/scripts-onshutdown' do
          action :nothing
        end.run_action(:delete)

        link '/etc/rc6.d/S20scripts-onshutdown' do
          only_if 'test -L /etc/rc6.d/S20scripts-onshutdown'
          action :nothing
        end.run_action(:delete)
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
    gecos_ws_mgmt_jobids 'scripts_launch_res' do
      recipe 'misc_mgmt'
    end.run_action(:reset)
  end
end
