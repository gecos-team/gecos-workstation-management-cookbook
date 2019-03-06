#
# Cookbook Name:: gecos-ws-mgmt
# Provider:: system_proxy
#
# Copyright 2013, Junta de Andalucia
# http://www.juntadeandalucia.es/
#
# All rights reserved - EUPL License V 1.1
# http://www.osor.eu/eupl
#

require 'uri'
require 'fileutils'

# Constants
DATE = Time.now.to_i.to_s.freeze
ROOT = '/var/lib/gecos-agent/network/proxy/'.freeze
CHANGED_FILES_OR_DIRECTORIES = [
  '/etc/environment',
  '/etc/apt/apt.conf.d/',
  '/etc/dconf/',
  '/etc/firefox/',
  '/etc/thunderbird/'
].freeze

# Regex pattern
BLOCK     = /\d{,2}|1\d{2}|2[0-4]\d|25[0-5]/
IP_REGX   = /\A#{BLOCK}\.#{BLOCK}\.#{BLOCK}\.#{BLOCK}\z/
HOST_REGX = /^((\w|\w\w*\w)\.)+(\w|\w\w*\w)$/

global_settings  = {}
mozilla_settings = {}
nochanges = true

def check_uri(uri, error_msg, scheme)
  ret = uri
  if uri =~ IP_REGX || uri =~ HOST_REGX
    ret = scheme.concat(uri)
  elsif !uri.empty?
    raise error_msg
  end

  ret
end

def check_http_uri(http_uri, error_msg)
  ret = http_uri
  uri = URI.parse(http_uri)
  if uri.host.nil?
    ret = check_uri(http_uri, error_msg, 'http://')
  elsif uri.scheme =~ /https/
    ret = 'http://'.concat(uri.host)
  end

  ret
end

def check_https_uri(https_uri, error_msg)
  ret = https_uri
  uri = URI.parse(https_uri)
  if uri.host.nil?
    ret = check_uri(https_uri, error_msg, 'https://')
  elsif uri.scheme =~ /http/
    ret = 'https://'.concat(uri.host)
  end

  ret
end

def remove_trailing_slash(uri)
  uri.chomp('/') unless uri.empty?
  uri
end

# Checking if resource changed
action :presetup do
  begin
    Chef::Log.info('system_proxy.rb ::: Starting PRESETUP ...')

    if is_os_supported? &&
      (is_policy_active?('network_mgmt','system_proxy_res') ||
       is_policy_autoreversible?('network_mgmt','system_proxy_res'))
      Chef::Log.info('system_proxy.rb ::: new_resource.global_config :'\
          "#{new_resource.global_config}")
      Chef::Log.info('system_proxy.rb ::: new_resource.mozilla_config:'\
          "#{new_resource.mozilla_config}")
      # SYSTEM GLOBAL CONFIG
      unless new_resource.global_config.empty?
        # Parameters and defaults
        global_settings = {
          'http_proxy' => (new_resource.global_config['http_proxy'] || ''),
          'http_proxy_port' => (new_resource.global_config['http_proxy_port'] ||
              80),
          'https_proxy' => (new_resource.global_config['https_proxy'] || ''),
          'https_proxy_port' => (new_resource.global_config[
            'https_proxy_port'] || 443),
          'proxy_autoconfig_url' => new_resource.global_config[
            'proxy_autoconfig_url'],
          'disable_proxy' => new_resource.global_config['disable_proxy']
        }

        # Checking params
        global_settings['http_proxy'] = check_http_uri(
          global_settings['http_proxy'],
          'System Wide: http_proxy URL or Hostname not valid'
        )

        global_settings['https_proxy'] = check_https_uri(
          global_settings['https_proxy'],
          'System Wide: https_proxy URL or Hostname not valid'
        )

        # Remove trailing slash
        global_settings['http_proxy'] = remove_trailing_slash(
          global_settings['http_proxy']
        )
        global_settings['https_proxy'] = remove_trailing_slash(
          global_settings['https_proxy']
        )

        Chef::Log.debug('system_proxy.rb ::: global_settings:  '\
            "#{global_settings}")

        # Checking if there are changes between system and policy configuration
        system_http_proxy  = node['ohai_gecos']['envs']['HTTP_PROXY'] ||
                             ENV['HTTP_PROXY'] || ENV['http_proxy'] || ''
        system_https_proxy = node['ohai_gecos']['envs']['HTTPS_PROXY'] ||
                             ENV['HTTPS_PROXY'] || ENV['https_proxy'] || ''

        system_http_proxy_host  = URI.parse(system_http_proxy).host
        system_http_proxy_port  = URI.parse(system_http_proxy).port || 80
        system_https_proxy_host = URI.parse(system_https_proxy).host
        system_https_proxy_port = URI.parse(system_https_proxy).port || 443
        policy_http_proxy_host  = URI.parse(global_settings['http_proxy']).host
        policy_http_proxy_port  = global_settings['http_proxy_port']
        policy_https_proxy_host = URI.parse(global_settings['https_proxy']).host
        policy_https_proxy_port = global_settings['https_proxy_port']

        Chef::Log.debug('system_proxy.rb ::: system_http_proxy_host:  '\
            "#{system_http_proxy_host}")
        Chef::Log.debug('system_proxy.rb ::: system_http_proxy_port:  '\
            "#{system_http_proxy_port}")
        Chef::Log.debug('system_proxy.rb ::: system_https_proxy_host: '\
            "#{system_https_proxy_host}")
        Chef::Log.debug('system_proxy.rb ::: system_https_proxy_port: '\
            "#{system_https_proxy_port}")
        Chef::Log.debug('system_proxy.rb ::: policy_http_proxy_host:  '\
            "#{policy_http_proxy_host}")
        Chef::Log.debug('system_proxy.rb ::: policy_http_proxy_port:  '\
            "#{policy_http_proxy_port}")
        Chef::Log.debug('system_proxy.rb ::: policy_https_proxy_host: '\
            "#{policy_https_proxy_host}")
        Chef::Log.debug('system_proxy.rb ::: policy_https_proxy_port: '\
            "#{policy_https_proxy_port}")

        nochanges = system_http_proxy_host  == policy_http_proxy_host  &&
                    system_http_proxy_port  == policy_http_proxy_port  &&
                    system_https_proxy_host == policy_https_proxy_host &&
                    system_https_proxy_port == policy_https_proxy_port

        Chef::Log.debug("system_proxy.rb ::: nochanges: #{nochanges}")
        # Disable proxy
        nochanges &&= global_settings['disable_proxy'] == false
        Chef::Log.debug('system_proxy.rb ::: nochanges[disable_proxy]: '\
            "#{nochanges}")
        # PAC
        nochanges &&= global_settings['proxy_autoconfig_url'].nil?
        Chef::Log.debug('system_proxy.rb ::: nochanges[autoconfig_url]: '\
            "#{nochanges}")
      end

      # MOZILLA APPS CONFIG
      unless new_resource.mozilla_config.empty?
        case new_resource.mozilla_config['mode']
        when 'NO PROXY'
          mozilla_settings['mode'] = 0
        when 'AUTODETECT'
          mozilla_settings['mode'] = 4
        when 'SYSTEM'
          mozilla_settings['mode'] = 5
        when 'MANUAL'
          mozilla_settings = {
            'mode' => 1,
            'http_proxy' => (new_resource.mozilla_config['http_proxy'] || ''),
            'http_proxy_port' => (new_resource.mozilla_config[
              'http_proxy_port'] || 80),
            'https_proxy' => (new_resource.mozilla_config['https_proxy'] || ''),
            'https_proxy_port' => (new_resource.mozilla_config[
              'https_proxy_port'] || 443)
          }

          # Checking params
          mozilla_settings['http_proxy'] = check_http_uri(
            mozilla_settings['http_proxy'],
            'Mozilla: http_proxy URL or Hostname not valid'
          )

          global_settings['https_proxy'] = check_https_uri(
            global_settings['https_proxy'],
            'System Wide: https_proxy URL or Hostname not valid'
          )

          # Remove trailing slash
          mozilla_settings['http_proxy'] = remove_trailing_slash(
            mozilla_settings['http_proxy']
          )
          mozilla_settings['https_proxy'] = remove_trailing_slash(
            mozilla_settings['https_proxy']
          )

          # Bugfix: Only host, not url
          mozilla_settings['http_proxy'] = URI.parse(
            mozilla_settings['http_proxy']
          ).host
          mozilla_settings['https_proxy'] = URI.parse(
            mozilla_settings['https_proxy']
          ).host

        when 'AUTOMATIC'
          mozilla_settings = {
            'mode' => 2,
            'proxy_autoconfig_url' => new_resource.mozilla_config[
              'proxy_autoconfig_url']
          }
        end

        mozilla_settings['no_proxies_on'] = new_resource.mozilla_config[
          'no_proxies_on']
        Chef::Log.debug('system_proxy.rb - mozilla_settings: '\
            "#{mozilla_settings}")
        gecos_ws_mgmt_appconfig_firefox 'Firefox proxy configuration' do
          provider 'gecos_ws_mgmt_appconfig_firefox'
          config_firefox mozilla_settings
          job_ids new_resource.job_ids
          support_os new_resource.support_os
          action :nothing
        end.run_action(:setup)

        gecos_ws_mgmt_appconfig_thunderbird 'Thunderbird proxy setup' do
          provider 'gecos_ws_mgmt_appconfig_thunderbird'
          config_thunderbird mozilla_settings
          job_ids new_resource.job_ids
          support_os new_resource.support_os
          action :nothing
        end.run_action(:setup)
      end

      if (nochanges && node.normal['gcc_link']) ||
         (!nochanges && !node.override['gcc_link'])
        Chef::Log.info('system_proxy.rb ::: Nothing to do!')
        job_ids = new_resource.job_ids
        job_ids.each do |jid|
          node.normal['job_status'][jid]['status'] = 0
        end

        gecos_ws_mgmt_jobids 'network_res' do
          recipe 'network_mgmt'
        end.run_action(:reset)

        new_resource.updated_by_last_action(false)
      else
        Chef::Log.info('system_proxy.rb ::: Applying changes!')
        gecos_ws_mgmt_connectivity 'proxy_backup' do
          action :nothing
          # only_if {not nochanges}
        end.run_action(:backup)

        action_setup
        Chef::Log.info('system_proxy.rb ::: Changes applied!')
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
    gecos_ws_mgmt_jobids 'system_proxy_res' do
      recipe 'network_mgmt'
    end.run_action(:reset)
  end
end

action :setup do
  Chef::Log.info('system_proxy.rb ::: Starting SETUP ... Applying new settings')
  begin
    if !global_settings['disable_proxy']
      # Clearing old configuration
      Chef::Log.debug('system_proxy.rb - System-Wide Proxy clearing')
      gecos_ws_mgmt_system_settings 'System-Wide Proxy Clear' do
        provider 'gecos_ws_mgmt_system_settings'
        schema   'system/proxy'
        action   :nothing
      end.run_action(:clear)

      # DESKTOP APPLICATIONS
      if global_settings['proxy_autoconfig_url'].nil? ||
         global_settings['proxy_autoconfig_url'].empty?

        # Appliying new configuration
        Chef::Log.debug('system_proxy.rb - System-Wide Proxy Mode Manual')
        gecos_ws_mgmt_system_settings 'System-Wide Proxy Mode' do
          provider 'gecos_ws_mgmt_system_settings'
          schema   'system/proxy'
          name     'mode'
          value    'manual'
          action   :nothing
        end.run_action(:set)

        gecos_ws_mgmt_system_settings 'System-Wide HTTP Proxy' do
          provider 'gecos_ws_mgmt_system_settings'
          schema   'system/proxy/http'
          name     'host'
          value     URI.parse(global_settings['http_proxy']).host
          only_if   { !global_settings['http_proxy'].empty? }
          action    :nothing
        end.run_action(:set)

        gecos_ws_mgmt_system_settings 'System-Wide HTTP Proxy PORT' do
          provider 'gecos_ws_mgmt_system_settings'
          schema   'system/proxy/http'
          name     'port'
          value     global_settings['http_proxy_port']
          only_if   { !global_settings['http_proxy'].empty? }
          action    :nothing
        end.run_action(:set)

        gecos_ws_mgmt_system_settings 'System-Wide HTTPS Proxy' do
          provider 'gecos_ws_mgmt_system_settings'
          schema   'system/proxy/https'
          name     'host'
          value     URI.parse(global_settings['https_proxy']).host
          only_if   { !global_settings['https_proxy'].empty? }
          action    :nothing
        end.run_action(:set)

        gecos_ws_mgmt_system_settings 'System-Wide HTTPS Proxy PORT' do
          provider 'gecos_ws_mgmt_system_settings'
          schema   'system/proxy/https'
          name     'port'
          value     global_settings['https_proxy_port']
          only_if   { !global_settings['https_proxy'].empty? }
          action    :nothing
        end.run_action(:set)

        # ENVIRONMENT
        ruby_block 'Add proxy environment variables' do
          block do
            http_proxy  = "HTTP_PROXY=#{global_settings['http_proxy']}:"\
              "#{global_settings['http_proxy_port']}"
            https_proxy = "HTTPS_PROXY=#{global_settings['https_proxy']}:"\
              "#{global_settings['https_proxy_port']}"

            fe = Chef::Util::FileEdit.new('/etc/environment')
            fe.search_file_replace_line(/HTTP_PROXY/i, http_proxy)
            fe.search_file_replace_line(/HTTPS_PROXY/i, https_proxy)
            fe.write_file
            fe.insert_line_if_no_match(/HTTP_PROXY/i, http_proxy)
            fe.write_file
            fe.insert_line_if_no_match(/HTTPS_PROXY/i, https_proxy)
            fe.write_file
            if global_settings['http_proxy'].empty?
              fe.search_file_delete_line(/HTTP_PROXY/i)
            end
            if global_settings['https_proxy'].empty?
              fe.search_file_delete_line(/HTTPS_PROXY/i)
            end
            fe.write_file
          end
          action :nothing
        end.run_action(:run)

        # APT
        var_hash = {
          proxy_settings: global_settings
        }
        template '/etc/apt/apt.conf.d/80proxy' do
          source 'apt_proxy.erb'
          variables var_hash
          action :nothing
        end.run_action(:create)

      else # PROXY AUTOCONFIG URL (PAC)
        Chef::Log.debug('system_proxy.rb - System-Wide Proxy Autoconfig URL')

        gecos_ws_mgmt_system_settings 'System-Wide Proxy Mode' do
          provider 'gecos_ws_mgmt_system_settings'
          schema   'system/proxy'
          name     'mode'
          value    'auto'
          action   :nothing
        end.run_action(:set)

        gecos_ws_mgmt_system_settings 'System-Wide Proxy Autoconfig URL' do
          provider 'gecos_ws_mgmt_system_settings'
          schema   'system/proxy'
          name     'autoconfig-url'
          value global_settings['proxy_autoconfig_url']
          action :nothing
        end.run_action(:set)

        # ENVIRONMENT
        ruby_block 'Delete proxy environment variables' do
          block do
            fe = Chef::Util::FileEdit.new('/etc/environment')
            fe.search_file_delete_line(/HTTPS?_PROXY/i)
            fe.write_file
          end
          action :nothing
        end.run_action(:run)

        file '/etc/apt/apt.conf.d/80proxy' do
          action :nothing
        end.run_action(:delete)
      end

      # NOTIFICATIONS
      # Do notify the connectivity resource to test the connection
      new_resource.updated_by_last_action(true)

    elsif global_settings['disable_proxy']
      # DESKTOP APPLICATIONS
      gecos_ws_mgmt_system_settings 'System-Wide Proxy Mode [:unset]' do
        provider 'gecos_ws_mgmt_system_settings'
        schema   'system/proxy'
        name     'mode'
        value    'none'
      end.run_action(:unset)

      gecos_ws_mgmt_system_settings 'System-Wide HTTP Proxy [:unset]' do
        provider 'gecos_ws_mgmt_system_settings'
        schema   'system/proxy/http'
        name     'host'
        value global_settings['http_proxy']
      end.run_action(:unset)

      gecos_ws_mgmt_system_settings 'System-Wide HTTP Proxy PORT [:unset]' do
        provider 'gecos_ws_mgmt_system_settings'
        schema   'system/proxy/http'
        name     'port'
        value global_settings['http_proxy_port']
      end.run_action(:unset)

      gecos_ws_mgmt_system_settings 'System-Wide HTTPS Proxy [:unset]' do
        provider 'gecos_ws_mgmt_system_settings'
        schema   'system/proxy/https'
        name     'host'
        value     global_settings['https_proxy']
      end.run_action(:unset)

      gecos_ws_mgmt_system_settings 'System-Wide HTTPS Proxy PORT [:unset]' do
        provider 'gecos_ws_mgmt_system_settings'
        schema  'system/proxy/https'
        name    'port'
        value    global_settings['https_proxy_port']
      end.run_action(:unset)

      gecos_ws_mgmt_system_settings 'System-Wide Proxy Autoconf URL [:unset]' do
        provider 'gecos_ws_mgmt_system_settings'
        schema  'system/proxy'
        name    'autoconfig-url'
        value global_settings['proxy_autoconfig_url']
      end.run_action(:unset)

      # ENVIRONMENT
      ruby_block 'Delete proxy environment variables' do
        block do
          fe = Chef::Util::FileEdit.new('/etc/environment')
          fe.search_file_delete_line(/HTTPS?_PROXY/i)
          fe.write_file
        end
        action :nothing
      end.run_action(:run)

      file '/etc/apt/apt.conf.d/80proxy' do
        action :nothing
      end.run_action(:delete)

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
    gecos_ws_mgmt_jobids 'system_proxy_res' do
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
