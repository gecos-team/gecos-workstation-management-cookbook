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

# Constants
DEFAULT_SECTION = 'Default Applications'.freeze

action :setup do
  begin
    if os_supported? &&
       (policy_active?('users_mgmt', 'mimetypes_res') ||
        policy_autoreversible?('users_mgmt', 'mimetypes_res'))
      $required_pkgs['mimetypes'].each do |pkg|
        Chef::Log.debug("mimetypes.rb - REQUIRED PACKAGE = #{pkg}")
        package "mimetypes_#{pkg}" do
          package_name pkg
          action :nothing
        end.run_action(:install)
      end

      gem_depends = ['inifile']
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
        username = user_key.gsub('###', '.')
        user = users[user_key]
        gid = Etc.getpwnam(username).gid

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
        if ::File.exist?(mimefile)
          ini = IniFile.load(mimefile)
          mimeapps = ini[DEFAULT_SECTION] if ini.has_section?(DEFAULT_SECTION)
        end

        Chef::Log.debug("mimetypes.rb - mimeapps: #{mimeapps}")

        user.mimetyperelationship.each do |assoc|
          Chef::Log.debug("mimetypes.rb - assoc: #{assoc}")

          desktopfile = assoc.desktop_entry
          desktopfile.concat('.desktop') unless desktopfile.include? '.desktop'

          Chef::Log.debug("mimetypes.rb - desktop: #{desktopfile}")

          # Only new changes
          mimes = assoc.mimetypes.reject do |x|
            mimeapps.key?(x) && mimeapps[x] == desktopfile
          end
          Chef::Log.debug("mimetypes.rb - mimes: #{mimes}")

          env_hash = { 'HOME' => "/home/#{username}", 'USER' => username.to_s }
          execute "xdg-mime execution commmand-#{username}-#{assoc}" do
            action :run
            user username
            group gid
            environment env_hash
            command "xdg-mime default #{desktopfile} #{mimes.join(' ')}"
            not_if do
              if !::File.exist?("/usr/share/applications/#{desktopfile}")
                Chef::Log.warn('mimetypes.rb - Application file (.desktop) '\
                    "not found: #{desktopfile}")
                true
              elsif mimes.empty?
                Chef::Log.warn("mimetypes.rb - No changes for #{desktopfile}"\
                    ": #{mimes}")
                true
              end
            end
          end
        end
      end
    end

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
    gecos_ws_mgmt_jobids 'mimetypes_res' do
      recipe 'users_mgmt'
    end.run_action(:reset)
  end
end
