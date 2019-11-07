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

#
# Checks a XML Document and raises an exception with the specified
# message in case of error
#
def check_xml_doc(xml_doc, message)
  raise message if !xml_doc || !xml_doc.root
end

#
# Gets an account name from an account XML node
#
def get_account_name(node)
  account_name = 'UNKNOWN'
  node.each_element do |elm|
    case elm.name
    when 'name'
      account_name = elm.content
    end
  end

  account_name
end

#
# Check an account XML node.
# This method the account name or 'UNKNOWN' in case of error.
#
def check_account_node(node, xml_name)
  if node.name != 'account'
    Chef::Log.error("Strange node in #{xml_name}: #{node.name}")
    return 'UNKNOWN'
  end

  acc_name = get_account_name(node)
  Chef::Log.error("No account name in #{xml_name}") if acc_name == 'UNKNOWN'
  acc_name
end

#
# Modify a XML account node in a XML document
#
def modify_xml_account(accounts_xml_doc, node, account_name)
  # Check if "account_name" account exists in accounts_xml"
  exists = false
  accounts_xml_doc.root.each_element do |node2|
    acc_name = check_account_node(node2, 'accounts.xml')
    next unless acc_name == account_name

    # An account with this name already exists
    # --> Overwrite it
    Chef::Log.info("Overwrite #{account_name} account")
    exists = true
    XMLUtil.replace_content(accounts_xml_doc, node2, node)
    break
  end
  [exists, accounts_xml_doc]
end

#
# Adds or modify a XML node into XML document
#
def add_or_modify_xml_node(node, accounts_xml_doc)
  account_name = check_account_node(node, 'template')
  return accounts_xml_doc if account_name == 'UNKNOWN'

  exists, accounts_xml_doc = modify_xml_account(
    accounts_xml_doc, node, account_name
  )

  unless exists
    # An account with this name does not exists
    # --> Append it
    Chef::Log.info("Append #{account_name} account")
    accounts_xml_doc = XMLUtil.append_node(accounts_xml_doc, node)
  end

  accounts_xml_doc
end

#
# Adds or modify a XML entry into accounts.xml file
#
def add_or_modify_xml_entry(template, homedir)
  template_doc = XMLUtil.parse_string(template)
  accounts_xml_doc = XMLUtil.parse_file("#{homedir}/.purple/accounts.xml")

  check_xml_doc(accounts_xml_doc, 'Bad XML in accounts.xml')

  check_xml_doc(template_doc, 'Bad XML in pidgin template')

  template_doc.root.each_element do |node|
    accounts_xml_doc = add_or_modify_xml_node(node, accounts_xml_doc)
  end

  XMLUtil.save_file(accounts_xml_doc, "#{homedir}/.purple/accounts.xml")
end

action :setup do
  begin
    # Checking OS and Pidgin
    if os_supported? &&
       (policy_active?('users_mgmt', 'im_client_res') ||
        policy_autoreversible?('users_mgmt', 'im_client_res'))
      # Install required packages
      $required_pkgs['im_client'].each do |pkg|
        Chef::Log.debug("im_client.rb - REQUIRED PACKAGES = #{pkg}")
        package "im_client_#{pkg}" do
          package_name pkg
          action :nothing
        end.run_action(:install)
      end

      # Setup email for users
      users = new_resource.users
      users.each_key do |user_key|
        user = users[user_key]
        username = user_key.gsub('###', '.')
        gid = Etc.getpwnam(username).gid

        # Check if the email must be configured
        Chef::Log.info('Check if the instant messaging client'\
          ' must be configured')
        next unless user.base.im_setup

        homedir = `eval echo ~#{username}`.delete("\n")

        # Create purple directory if doesn't exists
        directory "#{homedir}/.purple" do
          owner username
          group gid
          mode '700'
          action :nothing
        end.run_action(:create)

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
          VariableManager.add_key_to_environ('FIRSTNAME', user.identity.name)
        end

        if VariableManager.expand_variables(user.identity.surname)
          VariableManager.add_key_to_environ(
            'LASTNAME',
            VariableManager.expand_variables(user.identity.surname)
          )
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
        data = data_bag_item('pidgin_templates', 'pidgin')

        template = ''
        data['accounts_xml'].each do |line|
          expanded_line = VariableManager.expand_variables(line)
          # Return an error if the expanded_line returns nil
          raise 'Variables expansion error!' unless expanded_line

          template = template + expanded_line + "\n"
        end

        # Check if there are configuration changes by
        # comparing the current template signature and the
        # previous template signature
        current_hash = Digest::SHA256.hexdigest template

        previous_hash = ''
        if ::File.exist?("#{homedir}/.purple/digest")
          previous_hash = ::File.read("#{homedir}/.purple/digest")
        end

        # Skip this element if previous_hash == current_hash
        next unless previous_hash != current_hash || user.base.overwrite

        if user.base.overwrite ||
           !::File.exist?("#{homedir}/.purple/accounts.xml")
          # If overwrite flag is active the accounts.xml must be
          # overwritten if the content of the file is different
          previous_content = ''
          if ::File.exist?("#{homedir}/.purple/accounts.xml")
            previous_content = ::File.read("#{homedir}/.purple/digest")
          end

          # Overwrite the whole file
          Chef::Log.info('Overwrite pidgin configuration file')
          file "#{homedir}/.purple/accounts.xml" do
            content template
            mode '0755'
            owner username
            group gid
            action :nothing
            only_if { previous_content != template }
          end.run_action(:create)
        else
          # Only add/modify this entry

          unless XMLUtil.loaded?
            gem_package 'libxml-ruby' do
              gem_binary($gem_path)
              action :nothing
            end.run_action(:install)
            require 'libxml'
          end

          add_or_modify_xml_entry(template, homedir) if XMLUtil.loaded?
        end

        file "#{homedir}/.purple/digest" do
          content current_hash
          mode '0700'
          owner username
          group gid
          action :nothing
          only_if do
            ::File.exist?("#{homedir}/.purple") &&
              previous_hash != current_hash &&
              XMLUtil.loaded?
          end
        end.run_action(:create)
      end
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
    gecos_ws_mgmt_jobids 'im_client_res' do
      recipe 'users_mgmt'
    end.run_action(:reset)
  end
end
