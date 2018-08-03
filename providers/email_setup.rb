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
require 'chef/mixin/shell_out'
require 'securerandom'
include Chef::Mixin::ShellOut

action :setup do

  begin

    # Checking OS and Thunderbird
    if new_resource.support_os.include?($gecos_os)

      # Install thunderbird (in Spanish)
      package 'thunderbird-locale-es-es' do
        action :install
      end
      
      # Xvfb is necessary for running thunderbird -CreateProfile
      # because there is no headless mode by using MOZ_HEADLESS environment variable
      package 'xvfb' do
        action :install
      end     
      

      # Setup email for users
      users = new_resource.users
      users.each_key do |user_key|

        user = users[user_key]
        nameuser = user_key 
        username = nameuser.gsub('###','.')
        gid = Etc.getpwnam(username).gid

        # Check if the email must be configured
        Chef::Log.info("Check if the email must be configured")
         if user.base.email_setup

          # Create GECOS profile if doesn't exists
          homedir = `eval echo ~#{username}`.gsub("\n","")
          thunderbird_dir = "#{homedir}/.thunderbird"
          thunderbird_profiles = "#{homedir}/.thunderbird/profiles.ini"

          directory "#{homedir}/.thunderbird" do
             owner username
             group gid
             mode '700'
             action :create
          end

          directory "#{homedir}/.cache" do
            mode '0755'
            owner username
            group gid
            action :create
          end
           
           
          file '/tmp/.X99-lock' do
            action :delete
            only_if { ::File.exists?("/tmp/.X99-lock")}
          end

          execute "Create GECOS Profile" do
              command "Xvfb :99.0 -ac & sleep 1; thunderbird -CreateProfile 'gecos #{homedir}/.thunderbird/gecos' --display=:99.0; killall Xvfb"
              not_if { ::File.exists?("#{homedir}/.thunderbird/gecos") }
              user username
              environment ({'HOME' => homedir, 'USER' => username})
              action :run
              timeout 30
          end

          ruby_block "Remove thunderbird default profile" do
              block do

                Chef::Log.info("Check if must be the default profile")
                # Check if must be the default profile
 
                mustAddDefaultLine = true
                if ::File.exists?(thunderbird_profiles)
                  mustAddDefaultLine = true

                  # If profiles.ini file exists then we must parse it 
                  # to ensure that "gecos" is the default profile

                  fileObj = ::File.new(thunderbird_profiles, "r")
                  currentProfileName = ''
                  isDefaultProfileMarked = false
                  while (line = fileObj.gets)
                      line = line.strip

                      if line.start_with?('Name=')
                          currentProfileName = line[/=../]
                      end

                      if line == 'Default=1'
                          isDefaultProfileMarked = true
                          break
                      end


                  end
                  fileObj.close


                  if isDefaultProfileMarked and currentProfileName == 'gecos'
                      Chef::Log.info("gecos is already the default profile")
                      mustAddDefaultLine = false
                  end

                end

                if mustAddDefaultLine
                  Chef::Log.info("Set gecos as the default profile")
                  fe = Chef::Util::FileEdit.new(thunderbird_profiles)
                  # Remove "Default=1" if exists
                  fe.search_file_delete_line("Default=1")
                  # Insert "Default=1" in "gecos" profile
                  fe.insert_line_after_match("Path=gecos", "Default=1")
                  fe.write_file
                end



              end
              only_if { user.base.default_email }
              action :run
          end

          # Prepare environment variables
          VariableManager.reset_environ()
          VariableManager.add_to_environ(user_key)

          Chef::Log.info("Replace keys by the written values #{user_key}")
          if VariableManager.expand_variables(user.identity.name)
              VariableManager.add_key_to_environ('FIRSTNAME', VariableManager.expand_variables(user.identity.name))
          else
              VariableManager.add_key_to_environ('FIRSTNAME', user.identity.name)
          end

          if VariableManager.expand_variables(user.identity.surname)
              VariableManager.add_key_to_environ('LASTNAME', VariableManager.expand_variables(user.identity.surname))
          else
              VariableManager.add_key_to_environ('LASTNAME', user.identity.surname)
          end

          email = user.identity.email
          if VariableManager.expand_variables(email)
              email = VariableManager.expand_variables(email) 
          end

          Chef::Log.info("email #{email}")
          VariableManager.add_key_to_environ('EMAIL', email)
          VariableManager.add_key_to_environ('EMAILUSER', email.split('@')[0])
          VariableManager.add_key_to_environ('EMAILDOMAIN', email.split('@')[1])

          # Get the appropiate template
          data = data_bag_item('email_templates', user.base.email_template.downcase)

          template = ''
          data['prefs_js'].each do |line|
              expanded_line = VariableManager.expand_variables(line)
              # Return an error if the expanded_line returns nil
              if not expanded_line
                  raise 'Variables expansion error!'
              end

              template = template + expanded_line + "\n"
          end

          Chef::Log.info("template = #{template}")          
           
           
           
          file "#{homedir}/.thunderbird/gecos/prefs.js" do
            content template
            mode '0755'
            owner username
            group gid
            action :create
            only_if { ::File.exist?("#{homedir}/.thunderbird/gecos") }
          end

	end
        



      end
    else
      Chef::Log.info("This resource is not support into your OS")
    end
   
    # save current job ids (new_resource.job_ids) as "ok"
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
    
    gecos_ws_mgmt_jobids "email_setup_res" do
       recipe "users_mgmt"
    end.run_action(:reset)
    
  end
end
