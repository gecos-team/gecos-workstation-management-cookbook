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

require 'chef/mixin/shell_out'
include Chef::Mixin::ShellOut

date = DateTime.now.to_time.to_i.to_s
nm_conn_backup_dir = '/var/lib/gecos-agent/network/NetworkManager/'
nm_conn_production_dir = '/etc/NetworkManager/system-connections/chef-conns'
nm_conn_path = '/etc/NetworkManager/system-connections/'
connections = {}
interfaces  = {}
nochanges = true

# Checking if resource changed
action :presetup do

    begin 

        Chef::Log.info("network.rb ::: Starting PRESETUP ...")
        if new_resource.support_os.include?($gecos_os)

          connections = new_resource.connections
          interfaces = node[:network][:interfaces]
      
          connections.each do |conn|
              if not conn[:use_dhcp]
                  mac_addr = conn[:mac_address]
                  if conn[:fixed_con][:addresses].empty?
                      raise "There are not static IP addresses configured"
                  end
                  ip_addr  = conn[:fixed_con][:addresses][0][:ip_addr]
                  netmask  = conn[:fixed_con][:addresses][0][:netmask]
                  Chef::Log.debug("network.rb ::: presetup action - mac_addr = #{mac_addr}")
                  Chef::Log.debug("network.rb ::: presetup action - ip_addr  = #{ip_addr}")
                  Chef::Log.debug("network.rb ::: presetup action - netmask  = #{netmask}")

                  addr_data = interfaces.select{|iface,props| props[:addresses].has_key?(mac_addr.upcase)}.values.shift
                  Chef::Log.debug("network.rb ::: presetup action - addr_data = #{addr_data}")
                  nochanges &&= ((addr_data[:addresses].has_key?(ip_addr)) and (netmask == addr_data[:addresses][ip_addr][:netmask]))
                  Chef::Log.info("network.rb ::: presetup action - No changes in policy = #{nochanges}")
              elsif conn[:use_dhcp]
                nochanges = false
              end
          end
    
          if (nochanges && node.normal['gcc_link']) || (!nochanges && !node.override['gcc_link'])

              job_ids = new_resource.job_ids
              job_ids.each do |jid|
                  node.normal['job_status'][jid]['status'] = 0
              end

              gecos_ws_mgmt_jobids "network_res" do
                    recipe "network_mgmt"
              end.run_action(:reset)

              new_resource.updated_by_last_action(false)

          else
              #action_backup if not nochanges
              gecos_ws_mgmt_connectivity 'network_backup' do
                  action :nothing
                  #only_if {not nochanges}
              end.run_action(:backup)
              action_setup
          end
      else
          Chef::Log.info("This resource is not support into your OS")
      end
    rescue Exception => e
        Chef::Log.error(e)
        job_ids = new_resource.job_ids
        job_ids.each do |jid|
            node.normal['job_status'][jid]['status'] = 1
            if not e.message.frozen?
                node.normal['job_status'][jid]['message'] = e.message.force_encoding("utf-8")
            else
                node.normal['job_status'][jid]['message'] = e.message
            end
    end
    ensure
        gecos_ws_mgmt_jobids "network_res" do
          recipe "network_mgmt"
        end.run_action(:reset)
    end

end

action :setup do

  Chef::Log.info("network.rb ::: Starting SETUP .... Applying new settings")

  begin

      gem_depends = [ 'netaddr' ]

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

      unless Kernel::test('d', nm_conn_production_dir)
        FileUtils.mkdir nm_conn_production_dir
      end

      interfaces.select { |interface, properties| properties[:encapsulation] == 'Ethernet'}.each do |interface, properties|

        properties[:addresses].select { |mac_addr, addr_data| addr_data[:family]=='lladdr' }.each do |mac_addr, addr_data|
          connections.select { |connection| connection[:mac_address].upcase == mac_addr.upcase}.each do |connection|

            #Check require attributes
            if not connection[:use_dhcp]
              if connection[:fixed_con][:dns_servers].empty? or connection[:fixed_con][:addresses].empty? or not connection[:fixed_con].key?(:gateway)
                raise "There are attributes for the dhcp that are empty"
              end
            end

            if connection[:net_type] == 'wireless'
              if not connection[:wireless_conn].key?(:essid)
                raise "Wireless type selected without a ESSID"
              end
              if connection[:wireless_conn][:security][:sec_type] == 'WPA_PSK' or connection[:wireless_conn][:security][:sec_type] == 'WEP'
                if not connection[:wireless_conn][:security].key?(:enc_pass)
                  raise "Wireless with password empty"
                end
              elsif connection[:wireless_conn][:security][:sec_type] == 'Leap'
                if not connection[:wireless_conn][:security].key?(:auth_user) or not connection[:wireless_conn][:security].key?(:auth_password)
                  raise "Leap configuration without user and password"
                end
              end
            end

            conn_file = nm_conn_production_dir.to_s + '/' + connection[:name].to_s
            if Kernel::test('f',conn_file)
              #extraer el uuid
              uuid = open(conn_file).grep(/uuid/)[0].gsub("\n",'').split('=')[1]
            else
              #generar uno nuevo
              uuid = SecureRandom.uuid
            end

            Chef::Log.info("Setting connection for #{interface} [#{mac_addr}] - #{connection[:net_type]}")
            template conn_file do
              owner "root"
              group "root"
              mode 0600
              variables ({
                :uuid => uuid,
                :connection => connection
                })
              source 'connection.erb'
              action :nothing
            end.run_action(:create)
          end
        end
        Dir.chdir(nm_conn_production_dir) do
          Dir.glob('*').each do |file|
            if ::File.file?(file)
              Chef::Log.info("Moving files: #{nm_conn_production_dir}/#{file} to #{nm_conn_path}")
              FileUtils.mv file, nm_conn_path
            end
          end
        end 
      end

      #TODO: guardar cada interfaz en su archivo correspondiente de network
      #manager

      cookbook_file "/etc/init/gecos-nm.conf" do
        source "gecos-nm.conf" 
        mode "0644"
        backup false
      end

      # network-manager
      service 'network-manager' do
        case $gecos_os
          when "GECOS V2","Gecos V2 Lite"; provider Chef::Provider::Service::Upstart
          else provider Chef::Provider::Service::Systemd
        end
        action :nothing
      end.run_action(:restart)

      new_resource.updated_by_last_action(true)

      # save current job ids (new_resource.job_ids) as "ok"
      job_ids = new_resource.job_ids
      job_ids.each do |jid|
        node.normal['job_status'][jid]['status'] = 0
      end
    
  rescue Exception => e
    # just save current job ids as "failed"
    # save_failed_job_ids
    Chef::Log.error(e)
    job_ids = new_resource.job_ids
    job_ids.each do |jid|
      node.normal['job_status'][jid]['status'] = 1
      if not e.message.frozen?
        node.normal['job_status'][jid]['message'] = e.message.force_encoding("utf-8")
      else
        node.normal['job_status'][jid]['message'] = e.message
      end
    end
  ensure
    
    gecos_ws_mgmt_jobids "network_res" do
       recipe "network_mgmt"
    end.run_action(:reset) 

  end
end

action :warn do
   job_ids = new_resource.job_ids
   job_ids.each do |jid|
       node.normal['job_status'][jid]['status'] = 2
       node.normal['job_status'][jid]['message'] = "Network problems connecting to Control Center."
       Chef::Log.debug("network.rb ::: recovery action - jid = #{jid}")
   end
end
