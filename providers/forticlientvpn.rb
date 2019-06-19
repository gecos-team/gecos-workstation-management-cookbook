#
# Cookbook Name:: gecos_ws_mgmt
# Provider:: forticlient
#
# Copyright 2013, Junta de Andalucia
# http://www.juntadeandalucia.es/
#
# All rights reserved - EUPL License V 1.1
# http://www.osor.eu/eupl

HISTORY_FILTER = /^profile|^p12passwd|^path|^password|^user|^port|^server/

action :setup do
  begin
    # Added check to avoid execution if no connections defined
    if os_supported? &&
       ((!new_resource.connections.nil? &&
         !new_resource.connections.empty? &&
         policy_active?('network_mgmt', 'forticlientvpn_res')) ||
         policy_autoreversible?('network_mgmt', 'forticlientvpn_res'))

      res_proxyserver = new_resource.proxyserver || node[:gecos_ws_mgmt][
        :network_mgmt][:forticlientvpn_res][:proxyserver]
      res_proxyport = new_resource.proxyport || node[:gecos_ws_mgmt][
        :network_mgmt][:forticlientvpn_res][:proxyport]
      res_proxyuser = new_resource.proxyuser || node[:gecos_ws_mgmt][
        :network_mgmt][:forticlientvpn_res][:proxyuser]
      res_keepalive = new_resource.keepalive || node[:gecos_ws_mgmt][
        :network_mgmt][:forticlientvpn_res][:keepalive]
      res_autostart = new_resource.autostart || node[:gecos_ws_mgmt][
        :network_mgmt][:forticlientvpn_res][:autostart]
      res_connections = new_resource.connections || node[:gecos_ws_mgmt][
        :network_mgmt][:forticlientvpn_res][:connections]

      autostart_num = res_autostart ? 1 : 0

      require 'fileutils'

      Dir['/home/*'].each do |homedir|
        user_fctlsslvpnhistory = homedir + '/.fctsslvpnhistory'
        if ::File.directory?(user_fctlsslvpnhistory)
          # parse current conf file for already existant
          # (pass saved) connections
          current_conns = {}
          history = ::File.read(user_fctlsslvpnhistory)
          current_profile = history.grep(/^current/).each do |cpline|
            current_profile = cpline.strip.split('=')[1]
          end

          history.grep(HISTORY_FILTER).each do |fc|
            fc = fc.strip
            key, val = fc.split('=')
            if key.include? 'profile'
              current_profile = val
              current_conns[current_profile] = {}
            end
            current_conns[current_profile][key] = val
          end
          connections = current_conns
        else
          connections = {}
          current_profile = 'default'
        end

        # add new connections if they do not already exist

        res_connections.each do |conn|
          name = conn[:name]
          if connections[name].nil?
            connections[name] = {}
            connections[name]['server'] = conn[:server]
            connections[name]['port'] = conn[:port]
            connections[name]['p12passwd'] = ''
            connections[name]['path'] = ''
            connections[name]['password'] = ''
            connections[name]['user'] = ''
          else
            # update host/port for connection if values were updated in node
            if connections[name]['server'] != conn[:server]
              connections[name]['server'] = conn[:server]
            end
            if connections[name]['port'] != conn[:port]
              connections[name]['port'] = conn[:port]
            end
          end
        end

        user = homedir.scan(%r{/home/(.*)}).flatten.pop
        Chef::Log.info("forticlientvpn.rb ::: user = #{user}")
        var_hash = {
          proxyserver: res_proxyserver,
          proxyport: res_proxyport,
          proxyuser: res_proxyuser,
          current_profile: current_profile,
          keepalive: res_keepalive,
          autostart: autostart_num,
          connections: connections
        }
        template user_fctlsslvpnhistory do
          source 'fctlsslvpnhistory.erb'
          owner user.to_s
          group Etc.getpwnam(user).gid
          mode  '644'
          variables var_hash
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
    gecos_ws_mgmt_jobids 'forticlientvpn_res' do
      recipe 'network_mgmt'
    end.run_action(:reset)
  end
end
