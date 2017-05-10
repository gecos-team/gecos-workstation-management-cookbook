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

require 'chef/mixin/shell_out'
require 'uri'
require 'net/http'
require 'openssl'
require 'json'
include Chef::Mixin::ShellOut

action :test do
   Chef::Log.debug("connectivity.rb ::: TEST action")

   test_ok = true

   # GCC uri
   file = ::File.read('/etc/gcc.control')
   gcc_control = JSON.parse(file)
   Chef::Log.debug("connectivity.rb ::: gcc_control => #{gcc_control}")

   # Defaults: target = GCC 
   target = new_resource.target || gcc_control['uri_gcc']
   Chef::Log.debug("connectivity.rb ::: target => #{target}")

   scheme = URI.parse(target).scheme.downcase
   Chef::Log.debug("connectivity.rb ::: scheme => #{scheme}")

   host = URI.parse(target).host || target
   Chef::Log.debug("connectivity.rb ::: host => #{host}")

   port = case new_resource.port.nil?
       when false; new_resource.port
       when true;  URI.parse(target).port
   end

   # Defaults
   port ||= case scheme
     when 'http';  80
     when 'https'; 443
   end
   Chef::Log.debug("connectivity.rb ::: port  => #{port}")
    
   proxy_from_etc = proxy_ssl_from_etc = nil
   ruby_block "HTTP(S)_PROXY etc_environment" do
       block do
           file = ::File.read('/etc/environment')
           proxy_from_etc     = file.scan(/http_proxy=(.*)/i).flatten.pop  || ''
           proxy_ssl_from_etc = file.scan(/https_proxy=(.*)/i).flatten.pop || ''
       end
       action :nothing
   end.run_action(:run)

   Chef::Log.debug("connectivity.rb ::: proxy_from_etc => #{proxy_from_etc}")
   Chef::Log.debug("connectivity.rb ::: proxy_ssl_from_etc => #{proxy_ssl_from_etc}")

   proxy_from_etc     = 'http://'.concat(proxy_from_etc) unless proxy_from_etc.start_with?('','http://')
   proxy_ssl_from_etc = 'https://'.concat(proxy_ssl_from_etc) unless  proxy_ssl_from_etc.start_with?('','https://')
   
   Chef::Log.debug("connectivity.rb ::: proxy_from_etc => #{proxy_from_etc}")
   Chef::Log.debug("connectivity.rb ::: proxy_ssl_from_etc => #{proxy_ssl_from_etc}")

   # GCC or target url
   url = URI.parse("#{scheme}://#{host}:#{port}")

   begin
      # Using proxy if exists
      proxy = case scheme
          when 'http' then  
              URI.parse(proxy_from_etc)
          when 'https'then
              URI.parse(proxy_ssl_from_etc)
      end
 
      if proxy
         http = Net::HTTP.new(url.host, url.port, proxy.host, proxy.port)
      else
         http = Net::HTTP.new(url.host, url.port)
      end

      if scheme == 'https'
          http.use_ssl = true
          http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end

      # Following redirects
      max_follow = 5
      response = nil
      max_follow.times{
          response = http.request_get(url.request_uri)
          break unless response.kind_of?(Net::HTTPRedirection)
          url = URI.parse(response['location'])
      }
      
      Chef::Log.debug("connectivity.rb ::: response.code #{response.code}") 
      Chef::Log.debug("connectivity.rb ::: response.code #{response.code}") 
      test_ok = case response  
          when Net::HTTPOK; true
          else false
      end

   rescue Timeout::Error, EOFError,
      Errno::EINVAL, Errno::ECONNRESET, Errno::EHOSTUNREACH, Errno::ECONNREFUSED,
      Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError, Net::ProtocolError => e

      Chef::Log.debug("connectivity.rb ::: There was an error connection. #{e}") 
      test_ok = false

   ensure
      Chef::Log.debug("connectivity.rb ::: GCC test_ok => #{test_ok}") 
      node.normal['gcc_link'] = test_ok

      # ATTENTION: This resource does not change if there is connectivity
      new_resource.updated_by_last_action(!test_ok)
   end
end

DATE = DateTime.now.to_time.to_i.to_s
NETBACKUP_DIR = "/var/lib/gecos-agent/network/"
BACKUPS = [
    '/etc/environment',
    '/etc/apt/apt.conf.d/',
    '/etc/dconf/',
    '/etc/NetworkManager/'
]

action :backup do
   Chef::Log.debug("connectivity.rb ::: BACKUP action")
   unless Kernel::test('d', "#{NETBACKUP_DIR}#{DATE}")
       FileUtils.mkdir_p("#{NETBACKUP_DIR}#{DATE}")
   end

   BACKUPS.each do |bak| 
       dst = "#{NETBACKUP_DIR}#{DATE}" + ::File.dirname(bak)
       Chef::Log.debug("connectivity.rb ::: BACKUP action - dst:#{dst}")
       FileUtils.mkdir_p(dst)
       FileUtils.cp_r bak, dst if ::File.exists?(bak)
   end
end

action :recovery do
   Chef::Log.debug("connectivity.rb ::: RECOVERY action")
   
   Dir.chdir(NETBACKUP_DIR) do
      Dir.glob('*').sort.reverse.each do |bakdir|
          Chef::Log.debug("connectivity.rb ::: RECOVERY action - bakdir=#{bakdir}")
          src = NETBACKUP_DIR + bakdir
          Chef::Log.debug("connectivity.rb ::: RECOVERY action - src=#{src}")
          BACKUPS.each do |bak|
              if ::File.file?(bak)
                  FileUtils.rm bak
                  FileUtils.cp "#{src}#{bak}", bak if ::File.exists?("#{src}#{bak}")
              elsif ::File.directory?(bak)
                  FileUtils.rm_rf bak
                  FileUtils.cp_r "#{src}#{bak}", bak if ::File.exists?("#{src}#{bak}")
              end
          end

          service 'network-manager' do
            case $gecos_os
              when "GECOS V2","Gecos V2 Lite"; provider Chef::Provider::Service::Upstart
              else provider Chef::Provider::Service::Systemd
            end
            action :nothing
          end.run_action(:restart)

          # Calling connectivity provider to test network connection
          gcc_conn = gecos_ws_mgmt_connectivity 'recovery_connectivity' do
              action :nothing
          end
          gcc_conn.run_action(:test)
          
          Chef::Log.debug("connectivity.rb ::: gcc_conn.updated_by_last_action? = #{gcc_conn.updated_by_last_action?}")
          if !gcc_conn.updated_by_last_action?
              node.override['gcc_link'] = false
              break
          end
      end
   end
end
