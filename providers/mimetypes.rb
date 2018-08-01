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

# Constants
DEFAULT_SECTION='Default Applications'
ADDED_SECTION='Added Associations'

action :setup do
  begin
    if new_resource.support_os.include?($gecos_os)
      $required_pkgs['mimetypes'].each do |pkg|
        Chef::Log.debug("mimetypes.rb - REQUIRED PACKAGE = %s" % pkg)
        package pkg do
          action :nothing
        end.run_action(:install)
      end

      gem_depends = [ 'inifile' ]
      gem_depends.each do |gem|
        gem_package gem do
          gem_binary($gem_path)
            action :nothing
        end.run_action(:install)
      end
      Gem.clear_paths
      require 'inifile'

      users = new_resource.users

      users.each_key do |user_key|
      
        nameuser = user_key
        username = nameuser.gsub('###','.')
        user = users[user_key]
        gid = Etc.getpwnam(username).gid

        directory "/home/#{username}/.local/share/applications" do
          owner username
          group gid
          recursive true
        end

        Chef::Log.debug("mimetypes.rb - Users: #{user}")
        
        # File associations stored
        localshareapp = "/home/#{username}/.local/share/applications"
        directory localshareapp do
          owner username
          group gid
          recursive true
        end

        # Parse file associations stored
        mimeapps = {}
        mimefile = "#{localshareapp}/mimeapps.list"
        if ::File.exists?(mimefile)
          ini = IniFile.load(mimefile)
          if ini.has_section?(DEFAULT_SECTION)
            mimeapps = ini[DEFAULT_SECTION]
          end
        end

        Chef::Log.debug("mimetypes.rb - mimeapps: #{mimeapps}")

        user.mimetyperelationship.each do |assoc|
          Chef::Log.debug("mimetypes.rb - assoc: #{assoc}")

          desktopfile = assoc.desktop_entry
          if ! desktopfile.include? "\.desktop"
             desktopfile.concat(".desktop")
          end

          Chef::Log.debug("mimetypes.rb - desktop: #{desktopfile}")
          
          # Only new changes
          mimes = assoc.mimetypes.reject { |x| mimeapps.key?(x) && mimeapps[x] == desktopfile }
          Chef::Log.debug("mimetypes.rb - mimes: #{mimes}")

          execute "xdg-mime execution commmand" do
            action :run
            user username
            group gid
            environment ({'HOME' => "/home/#{username}", 'USER' => "#{username}"})
            command "xdg-mime default #{desktopfile} #{mimes.join(" ")}"
            not_if do
              if !::File.exists?("/usr/share/applications/#{desktopfile}")
                Chef::Log.warn("mimetypes.rb - Application file (.desktop) not found: #{desktopfile}")
                true
              elsif mimes.empty?
                Chef::Log.warn("mimetypes.rb - No changes for #{desktopfile}: #{mimes}")
                true
              end
            end
          end
                      
        end
      end
    else
      Chef::Log.info("This resource is not support into your OS")
    end
    
    job_ids = new_resource.job_ids
    job_ids.each do |jid|
      node.normal['job_status'][jid]['status'] = 0
    end

    rescue Exception => e
    # just save current job ids as "failed"
    # save_failed_job_ids
    Chef::Log.error(e.message)
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
    
    gecos_ws_mgmt_jobids "mimetypes_res" do
       recipe "users_mgmt"
    end.run_action(:reset)
    
  end  
end
