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

require 'etc'
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
				gid = Etc.getpwnam(username).gid
				xdg_code = ''

				directory "/home/#{username}/.local/share/applications" do
					owner username
					group gid
					recursive true
				end

				Chef::Log.debug("mimetypes.rb - Users: #{user}")

				user.mimetyperelationship.each do |assoc|
					Chef::Log.debug("mimetypes.rb - assoc: #{assoc}")

					desktopfile = assoc.desktop_entry
					if ! desktopfile.include? "\.desktop"
   				  desktopfile.concat(".desktop")
					end

					mimes = assoc.mimetypes
					Chef::Log.debug("mimetypes.rb - desktop: #{desktopfile}")
					Chef::Log.debug("mimetypes.rb - mimes: #{mimes.join(" ")}")

					if ::File::exists?("/usr/share/applications/#{desktopfile}")
						xdg_code += "xdg-mime default #{desktopfile} #{mimes.join(" ")};"
					end
				end

				Chef::Log.debug("mimetypes.rb - xdg_code: #{xdg_code}")
				bash "default program #{username}" do
					action :run
					user username
					group gid
					environment ({'HOME' => "/home/#{username}", 'USER' => "#{username}"})
     			code "#{xdg_code}"
   			end
			end
  	end
	end
end 
