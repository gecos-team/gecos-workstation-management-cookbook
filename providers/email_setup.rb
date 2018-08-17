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

action :setup do

  begin

    # Checking OS and Thunderbird
    if new_resource.support_os.include?($gecos_os)

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

          $required_pkgs['email_setup'].each do |pkg|
            Chef::Log.debug("email_setup.rb - REQUIRED PACKAGE = %s" % pkg)
            package pkg do
              action :nothing
            end.run_action(:install)
          end
          
          # Create GECOS profile if doesn't exists
          homedir = `eval echo ~#{username}`.gsub("\n","")
          thunderbird_dir = "#{homedir}/.thunderbird"
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
          # because there is no headless mode by using MOZ_HEADLESS environment variable

          file '/tmp/.X99-lock' do
            action :nothing
            only_if { ::File.exists?("/tmp/.X99-lock")}
          end.run_action(:delete)

          execute "Create GECOS Profile" do
              command "Xvfb :99.0 -ac & sleep 1; thunderbird -CreateProfile 'gecos #{homedir}/.thunderbird/gecos' --display=:99.0; killall Xvfb"
              not_if { ::File.exists?("#{homedir}/.thunderbird/gecos") }
              user username
              environment ({'HOME' => homedir, 'USER' => username})
              action :nothing
              timeout 30
          end.run_action(:run)

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
              action :nothing
          end.run_action(:run)

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

          # Chef::Log.info("template = #{template}")          
           
          # Check if there are configuration changes by 
          # comparing the current template signature and the 
          # previous template signature
          current_hash = Digest::SHA256.hexdigest template
          
          previous_hash = ''
          if ::File.exist?("#{homedir}/.thunderbird/gecos/digest")
            previous_hash = ::File.read("#{homedir}/.thunderbird/gecos/digest")
          end
           
          # Chef::Log.info("current_hash = #{current_hash} previous_hash = #{previous_hash}")   
           
          file "#{homedir}/.thunderbird/gecos/prefs.js" do
            content template
            mode '0755'
            owner username
            group gid
            action :nothing
            only_if { ::File.exist?("#{homedir}/.thunderbird/gecos") and previous_hash != current_hash }
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

          directory "/var/cache/gecos" do
            mode '0755'
            action :nothing
          end.run_action(:create)
  
          directory "/var/cache/gecos/email_setup" do
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
            xid = shell_out("unzip -qc #{plugin_file} install.rdf |  xmlstarlet sel \
                            -N rdf=http://www.w3.org/1999/02/22-rdf-syntax-ns# \
                            -N em=http://www.mozilla.org/2004/em-rdf# \
                            -t -v \
                            \"//rdf:Description[@about='urn:mozilla:install-manifest']/em:id\"").stdout

            Chef::Log.info("email_setup.rb - Extension ID = #{xid}")
            

            # Check if the extension is already installed by
            # querying firefox extensions databases
            xfiles = [ "extensions.json", "extensions.sqlite", "extensions.rdf" ]        
            installed = false

            xfiles.each do |xfile|        
              xf = "#{homedir}/.thunderbird/gecos/#{xfile}"
              Chef::Log.debug("web_browser.rb - Extension file = #{xf}")
              if ::File.exist?(xf)
                installed = case xfile
                  when /\.json$/i
                    jfile = ::File.read(xf)
                    addons = JSON.parse(jfile)["addons"]                
                    Chef::Log.debug("web_browser.rb - JSON addons: #{addons}")
                    addons.any?{|h| h["id"] == xid}
                  when /\.sqlite$/
                    db = SQLite3::Database.open(xf)
                    addons = db.get_first_value("SELECT locale.name, locale.description, addon.version, addon.active, addon.id FROM addon 
                      INNER JOIN locale on locale.id = addon.defaultLocale WHERE addon.type = 'extension' AND addon.id = '#{xid}'
                      ORDER BY addon.active DESC, UPPER(locale.name)")
                    Chef::Log.debug("web_browser.rb - SQLite addons: #{addons}")
                    !addons.nil?
                  else   
                    !!::File.open(xf).read().match(xid) # operator !! forces true/false returned
                  end # case xfile
              end # if ::File.exist?(xf)
              break if installed
            end # xfiles.each
            Chef::Log.info("email_setup.rb - Installed plugin? #{installed}")

            if not installed
              plugin_dir_temp = "#{plugin_file}_temp"
              Chef::Log.info("email_setup.rb - Extract plugin file to temporal directory: #{plugin_file} --> #{plugin_dir_temp}")
              bash "extract plugin #{plugin_file}" do
                action :nothing
                code <<-EOH
                  rm -rf #{plugin_dir_temp}
                  mkdir -p #{plugin_dir_temp}
                  unzip -o #{plugin_file} -d #{plugin_dir_temp}
                EOH
              end.run_action(:run)

              source = plugin_dir_temp
              destination = "#{exdir}/#{xid}"
          
              Chef::Log.info("email_setup.rb - Move directory: #{source} --> #{destination}")
              ::FileUtils.mkdir_p(exdir)
              ::FileUtils.mv(source, destination)       


     
            end # if not installed



          end # data['plugins'].each

           
        

          bash "chown #{username}" do
            code <<-EOH 
              chown -R #{username}:#{gid} #{homedir}/.thunderbird/gecos
            EOH
            action :nothing
          end.run_action(:run)
           
	end # if user.base.email_setup
        
      end # users.each_key
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
