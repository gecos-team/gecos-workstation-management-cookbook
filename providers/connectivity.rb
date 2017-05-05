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
    
   # Load new root environment because of proxy environ vars
   proxyenv = '/tmp/proxyenv'  
   file proxyenv do
       action :nothing
   end.run_action(:delete)

   bash 'root_source_environment' do
       code <<-EOH
            unset HTTP_PROXY HTTPS_PROXY
            source /etc/environment
            echo "http_proxy=$HTTP_PROXY"  > #{proxyenv}
	    echo "https_proxy=$HTTPS_PROXY" >> #{proxyenv}
       EOH
       action :nothing
   end.run_action(:run)

   Chef::Log.debug("connectivity.rb ::: root_source_environment")
   ruby_block "Proxy Environ" do
       only_if { ::File.exists?(proxyenv) }
       block do
               file = ::File.read(proxyenv)
               ENV['HTTP_PROXY']  = file.scan(/http_proxy=(.*)/).flatten.pop
               ENV['HTTPS_PROXY'] = file.scan(/https_proxy=(.*)/).flatten.pop
       end
       action :nothing
   end.run_action(:run)

   Chef::Log.debug("connectivity.rb ::: ENV['HTTP_PROXY']  => #{ENV['HTTP_PROXY']}")
   Chef::Log.debug("connectivity.rb ::: ENV['HTTPS_PROXY'] => #{ENV['HTTPS_PROXY']}")

   ENV['HTTP_PROXY'] ||= ''
   ENV['HTTPS_PROXY'] ||= ''

   ENV['HTTP_PROXY']  = "http://".concat(ENV['HTTP_PROXY'])  if !(ENV['HTTP_PROXY'].empty? || ENV['HTTP_PROXY'].include?("http://"))
   ENV['HTTPS_PROXY'] = "https://".concat(ENV['HTTP_PROXY']) if !(ENV['HTTPS_PROXY'].empty? || ENV['HTTPS_PROXY'].include?("https://"))

   Chef::Log.debug("connectivity.rb ::: ENV['HTTP_PROXY']  => #{ENV['HTTP_PROXY']}")
   Chef::Log.debug("connectivity.rb ::: ENV['HTTPS_PROXY'] => #{ENV['HTTPS_PROXY']}")
   
   # Parsing 
   http_proxy_host  = URI.parse(ENV['HTTP_PROXY']).host || ENV['HTTP_PROXY']
   http_proxy_port  = URI.parse(ENV['HTTP_PROXY']).port
   https_proxy_host = URI.parse(ENV['HTTPS_PROXY']).host || ENV['HTTPS_PROXY']
   https_proxy_port = URI.parse(ENV['HTTPS_PROXY']).port
   Chef::Log.debug("connectivity.rb ::: http_proxy_host  => #{http_proxy_host}")
   Chef::Log.debug("connectivity.rb ::: http_proxy_port  => #{http_proxy_port}")
   Chef::Log.debug("connectivity.rb ::: https_proxy_host => #{https_proxy_host}")
   Chef::Log.debug("connectivity.rb ::: https_proxy_port => #{https_proxy_port}")

   # Gecos Control Center (GCC)
   wget_opts = case scheme 
       when 'http';  "-q"
       when 'https'; "-q --no-check-certificate"
   end
   wget_cmd = "wget #{wget_opts} #{scheme}://#{host}:#{port} -O /dev/null"
   Chef::Log.debug("connectivity.rb ::: wget command => #{wget_cmd}")

   wget_exe = shell_out("#{wget_cmd}", :env => {'http_proxy' => ENV['HTTP_PROXY'],'https_proxy' => ENV['HTTPS_PROXY']})
   test_ok = wget_exe.exitstatus == 0
   Chef::Log.debug("connectivity.rb ::: GCC test_ok => #{test_ok}") 
   Chef::Log.debug("connectivity.rb ::: wget.exitstatus => #{wget_exe.exitstatus}") 

   node.normal['gcc_link'] = if test_ok
      true
   else
      false
   end

   # ATTENTION: This resource does not change if there is connectivity
   new_resource.updated_by_last_action(!test_ok)
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
              Chef::Log.debug("connectivity.rb ::: RECOVERY action - bak=#{bak}")
              if ::File.file?(bak)
                  Chef::Log.debug("connectivity.rb ::: RECOVERY action - is File")
                  FileUtils.rm bak
                  FileUtils.cp "#{src}#{bak}", bak if ::File.exists?("#{src}#{bak}")
              elsif ::File.directory?(bak)
                  Chef::Log.debug("connectivity.rb ::: RECOVERY action - is Directory")
                  FileUtils.rm_rf bak
                  FileUtils.cp_r "#{src}#{bak}", bak if ::File.exists?("#{src}#{bak}")
                  Chef::Log.debug("connectivity.rb ::: RECOVERY action - directory deleted? #{::File.directory?(bak)}")
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
