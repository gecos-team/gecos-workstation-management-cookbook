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
    repo_list = new_resource.repo_list
    repo_list.each do |repo|
      puts repo
      apt_repository repo.repo_name do
        uri repo.uri
        distribution repo.distribution
        components repo.components
        action repo.actiontorun
        key repo.repo_key
        keyserver repo.key_server
        deb_src repo.deb_src 
      end
    end

    # TODO:
    # save current job ids (new_resource.jobs_id) as "ok"
         
  rescue
    # TODO:
    # just save current job ids as "failed"
    # save_failed_job_ids
    raise
  end
end

