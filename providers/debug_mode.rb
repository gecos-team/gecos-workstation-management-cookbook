#
# Cookbook Name:: gecos-ws-mgmt
# Provider:: debug_mode
#
# Copyright 2018, Junta de Andalucia
# http://www.juntadeandalucia.es/
#
# All rights reserved - EUPL License V 1.1
# http://www.osor.eu/eupl
#
require 'json'
require 'time'

action :setup do
  begin
    # Checking OS
    if !is_supported?
      Chef::Log.info('This resource is not supported in your OS')
    elsif has_applied_policy?('single_node','debug_mode_res') || \
          is_autoreversible?('single_node','debug_mode_res')
      enable_debug = new_resource.enable_debug
      if new_resource.expire_datetime == '' ||
         Time.parse(new_resource.expire_datetime) < Time.now
        enable_debug = false
      end

      # Set debug mode flag
      var_hash = { debug_mode: enable_debug }
      template '/etc/gecos/debug_mode' do
        source 'debug_mode.erb'
        owner 'root'
        group 'root'
        mode '0644'
        variables var_hash
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
    gecos_ws_mgmt_jobids 'debug_mode_res' do
      recipe 'single_node'
    end.run_action(:reset)
  end
end
