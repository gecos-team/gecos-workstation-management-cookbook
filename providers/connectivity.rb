#
# Cookbook Name:: gecos-ws-mgmt
# Provider:: connectivity
#
# Copyright 2013, Junta de Andalucia
# http://www.juntadeandalucia.es/
#
# All rights reserved - EUPL License V 1.1
# http://www.osor.eu/eupl
#

require 'uri'
require 'net/http'
require 'openssl'
require 'json'

action :test do
  Chef::Log.debug('connectivity.rb ::: TEST action')

  # Initialize vars
  test_ok = true

  # Targets
  targets = case new_resource.target.nil?
            when true then
              # GCC url
              fgcc = ::File.read('/etc/gcc.control')
              gcc_json = JSON.parse(fgcc)
              Chef::Log.debug("connectivity.rb ::: gcc_control => #{gcc_json}")

              # CHEF-SERVER url
              fchef = ::File.read('/etc/chef.control')
              chef_json = JSON.parse(fchef)
              Chef::Log.debug("connectivity.rb ::: chef_server => #{chef_json}")

              [gcc_json['uri_gcc'], chef_json['chef_server_url']]
            else
              [new_resource.target]
            end
  Chef::Log.debug("connectivity.rb ::: targets => #{targets}")

  # Proxy
  proxy_from_etc = proxy_ssl_from_etc = nil
  ruby_block 'HTTP(S)_PROXY etc_environment' do
    block do
      file = ::File.read('/etc/environment')
      proxy_from_etc     = file.scan(/http_proxy=(.*)/i).flatten.pop  || ''
      proxy_ssl_from_etc = file.scan(/https_proxy=(.*)/i).flatten.pop || ''
    end
    action :nothing
  end.run_action(:run)

  Chef::Log.debug("connectivity.rb ::: proxy_from_etc => #{proxy_from_etc}")
  Chef::Log.debug('connectivity.rb ::: proxy_ssl_from_etc => '\
      "#{proxy_ssl_from_etc}")

  unless proxy_from_etc.start_with?('', 'http://')
    proxy_from_etc     = 'http://'.concat(proxy_from_etc)
  end

  unless proxy_ssl_from_etc.start_with?('', 'https://')
    proxy_ssl_from_etc = 'https://'.concat(proxy_ssl_from_etc)
  end

  Chef::Log.debug("connectivity.rb ::: proxy_from_etc => #{proxy_from_etc}")
  Chef::Log.debug('connectivity.rb ::: proxy_ssl_from_etc => '\
      "#{proxy_ssl_from_etc}")
  # Testing connection
  targets.each do |target|
    Chef::Log.debug("connectivity.rb ::: target => #{target}")

    scheme = URI.parse(target).scheme.downcase
    Chef::Log.debug("connectivity.rb ::: scheme => #{scheme}")

    host = URI.parse(target).host || target
    Chef::Log.debug("connectivity.rb ::: host => #{host}")

    port = new_resource.port.nil? ? new_resource.port : URI.parse(target).port

    # Defaults
    port ||= case scheme
             when 'http'
               80
             when 'https'
               443
             end
    Chef::Log.debug("connectivity.rb ::: port  => #{port}")

    # Target url
    url = URI.parse("#{scheme}://#{host}:#{port}")

    begin
      # Using proxy if exists
      proxy = case scheme
              when 'http'
                URI.parse(proxy_from_etc)
              when 'https'
                URI.parse(proxy_ssl_from_etc)
              end

      http = if proxy
               Net::HTTP.new(url.host, url.port, proxy.host, proxy.port)
             else
               Net::HTTP.new(url.host, url.port)
             end

      if scheme == 'https'
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end

      # Following redirects
      max_follow = 5
      response = nil
      max_follow.times do
        response = http.request_get(url.request_uri)
        break unless response.is_a?(Net::HTTPRedirection)
        url = URI.parse(response['location'])
      end

      Chef::Log.debug("connectivity.rb ::: response.code #{response.code}")
      test_ok &&= response.is_a?(Net::HTTPOK)
    rescue Timeout::Error, EOFError,
           Errno::EINVAL, Errno::ECONNRESET, Errno::EHOSTUNREACH,
           Errno::ECONNREFUSED, Errno::ENETUNREACH, Net::HTTPBadResponse,
           Net::HTTPHeaderSyntaxError, Net::ProtocolError => e

      Chef::Log.debug("connectivity.rb ::: There was an error connection. #{e}")
      test_ok = false
    ensure
      break unless test_ok
    end
  end

  Chef::Log.debug("connectivity.rb ::: GCC test_ok => #{test_ok}")
  node.normal['gcc_link'] = test_ok

  # ATTENTION: This resource does not change if there is connectivity
  new_resource.updated_by_last_action(!test_ok)
end

DATE = Time.now.to_i.to_s.freeze
NETBACKUP_DIR = '/var/lib/gecos-agent/network/'.freeze
BACKUPS = [
  '/etc/environment',
  '/etc/apt/apt.conf.d/',
  '/etc/dconf/',
  '/etc/NetworkManager/'
].freeze

action :backup do
  Chef::Log.debug('connectivity.rb ::: BACKUP action')
  unless ::File.directory?("#{NETBACKUP_DIR}#{DATE}")
    FileUtils.mkdir_p("#{NETBACKUP_DIR}#{DATE}")
  end

  BACKUPS.each do |bak|
    dst = "#{NETBACKUP_DIR}#{DATE}" + ::File.dirname(bak)
    Chef::Log.debug("connectivity.rb ::: BACKUP action - dst:#{dst}")
    FileUtils.mkdir_p(dst)
    FileUtils.cp_r bak, dst if ::File.exist?(bak)
  end
end

action :recovery do
  Chef::Log.debug('connectivity.rb ::: RECOVERY action')

  Dir.chdir(NETBACKUP_DIR) do
    Dir.glob('*').sort.reverse_each do |bakdir|
      Chef::Log.debug("connectivity.rb ::: RECOVERY action - bakdir=#{bakdir}")
      src = NETBACKUP_DIR + bakdir
      Chef::Log.debug("connectivity.rb ::: RECOVERY action - src=#{src}")
      BACKUPS.each do |bak|
        if ::File.file?(bak)
          FileUtils.rm bak
          FileUtils.cp "#{src}#{bak}", bak if ::File.exist?("#{src}#{bak}")
        elsif ::File.directory?(bak)
          FileUtils.rm_rf bak
          FileUtils.cp_r "#{src}#{bak}", bak if ::File.exist?("#{src}#{bak}")
        end
      end

      service 'network-manager' do
        case $gecos_os
        when 'GECOS V2', 'Gecos V2 Lite'
          provider Chef::Provider::Service::Upstart
        else
          provider Chef::Provider::Service::Systemd
        end
        action :nothing
      end.run_action(:restart)

      # Calling connectivity provider to test network connection
      gcc_conn = gecos_ws_mgmt_connectivity 'recovery_connectivity' do
        action :nothing
      end
      gcc_conn.run_action(:test)

      Chef::Log.debug('connectivity.rb ::: gcc_conn.updated_by_last_action? ='\
          " #{gcc_conn.updated_by_last_action?}")
      unless gcc_conn.updated_by_last_action?
        node.override['gcc_link'] = false
        break
      end
    end
  end
end
