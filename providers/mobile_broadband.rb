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


action :setup do

  begin
    # setup resource depends
    os = `lsb_release -d`.split(":")[1].chomp().lstrip()
    if new_resource.support_os.include?(os)
      gem_depends = [ 'securerandom', 'activesupport', 'json' ]

      gem_depends.each do |gem|

        r = gem_package gem do
          gem_binary("/opt/chef/embedded/bin/gem")
          action :nothing
        end
        r.run_action(:install)

      end
      Gem.clear_paths
      require 'securerandom'
      require 'json'
      require 'active_support/core_ext/hash'

      # setup system connections
      connections = new_resource.connections
      Chef::Log.info("Connections: #{connections}")

      nm_conn_path = '/etc/NetworkManager/system-connections/'
      node[:gecos_ws_mgmt][:network_mgmt][:mobile_broadband_res][:connections].each_pair do |provider, conn|
        Chef::Log.info("Setting '#{provider}' broadband connection")
        if conn[:conn_uuid].nil? 
        then
          conn_uuid = SecureRandom.uuid
          node.normal[:gecos_ws_mgmt][:network_mgmt][:mobile_broadband_res][provider][:conn_uuid] = conn_uuid
          # start providers xml parsing
          providers_hash = Hash.from_xml(File.read "/usr/share/mobile-broadband-provider-info/serviceproviders.xml")
          conn_country = node[:gecos_ws_mgmt][:network_mgmt][:mobile_briadband_res][provider][:conn_country]
          dig1 = providers_hash["serviceproviders"]["country"].select {|country| country["code"] == conn_country }
          providers = dig1[0]["provider"]
          provider_info = providers.select {|p| p["name"] == provider }
          conn_apn = provider_info.sort[0][1]["apn"]["value"]
          conn_username = provider_info.sort[0][1]["apn"]["username"]
        else
          conn_uuid = conn[:conn_uuid]
        end
        template "#{nm_conn_path}/gecos_mobile_broadband_#{conn_uuid}" do
          source "nm_mobile_broadband.erb"
          action :create
          variables(
            :conn_name => provider,
            :conn_uuid => conn_uiid,
            :conn_username => conn_username,
            :conn_apn => conn_apn
          )
        end
      end
      # save current job ids (new_resource.job_ids) as "ok"
      job_ids = new_resource.job_ids
      job_ids.each do |jid|
        node.set['job_status'][jid]['status'] = 0
      end
    else
      Chef::Log.info("This resource is not support into your OS")
    end
  rescue Exception => e
    # just save current job ids as "failed"
    # save_failed_job_ids
    Chef::Log.error(e)
    job_ids = new_resource.job_ids
    job_ids.each do |jid|
      node.set['job_status'][jid]['status'] = 1
      node.set['job_status'][jid]['message'] = e.message.force_encoding("utf-8")
    end
  end
end
