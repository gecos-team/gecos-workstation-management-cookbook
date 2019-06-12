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
require 'date'

action :setup do
  begin
    if os_supported? &&
       (policy_active?('misc_mgmt', 'remote_shutdown_res') || \
        policy_autoreversible?('misc_mgmt', 'remote_shutdown_res'))
      if !new_resource.shutdown_mode.empty?
        shutdown_command = if new_resource.shutdown_mode == 'halt'
                             '/sbin/shutdown -r now'
                           else
                             '/sbin/reboot'
                           end

        now = Time.now

        change = false

        sc_hash = {}
        sc_hash['shutdown_command'] = shutdown_command

        if ::File.exist?('/etc/cron.shutdown')
          file = ::File.read('/etc/cron.shutdown')
          json_file = JSON.parse(file)
          change = (json_file != sc_hash)
        end

        # In 5 mins from now
        shutdown_time = now + (5 * 60)
        Chef::Log.info("now = #{now} shutdown_time=#{shutdown_time}")
        cron 'remote shutdown' do
          minute shutdown_time.min.to_s
          hour shutdown_time.hour.to_s
          day shutdown_time.day.to_s
          month shutdown_time.month.to_s
          command shutdown_command
          action :nothing
          only_if { !::File.exist?('/etc/cron.shutdown') || change }
        end.run_action(:create)

        ::File.open('/etc/cron.shutdown', 'w') do |f|
          f.write(sc_hash.to_json)
        end
      else
        cron 'remote shutdown' do
          action :nothing
        end.run_action(:delete)

        file '/etc/cron.shutdown' do
          owner 'root'
          group 'root'
          mode '0755'
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
    gecos_ws_mgmt_jobids 'remote_shutdown_res' do
      recipe 'misc_mgmt'
    end.run_action(:reset)
  end
end
