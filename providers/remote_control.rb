#
# Cookbook Name:: gecos-ws-mgmt
# Provider:: remote_control
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
    if new_resource.support_os.include?($gecos_os)

      enable_helpchannel = new_resource.enable_helpchannel
      enable_ssh = new_resource.enable_ssh
      ssl_verify = new_resource.ssl_verify
      tunnel_url = new_resource.tunnel_url 
      # Default url
      tunnel_url ||= node[:gecos_ws_mgmt][
        :misc_mgmt][:remote_control_res][:tunnel_url]
      # Default secret
      known_message = node[:gecos_ws_mgmt][
        :misc_mgmt][:remote_control_res][:known_message]

      # Read-only perms to all users
      file '/etc/chef/client.pem' do
        mode '644'
      end

      # Un/Install HelpChannel client
      hc_action = enable_helpchannel ? :install : :remove
      package 'gecosws-hc-client' do
	action hc_action
      end

      # Un/Install SSH
      ssh_action = enable_ssh ? :install : :remove
      notify_action = enable_ssh ? :start : :stop 
      package 'openssh-server' do
	action ssh_action
	notifies "#{notify_action}", 'service[ssh]', :immediately
      end

      # Start/Stop ssh service
      service 'ssh' do
        action :nothing
      end

      # Template /etc/helpchannel.conf
      var_hash = { 
        tunnel_url: tunnel_url,
	known_message: known_message,
	ssl_verify: ssl_verify
      }

      template '/etc/helpchannel.conf' do
        source 'helpchannel.erb'
        owner 'root'
        group 'root'
        mode '0644'
        variables var_hash
	only_if { enable_helpchannel && !tunnel_url.empty? }
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
    gecos_ws_mgmt_jobids 'remote_control_res' do
      recipe 'misc_mgmt'
    end.run_action(:reset)
  end
end
