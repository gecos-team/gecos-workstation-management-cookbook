#
# Cookbook Name:: gecos-ws-mgmt
# Provider:: im_setup
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

    # Checking OS and Pidgin
    if new_resource.support_os.include?($gecos_os)

      # Install required packages
      $required_pkgs['im_client'].each do |pkg|
         Chef::Log.debug("im_client.rb - REQUIRED PACKAGES = %s" % pkg)
         package pkg do
           action :nothing
         end.run_action(:install)
      end      
      
      # Setup email for users
      users = new_resource.users
      users.each_key do |user_key|

        user = users[user_key]
        nameuser = user_key 
        username = nameuser.gsub('###','.')
        gid = Etc.getpwnam(username).gid

        # Check if the email must be configured
        Chef::Log.info("Check if the instant messaging client must be configured")
        if user.base.im_setup
          homedir = `eval echo ~#{username}`.gsub("\n","")

          # Create purple directory if doesn't exists
          directory "#{homedir}/.purple" do
             owner username
             group gid
             mode '700'
             action :nothing
          end.run_action(:create)

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
          data = data_bag_item('pidgin_template', 'pidgin')

          template = ''
          data['accounts_xml'].each do |line|
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
          if ::File.exist?("#{homedir}/.purple/digest")
            previous_hash = ::File.read("#{homedir}/.purple/digest")
          end
           
          #Chef::Log.info("current_hash = #{current_hash} previous_hash = #{previous_hash}")   
          
	        if ::File.exist?("#{homedir}/.purple") and (previous_hash != current_hash or user.base.overwrite)
            if user.base.overwrite or not ::File.exist?("#{homedir}/.purple/accounts.xml")
                # If overwrite flag is active the accounts.xml must be overwritten if the content of the file 
                # is different
                previous_content = ''
                if ::File.exist?("#{homedir}/.purple/accounts.xml")
                    previous_content = ::File.read("#{homedir}/.purple/digest")
                end

                # Overwrite the whole file
                Chef::Log.info("Overwrite pidgin configuration file")  
                file "#{homedir}/.purple/accounts.xml" do
                    content template
                    mode '0755'
                    owner username
                    group gid
                    action :nothing
                    only_if { previous_content != template  }
                end.run_action(:create)

            else
               # Only add/modify this entry
            
               if not XMLUtil.isLoaded()
                   gem_package 'libxml-ruby' do
                       gem_binary($gem_path)
                       action :nothing
                   end.run_action(:install)
               end 

               if XMLUtil.isLoaded()
              
                 template_doc = XMLUtil.parseString(template)
                 accounts_xml_doc =  XMLUtil.parseFile("#{homedir}/.purple/accounts.xml")
                 if not accounts_xml_doc or not accounts_xml_doc.root
                     Chef::Log.error("Bad XML in accounts.xml")  
                 end

                 if not template_doc or not template_doc.root
                     Chef::Log.error("Bad XML in pidgin template")  
                 end

                 template_doc.root.each_element do |node|
                    case node.name
                    when 'account'
                        accountName = 'UNKNOWN'
                        node.each_element  do |elm|
                            case elm.name
                            when 'name'
                                accountName = elm.content
                            end # case
                        end # each element

                        if accountName == 'UNKNOWN'
                            Chef::Log.error("No account name in template") 
                            next
                        end

                       Chef::Log.info("Check if #{accountName} account exists in accounts_xml") 
                       exists = false
                       accounts_xml_doc.root.each_element do |node2|
                          case node2.name
                          when 'account'
                              accName = 'UNKNOWN'
                              node2.each_element  do |elm|
                                  case elm.name
                                      when 'name'
                                     accName = elm.content
                                  end # case
                              end # each element

                              if accName == 'UNKNOWN'
                                 Chef::Log.error("No account name in accounts.xml") 
                                 next
                              end

                              if accName == accountName
                                  # An account with this name already exists --> Overwrite it
                                  Chef::Log.info("Overwrite #{accountName} account") 
                                  exists = true
                                  XMLUtil.replaceContent(accounts_xml_doc, node2, node)

                                  break
                              end # accName == accountName

                          else
                              Chef::Log.error("Strange node in template: #{node.name}")   
                          end # case
                       end # each_element

                       if not exists
                           # An account with this name does not exists --> Append it
                           Chef::Log.info("Append #{accountName} account") 
                           accounts_xml_doc = XMLUtil.appendNode(accounts_xml_doc, node)

                       end # not exists

                    else
                       Chef::Log.error("Strange node in template: #{node.name}")   

                    end # case
                 end # each_element

                 XMLUtil.saveFile(accounts_xml_doc, "#{homedir}/.purple/accounts.xml")
               end #XMLUtil.isLoaded()
               
            end # if user.base.overwrite


	  end # if previous_hash != current_hash

          file "#{homedir}/.purple/digest" do
            content current_hash
            mode '0700'
            owner username
            group gid
            action :nothing
            only_if { ::File.exist?("#{homedir}/.purple") and previous_hash != current_hash and XMLUtil.isLoaded() }
          end.run_action(:create)  
           
           
	end # if user.base.im_setup
        
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
    Chef::Log.error(e.backtrace)

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
    
    gecos_ws_mgmt_jobids "im_client_res" do
       recipe "users_mgmt"
    end.run_action(:reset)
    
  end
end
