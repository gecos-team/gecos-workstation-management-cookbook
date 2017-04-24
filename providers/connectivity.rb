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

   # Defaults: target = GCC 
   target = new_resource.target || gcc_control['uri_gcc']
   target = URI.parse(target).host || target
   port = new_resource.port || 80
   Chef::Log.debug("connectivity.rb ::: target => #{target}")
   Chef::Log.debug("connectivity.rb ::: port => #{port}")
   Chef::Log.debug("connectivity.rb ::: gcc_control => #{gcc_control}")
    
   # Environ proxy variables if exist
   #node['ohai_gecos']['users'].each do |user|
   #    Chef::Log.debug("connectivity.rb ::: user =>> #{user}")
   #    if user.uid.to_i >= 1000
   #        ENV['HTTP_PROXY']  = shell_out("su - #{user.username} -c \"printenv HTTP_PROXY\"").stdout
   #        ENV['HTTPS_PROXY'] = shell_out("su - #{user.username} -c \"printenv HTTPS_PROXY\"").stdout
   #        break
   #    end
   #end

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

   if !(http_proxy_host.empty? && https_proxy_host.empty?)
       # Pinging Proxy
       proxy_ping = "ping -q -w 1 -c 1 #{http_proxy_host} > /dev/null"
       ssl_proxy_ping = "ping -q -w 1 -c 1 #{https_proxy_host} > /dev/null"

       proxy_cmd = shell_out("#{proxy_ping}").exitstatus == 0
       ssl_proxy_cmd = shell_out("#{ssl_proxy_ping}").exitstatus == 0
       Chef::Log.debug("connectivity.rb ::: proxy_cmd => #{proxy_cmd}") 
       Chef::Log.debug("connectivity.rb ::: ssl_proxy_cmd => #{ssl_proxy_cmd}") 
  
       test_ok = (proxy_cmd or ssl_proxy_cmd)
       Chef::Log.debug("connectivity.rb ::: proxy test_ok => #{test_ok}") 
   end

   # Pinging Gecos Control Center (GCC)
   if (test_ok)
       ping = "ping -q -w 1 -c 1 #{target} > /dev/null"
       wget = "wget -q --no-check-certificate #{target}:#{port} -O /dev/null"
   
       ping_cmd = shell_out("#{ping}").exitstatus == 0
       wget_cmd = shell_out("#{wget}", :env => {'http_proxy' => ENV['HTTP_PROXY'],'https_proxy' => ENV['HTTPS_PROXY']}).exitstatus == 0

       test_ok = (ping_cmd && wget_cmd)
	
       node.normal['gcc_link'] = if test_ok
           true
       else
          false
       end
       Chef::Log.debug("connectivity.rb ::: GCC test_ok => #{test_ok}") 
   end

   # Commands
   #ping   = "ping -q -w 1 -c 1 #{target} > /dev/null"
   #wget   = "wget -q --no-check-certificate #{target}:#{port} -O /dev/null"
   #netcat = "netcat -z #{target} #{port} &>/dev/null"

   # HTTP
   #netcat = "netcat -z -X connect -x #{http_proxy_host}:#{http_proxy_port} #{target} #{port} &>/dev/null" if not http_proxy_host.empty?

   # HTTPS
   #netcat_ssl = "netcat -z -X connect -x #{https_proxy_host}:#{https_proxy_port} #{target} #{port} &>/dev/null" if not https_proxy_host.empty?

   #Chef::Log.debug("connectivity.rb ::: ping command => #{ping}") 
   #Chef::Log.debug("connectivity.rb ::: netcat command => #{netcat}") 
   #Chef::Log.debug("connectivity.rb ::: wget command => #{wget}") 

   # Testing
   #ping_cmd  = shell_out("#{ping}").exitstatus == 0
   #http_cmd  = shell_out("#{netcat} && #{wget}", :env => {'http_proxy' => ENV['HTTP_PROXY']}).exitstatus == 0
   #https_cmd = shell_out("#{netcat_ssl} && #{wget}", :env => {'https_proxy' => ENV['HTTPS_PROXY']}).exitstatus == 0
   
   #test_ok = if not https_proxy_host.empty?
   # ping_cmd && http_cmd && https_cmd
   #    else
   # ping_cmd && http_cmd
   #end
   
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
       FileUtils.cp_r bak, dst
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
                  FileUtils.cp "#{src}#{bak}", bak if ::File.exist?("#{src}#{bak}")
              elsif ::File.directory?(bak)
                  FileUtils.rm_rf bak
                  FileUtils.cp_r "#{src}#{bak}", bak
              end
          end  

          service 'network-manager' do
              case $gecos_os
              when "GECOS V3"
                provider Chef::Provider::Service::Systemd
              else
                provider Chef::Provider::Service::Upstart
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
