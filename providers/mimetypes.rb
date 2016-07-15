#
## Cookbook Name:: gecos-ws-mgmt
## Provider:: pdf_viewer
##
## Copyright 2013, Junta de Andalucia
## http://www.juntadeandalucia.es/
##
## All rights reserved - EUPL License V 1.1
## http://www.osor.eu/eupl
##

require 'chef/mixin/shell_out'
include Chef::Mixin::ShellOut

action :setup do
	begin
	  if new_resource.support_os.include?($gecos_os)
	
    	package "xdg-utils" do
       action :nothing
      end.run_action(:install)

      users = new_resource.users

      users.each_key do |user_key|
        nameuser = user_key
        username = nameuser.gsub('###','.')
        user = users[user_key]

				directory "/home/#{username}/.local/share/applications" do
					owner username
					group username
					recursive true
				end

				Chef::Log.debug("mimetypes.rb - Users: #{user}")

				user.mimetyperelationship.each do |assoc|
			
					Chef::Log.debug("mimetypes.rb - assoc: #{assoc}")

					desktop = "#{assoc.desktop_entry}.desktop"
					mimes   = assoc.mimetypes
					Chef::Log.debug("mimetypes.rb - desktop: #{desktop}")
					Chef::Log.debug("mimetypes.rb - mimes: #{mimes.join(" ")}")

					bash "default program #{desktop}" do
						action :run
						user username
						group username
						environment ({'HOME' => "/home/#{username}", 'USER' => "#{username}"})
       			code <<-EOH
							xdg-mime default #{desktop} #{mimes.join(" ")}
						EOH
						only_if {::File.exists?("/usr/share/applications/#{desktop}")}
     			end

				end
			end
  	end
	end
end       
