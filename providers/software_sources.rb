#
# Cookbook Name:: gecos-ws-mgmt
# Provider:: software_sources
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
      repo_list = new_resource.repo_list
      
      current_lists = []
      remote_lists = []    
      remote_lists.push("gecosv2.list")

      Dir.foreach('/etc/apt/sources.list.d') do |item|
        next if item == '.' or item == '..'
        current_lists.push(item)
      end

      if repo_list.any?
        repo_list.each do |repo|
          remote_lists.push("#{repo.repo_name}.list")        
          apt_repository repo.repo_name do
            uri repo.uri
            distribution repo.distribution
            components repo.components
            action :nothing
            key repo.repo_key
            keyserver repo.key_server
            deb_src repo.deb_src 
          end.run_action(:add)
        end
      end

      files_to_remove = current_lists - remote_lists
      files_to_remove.each do |value|
        ::File.delete("/etc/apt/sources.list.d/#{value}")
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

    resource = gecos_ws_mgmt_jobids "software_sources_res" do
       recipe "software_mgmt"
    end
    resource.provider = Chef::ProviderResolver.new(node, resource , :reset).resolve
    resource.run_action(:reset)
    
  end
end

