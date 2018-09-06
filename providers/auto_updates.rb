#
# Cookbook Name:: gecos-ws-mgmt
# Provider:: auto_updates
#
# Copyright 2013, Junta de Andalucia
# http://www.juntadeandalucia.es/
#
# All rights reserved - EUPL License V 1.1
# http://www.osor.eu/eupl
#

action :setup do
  begin
    onstart_update = new_resource.onstart_update
    onstop_update = new_resource.onstop_update
    days = new_resource.days || []
    date = new_resource.date || {}
    if new_resource.support_os.include?($gecos_os)
      Chef::Log.info('Setting automatic updates')
      log_file = '/var/log/automatic-updates.log'
      err_file = '/var/log/automatic-updates.err'

      arrinit = ['2'] if onstart_update
      arrhalt = %w[6 0] if onstop_update

      if onstart_update || onstop_update || !days.empty? ||
         !date.empty?
        var_hash = {
          log_file: log_file,
          err_file: err_file,
          arrinit: arrinit,
          arrhalt: arrhalt
        }
        template '/etc/init.d/auto_updates' do
          source 'auto_updates.erb'
          mode '0755'
          owner 'root'
          variables var_hash
          action :nothing
        end.run_action(:create)
      else
        file '/etc/init.d/auto_updates' do
          action :nothing
        end.run_action(:delete)
      end

      if onstart_update
        bash 'enable on start auto_update script' do
          action :nothing
          code 'update-rc.d auto_updates start 60 2 .\n'
        end.run_action(:run)
      else
        link '/etc/rc2.d/S60auto_updates' do
          action :nothing
          only_if 'test -L /etc/rc2.d/S60auto_updates'
        end.run_action(:delete)
      end

      if onstop_update
        bash 'enable on stop auto_update script' do
          action :nothing
          code 'update-rc.d auto_updates start 60 6 0 .\n'
        end.run_action(:run)
      else
        link '/etc/rc6.d/S60auto_updates' do
          action :nothing
          only_if 'test -L /etc/rc6.d/S60auto_updates'
        end.run_action(:delete)

        link '/etc/rc0.d/S60auto_updates' do
          action :nothing
          only_if 'test -L /etc/rc0.d/S60auto_updates'
        end.run_action(:delete)
      end

      dmap = {
        monday: 1,
        tuesday: 2,
        wednesday: 3,
        thursday: 4,
        friday: 5,
        saturday: 6,
        sunday: 7
      }

      var_hash = {
        date_cron: date,
        days_cron: days,
        days_map: dmap
      }

      if !days.empty? || !date.empty?
        template '/etc/cron.d/apt_cron' do
          source 'apt_cron.erb'
          mode '0755'
          owner 'root'
          variables var_hash
          action :nothing
        end.run_action(:create)
      else
        file '/etc/cron.d/apt_cron' do
          action :nothing
        end.run_action(:delete)
      end
    else
      Chef::Log.info('This resource is not supported in your OS')
    end

    # TODO: add script to init.d, both in start fucntion, on login
    # in rc2 and on logout in rc6

    # save current job ids (new_resource.job_ids) as "ok"
    job_ids = new_resource.job_ids
    job_ids.each do |jid|
      node.normal['job_status'][jid]['status'] = 0
    end
  rescue StandardError => e
    # just save current job ids as "failed"
    # save_failed_job_ids
    Chef::Log.error(e.message)
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
    gecos_ws_mgmt_jobids 'auto_updates_res' do
      recipe 'misc_mgmt'
    end.run_action(:reset)
  end
end
