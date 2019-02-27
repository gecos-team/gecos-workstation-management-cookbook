#
# Cookbook Name:: gecos-ws-mgmt
# Provider:: network
#
# Copyright 2013, Junta de Andalucia
# http://www.juntadeandalucia.es/
#
# All rights reserved - EUPL License V 1.1
# http://www.osor.eu/eupl
#
#
#

nm_conn_production_dir = '/etc/NetworkManager/system-connections/chef-conns'
nm_conn_path = '/etc/NetworkManager/system-connections/'
connections = {}
interfaces  = {}
nochanges = true

# Checking if resource changed
action :presetup do
  begin
    Chef::Log.info('network.rb ::: Starting PRESETUP ...')
    if !is_supported?
      Chef::Log.info('This resource is not supported in your OS')
    elsif has_applied_policy?('network_mgmt','network_res') || \
          is_autoreversible?('network_mgmt','network_res')
      connections = new_resource.connections
      interfaces = node[:network][:interfaces]

      connections.each do |conn|
        if !conn[:use_dhcp]
          mac_addr = conn[:mac_address]
          if conn[:fixed_con][:addresses].empty?
            raise 'There are not static IP addresses configured'
          end
          ip_addr  = conn[:fixed_con][:addresses][0][:ip_addr]
          netmask  = conn[:fixed_con][:addresses][0][:netmask]
          Chef::Log.debug('network.rb ::: presetup action - mac_addr ='\
            " #{mac_addr}")
          Chef::Log.debug('network.rb ::: presetup action - ip_addr  ='\
            " #{ip_addr}")
          Chef::Log.debug('network.rb ::: presetup action - netmask  ='\
            " #{netmask}")

          addr_data = interfaces.select do |_iface, props|
            props[:addresses].key? mac_addr.upcase
          end.values.shift
          Chef::Log.debug('network.rb ::: presetup action - addr_data ='\
            " #{addr_data}")
          nochanges &&= ((addr_data[:addresses].key? ip_addr) &&
            (netmask == addr_data[:addresses][ip_addr][:netmask]))
          Chef::Log.info('network.rb ::: presetup action - '\
            "No changes in policy = #{nochanges}")
        elsif conn[:use_dhcp]
          nochanges = false
        end
      end

      if (nochanges && node.normal['gcc_link']) ||
         (!nochanges && !node.override['gcc_link'])

        job_ids = new_resource.job_ids
        job_ids.each do |jid|
          node.normal['job_status'][jid]['status'] = 0
        end

        gecos_ws_mgmt_jobids 'network_res' do
          recipe 'network_mgmt'
        end.run_action(:reset)

        new_resource.updated_by_last_action(false)
      else
        # action_backup if not nochanges
        gecos_ws_mgmt_connectivity 'network_backup' do
          action :nothing
          # only_if {not nochanges}
        end.run_action(:backup)
        action_setup
      end
    end
  rescue StandardError => e
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
    gecos_ws_mgmt_jobids 'network_res' do
      recipe 'network_mgmt'
    end.run_action(:reset)
  end
end

action :setup do
  Chef::Log.info('network.rb ::: Starting SETUP .... Applying new settings')
  begin
    gem_depends = ['netaddr']
    gem_depends.each do |gem|
      r = gem_package gem do
        gem_binary($gem_path)
        action :nothing
      end
      r.run_action(:install)
    end
    Gem.clear_paths

    require 'netaddr'
    require 'fileutils'
    require 'securerandom'

    unless ::File.directory?(nm_conn_production_dir)
      FileUtils.mkdir nm_conn_production_dir
    end

    ethernet_interfaces = interfaces.select do |_interface, properties|
      properties[:encapsulation] == 'Ethernet'
    end

    ethernet_interfaces.each do |interface, properties|
      lladdr_family = properties[:addresses].select do |_mac_addr, addr_data|
        addr_data[:family] == 'lladdr'
      end

      lladdr_family.each do |mac_addr, _addr_data|
        # Get connection data by MAC address
        conn_data = connections.select do |connection|
          connection[:mac_address].casecmp(mac_addr.upcase)
        end

        conn_data.each do |connection|
          # Check require attributes
          unless connection[:use_dhcp]
            if connection[:fixed_con][:dns_servers].empty? ||
               connection[:fixed_con][:addresses].empty? ||
               !connection[:fixed_con].key?(:gateway)
              raise 'There are attributes for the dhcp that are empty'
            end
          end

          if connection[:net_type] == 'wireless'
            unless connection[:wireless_conn].key?(:essid)
              raise 'Wireless type selected without a ESSID'
            end
            if connection[:wireless_conn][:security][:sec_type] == 'WPA_PSK' ||
               connection[:wireless_conn][:security][:sec_type] == 'WEP'
              unless connection[:wireless_conn][:security].key?(:enc_pass)
                raise 'Wireless with password empty'
              end
            elsif connection[:wireless_conn][:security][:sec_type] == 'Leap'
              if !connection[:wireless_conn][:security].key?(:auth_user) ||
                 !connection[:wireless_conn][:security].key?(:auth_password)
                raise 'Leap configuration without user and password'
              end
            end
          end

          conn_file = nm_conn_production_dir.to_s + '/' + connection[:name].to_s
          uuid = if ::File.file?(conn_file)
                   # extraer el uuid
                   ::File.read(conn_file).grep(/uuid/)[0].delete("\n")
                         .split('=')[1]
                 else
                   # generar uno nuevo
                   SecureRandom.uuid
                 end

          Chef::Log.info("Setting connection for #{interface} [#{mac_addr}]"\
              " - #{connection[:net_type]}")
          var_hash = {
            uuid: uuid,
            connection: connection
          }
          template conn_file do
            owner 'root'
            group 'root'
            mode '0600'
            variables var_hash
            source 'connection.erb'
            action :nothing
          end.run_action(:create)
        end
      end
      Dir.chdir(nm_conn_production_dir) do
        Dir.glob('*').each do |file|
          next unless ::File.file?(file)
          Chef::Log.info("Moving files: #{nm_conn_production_dir}/#{file} "\
              "to #{nm_conn_path}")
          FileUtils.mv file, nm_conn_path
        end
      end
    end

    # TODO: guardar cada interfaz en su archivo correspondiente de network
    # manager

    cookbook_file '/etc/init/gecos-nm.conf' do
      source 'gecos-nm.conf'
      mode '0644'
      backup false
    end

    # network-manager
    service 'network-manager' do
      case $gecos_os
      when 'GECOS V2', 'Gecos V2 Lite'
        provider Chef::Provider::Service::Upstart
      else
        provider Chef::Provider::Service::Systemd
      end
      action :nothing
    end.run_action(:restart)

    new_resource.updated_by_last_action(true)

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
    gecos_ws_mgmt_jobids 'network_res' do
      recipe 'network_mgmt'
    end.run_action(:reset)
  end
end

action :warn do
  job_ids = new_resource.job_ids
  job_ids.each do |jid|
    node.normal['job_status'][jid]['status'] = 2
    node.normal['job_status'][jid]['message'] = 'Network problems '\
      'connecting to Control Center.'
    Chef::Log.debug("network.rb ::: recovery action - jid = #{jid}")
  end
end
