#
# Cookbook Name:: gecos-ws-mgmt
# Provider:: tz_date
#
# Copyright 2013, Junta de Andalucia
# http://www.juntadeandalucia.es/
#
# All rights reserved - EUPL License V 1.1
# http://www.osor.eu/eupl
#

V2 = ['GECOS V2', 'Gecos V2 Lite'].freeze

action :setup do
  begin
    if os_supported? &&
       (policy_active?('misc_mgmt', 'tz_date_res') ||
        policy_autoreversible?('misc_mgmt', 'tz_date_res'))

      ntp_server = new_resource.server

      case $gecos_os
      when *V2 # DISTROS BASED ON UPSTART: NTPDATE

        $required_pkgs['tz_date'].each do |pkg|
          Chef::Log.debug("tz_date.rb - REQUIRED PACKAGE = #{pkg}")
          package pkg do
            action :nothing
          end.run_action(:install)
        end

        execute 'ntpdate' do
          command "ntpdate-debian -u #{ntp_server}"
          action :nothing
        end

        template '/etc/default/ntpdate' do
          source 'ntpdate.erb'
          owner 'root'
          group 'root'
          mode '0644'
          variables(ntp_server: ntp_server)
          not_if { ntp_server.nil? || ntp_server.empty? }
          notifies :run, 'execute[ntpdate]', :immediately
        end

      else # DISTROS BASED ON SYSTEMD: TIMESYNCD

        # Incompatibles
        %w[chrony ntp].each do |pkg|
          package pkg do
            action :nothing
          end.run_action(:purge)
        end

        service 'systemd-timesyncd' do
          supports(start: true, stop: true, restart: true, reload: true,
                   status: true)
          action %i[enable start]
        end

        bash 'timedatectl' do
          code <<-TIMEDATECTLCODE
          timedatectl set-local-rtc 0
          timedatectl set-ntp true
          TIMEDATECTLCODE
        end

        template '/etc/systemd/timesyncd.conf' do
          source 'timesyncd.conf.erb'
          owner 'root'
          group 'root'
          mode '0644'
          variables(ntp_server: ntp_server)
          not_if { ntp_server.nil? || ntp_server.empty? }
          notifies :restart, 'service[systemd-timesyncd]', :immediately
        end

      end
    end

    # save current job ids (new_resource.job_ids) as "ok"
    job_ids = new_resource.job_ids
    job_ids.each do |jid|
      node.normal['job_status'][jid]['status'] = 0
    end
  rescue StandardError => e
    Chef::Log.error(e.message)
    Chef::Log.error(e.backtrace.join("\n"))

    # just save current job ids as "failed"
    # save_failed_job_ids
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
    gecos_ws_mgmt_jobids 'tz_date_res' do
      recipe 'misc_mgmt'
    end.run_action(:reset)
  end
end
