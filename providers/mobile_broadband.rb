#
# Cookbook Name:: gecos-ws-mgmt
# Provider:: mobile_broadband
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
    if os_supported? &&
       (policy_active?('network_mgmt', 'mobile_broadband_res') ||
        policy_autoreversible?('network_mgmt', 'mobile_broadband_res'))
      gem_depends = %w[activesupport json]
      gem_depends.each do |gem|
        r = gem_package gem do
          gem_binary($gem_path)
          action :nothing
        end
        r.run_action(:install)
      end
      Gem.clear_paths
      require 'securerandom'
      require 'json'
      require 'active_support/core_ext/hash'

      directory '/usr/share/mobile-broadband-provider-info' do
        owner 'root'
        group 'root'
        mode '0755'
      end.run_action(:create)

      # Please, keep this file updated with the latest package
      cookbook_file '/usr/share/mobile-broadband-provider-info'\
        '/serviceproviders.xml' do
        source 'serviceproviders.xml'
        owner 'root'
        group 'root'
        mode '0644'
        action :nothing
      end.run_action(:create)

      # setup system connections
      connections = new_resource.connections
      Chef::Log.info("Connections: #{connections}")

      nm_conn_path = '/etc/NetworkManager/system-connections'
      id_con = 0
      connections = node[:gecos_ws_mgmt][:network_mgmt][
        :mobile_broadband_res][:connections]
      connections.each do |conn|
        provider = conn[:provider]
        Chef::Log.info("Setting '#{provider}' broadband connection")
        conn_uuid = SecureRandom.uuid

        # start providers xml parsing
        # some bash rationale (extracts spanish providers' names):
        # cat /usr/share/mobile-broadband-provider-info/
        # ...serviceproviders.xml
        # | xml2json| jq .serviceproviders.country
        # | sed -e 's|@code|code|g' -e 's|#tail|tail|g' -e
        # 's|#text|text|g' /var/tmp/countries.json|jq '.[] |
        # select(.code=="es")'|jq .provider[].name.text
        xml = ::File.read(
          '/usr/share/mobile-broadband-provider-info/'\
            'serviceproviders.xml'
        )
        providers_hash = Hash.from_xml(xml)
        conn_country = conn['country']
        providers_country = providers_hash['serviceproviders']['country']
        dig1 = providers_country.select do |country|
          country['code'] == conn_country
        end
        providers = dig1[0]['provider']
        provider_info = providers.select { |p| p['name'] == provider }
        provider_info.sort!
        case provider_info[0]
        when Array
          gsm_object = provider_info[0][1]['gsm']
        when Hash
          gsm_object = provider_info[0]['gsm']
        end
        case gsm_object['apn']
        when Array
          apn_object = gsm_object['apn'][0]
        when Hash
          apn_object = gsm_object['apn']
        end

        conn_apn = apn_object['value']
        conn_username = apn_object['username']

        var_hash = {
          conn_name: "Gecos_GSM_#{id_con}",
          conn_uuid: conn_uuid,
          conn_username: conn_username,
          conn_apn: conn_apn
        }
        template "#{nm_conn_path}/Gecos_GSM_#{id_con}" do
          source 'nm_mobile_broadband.erb'
          action :nothing
          mode '0600'
          variables var_hash
        end.run_action(:create)
        id_con += 1
      end
      # save current job ids (new_resource.job_ids) as "ok"
      job_ids = new_resource.job_ids
      job_ids.each do |jid|
        node.normal['job_status'][jid]['status'] = 0
      end
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
    gecos_ws_mgmt_jobids 'mobile_broadband_res' do
      recipe 'network_mgmt'
    end.run_action(:reset)
  end
end
