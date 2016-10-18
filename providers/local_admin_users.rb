#
# Cookbook Name:: gecos-ws-mgmt
# Provider:: local_admin_users
#
# Copyright 2013, Junta de Andalucia
# http://www.juntadeandalucia.es/
#
# All rights reserved - EUPL License V 1.1
# http://www.osor.eu/eupl
#

action :setup do
  begin
# OS identification moved to recipes/default.rb
#    os = `lsb_release -d`.split(":")[1].chomp().lstrip()
#    if new_resource.support_os.include?(os)
    if new_resource.support_os.include?($gecos_os)

      local_admin_list = new_resource.local_admin_list
      local_admin_remove_list = new_resource.local_admin_remove_list
      if !local_admin_list.empty?
  	group "sudo" do
          members local_admin_list
  	  append true
          action :nothing
  	end.run_action(:modify)
      end
      if !local_admin_remove_list.empty?
  	group "sudo" do
          excluded_members local_admin_remove_list
  	  append true
          action :nothing
  	end.run_action(:modify)
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
    
    resource = gecos_ws_mgmt_jobids "local_admin_users_res" do
       recipe "misc_mgmt"
    end
    resource.provider = Chef::ProviderResolver.new(node, resource , :reset).resolve
    resource.run_action(:reset)    
    
  end
end
