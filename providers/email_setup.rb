#
# Cookbook Name:: gecos-ws-mgmt
# Provider:: email_setup
#
# Copyright 2018, Junta de Andalucia
# http://www.juntadeandalucia.es/
#
# All rights reserved - EUPL License V 1.1
# http://www.osor.eu/eupl
#
require 'json'
require 'uri'

#
# Parse profiles.ini file and get the current profile
# name and a boolean that indicates if the default profile is
# marked
#
def parse_profiles_ini(thunderbird_profiles)
  # If profiles.ini file exists then we must parse it
  # to ensure that "gecos" is the default profile
  file_obj = ::File.new(thunderbird_profiles, 'r')
  current_profile_name = ''
  is_default_marked = false
  while (line = file_obj.gets)
    line = line.strip
    current_profile_name = line[/=../] if line.start_with?('Name=')
    is_default_marked ||= (line == 'Default=1')
  end
  file_obj.close

  [current_profile_name, is_default_marked]
end

#
# Marks "gecos" as the default profile inside profile.ini file
#
def mark_gecos_as_default_profile(thunderbird_profiles)
  Chef::Log.info('Set gecos as the default profile')
  fe = Chef::Util::FileEdit.new(thunderbird_profiles)
  # Remove "Default=1" if exists
  fe.search_file_delete_line('Default=1')
  # Insert "Default=1" in "gecos" profile
  fe.insert_line_after_match('Path=gecos', 'Default=1')
  fe.write_file
end

#
# Set "gecos" as the default user profile
#
def setup_gecos_as_default_profile(profile_ini)
  Chef::Log.info('Check if must be the default profile')
  # Check if must be the default profile
  must_add_default_line = true
  if ::File.exist?(profile_ini)
    current_profile_name, is_default_profile_marked =
      parse_profiles_ini(profile_ini)

    # Check if gecos is already the default profile
    must_add_default_line = !is_default_profile_marked ||
                            current_profile_name != 'gecos'
  end

  mark_gecos_as_default_profile(profile_ini) if must_add_default_line
end

action :setup do
  begin
    # Checking OS and Thunderbird
    if new_resource.support_os.include?($gecos_os)
      # Setup email for users
      users = new_resource.users
      users.each_key do |user_key|
        user = users[user_key]
        nameuser = user_key
        username = nameuser.gsub('###', '.')
        gid = Etc.getpwnam(username).gid

        # Check if the email must be configured
        Chef::Log.info('Check if the email must be configured')
        next unless user.base.email_setup

        $required_pkgs['email_setup'].each do |pkg|
          Chef::Log.debug("email_setup.rb - REQUIRED PACKAGE = #{pkg}")
          package pkg do
            action :nothing
          end.run_action(:install)
        end

        # Create GECOS profile if doesn't exists
        homedir = `eval echo ~#{username}`.delete("\n")
        thunderbird_profiles = "#{homedir}/.thunderbird/profiles.ini"

        directory "#{homedir}/.thunderbird" do
          owner username
          group gid
          mode '700'
          action :nothing
        end.run_action(:create)

        directory "#{homedir}/.cache" do
          mode '0755'
          owner username
          group gid
          action :nothing
        end.run_action(:create)

        # Xvfb is necessary for running thunderbird -CreateProfile
        # because there is no headless mode by using MOZ_HEADLESS
        # environment variable
        file '/tmp/.X99-lock' do
          action :nothing
          only_if { ::File.exist?('/tmp/.X99-lock') }
        end.run_action(:delete)

        env_hash = { 'HOME' => homedir, 'USER' => username }
        execute 'Create GECOS Profile' do
          command 'Xvfb :99.0 -ac & sleep 1; thunderbird -CreateProfile '\
            "'gecos #{homedir}/.thunderbird/gecos' "\
            '--display=:99.0; killall Xvfb'
          not_if { ::File.exist?("#{homedir}/.thunderbird/gecos") }
          user username
          environment env_hash
          action :nothing
          timeout 30
        end.run_action(:run)

        if user.base.default_email
          setup_gecos_as_default_profile(thunderbird_profiles)
        end

        # Prepare environment variables
        VariableManager.reset_environ
        VariableManager.add_to_environ(user_key)

        Chef::Log.info("Replace keys by the written values #{user_key}")
        if VariableManager.expand_variables(user.identity.name)
          VariableManager.add_key_to_environ(
            'FIRSTNAME',
            VariableManager.expand_variables(user.identity.name)
          )
        else
          VariableManager.add_key_to_environ(
            'FIRSTNAME',
            user.identity.name
          )
        end

        if VariableManager.expand_variables(user.identity.surname)
          VariableManager.add_key_to_environ(
            'LASTNAME',
            VariableManager.expand_variables(user.identity.surname)
          )
        else
          VariableManager.add_key_to_environ(
            'LASTNAME',
            user.identity.surname
          )
        end

        email = user.identity.email
        if VariableManager.expand_variables(email)
          email = VariableManager.expand_variables(email)
        end

        Chef::Log.info("email #{email}")
        VariableManager.add_key_to_environ('EMAIL', email)
        VariableManager.add_key_to_environ(
          'EMAILUSER',
          email.split('@')[0]
        )
        VariableManager.add_key_to_environ(
          'EMAILDOMAIN',
          email.split('@')[1]
        )

        # Get the appropiate template
        data = data_bag_item(
          'email_templates',
          user.base.email_template.downcase
        )

        template = ''
        data['prefs_js'].each do |line|
          expanded_line = VariableManager.expand_variables(line)
          # Return an error if the expanded_line returns nil
          raise 'Variables expansion error!' unless expanded_line

          template += expanded_line + "\n"
        end

        # Check if there are configuration changes by
        # comparing the current template signature and the
        # previous template signature
        current_hash = Digest::SHA256.hexdigest template

        previous_hash = ''
        if ::File.exist?("#{homedir}/.thunderbird/gecos/digest")
          previous_hash = ::File.read("#{homedir}/"\
              '.thunderbird/gecos/digest')
        end

        file "#{homedir}/.thunderbird/gecos/prefs.js" do
          content template
          mode '0755'
          owner username
          group gid
          action :nothing
          only_if do
            ::File.exist?("#{homedir}/.thunderbird/gecos") &&
              previous_hash != current_hash
          end
        end.run_action(:create)

        file "#{homedir}/.thunderbird/gecos/digest" do
          content current_hash
          mode '0700'
          owner username
          group gid
          action :nothing
          only_if { ::File.exist?("#{homedir}/.thunderbird/gecos") }
        end.run_action(:create)

        # Extensions download
        exdir = "#{homedir}/.thunderbird/gecos/extensions"

        directory exdir do
          owner username
          group gid
          action :nothing
        end.run_action(:create)

        directory '/var/cache/gecos' do
          mode '0755'
          action :nothing
        end.run_action(:create)

        directory '/var/cache/gecos/email_setup' do
          mode '0755'
          action :nothing
        end.run_action(:create)

        data['plugins'].each do |plugin_data|
          Chef::Log.info("Checking addon: #{plugin_data['name']}")

          uri = URI.parse(plugin_data['url'])
          plugin_file_name = ::File.basename(uri.path)
          plugin_file = "/var/cache/gecos/email_setup/#{plugin_file_name}"

          # Download extension if necessary
          remote_file plugin_file do
            source plugin_data['url']
            action :nothing
          end.run_action(:create_if_missing)

          # Get extension ID
          xid = MozillaPluginManager.get_extension_id(plugin_file)

          # Check if the extension is already installed
          expath = Pathname.new("#{homedir}/.thunderbird/gecos/")
          installed = MozillaPluginManager.extension_installed?(xid, expath)
          Chef::Log.info("email_setup.rb - Installed plugin? #{installed}")

          next if installed

          MozillaPluginManager.install_plugin_on_version(
            0, plugin_file, exdir, xid, username
          )
        end

        bash "chown #{username}" do
          code "chown -R #{username}:#{gid} #{homedir}/.thunderbird/gecos"
          action :nothing
        end.run_action(:run)
      end
    else
      Chef::Log.info('This resource is not supported in your OS')
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
    gecos_ws_mgmt_jobids 'email_setup_res' do
      recipe 'users_mgmt'
    end.run_action(:reset)
  end
end
