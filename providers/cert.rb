#
# Cookbook Name:: gecos_ws_mgmt
# Provider:: cert
#
# Copyright 2013, Junta de Andalucia
# http://www.juntadeandalucia.es/
#
# All rights reserved - EUPL License V 1.1
# http://www.osor.eu/eupl

action :setup do
  begin
    if new_resource.support_os.include?($gecos_os)
      # install depends
      $required_pkgs['cert'].each do |pkg|
        Chef::Log.debug("cert.rb - REQUIRED PACKAGE = #{pkg}")
        package pkg do
          action :nothing
        end.run_action(:install)
      end

      require 'fileutils'

      res_ca_root_certs = new_resource.ca_root_certs ||
                          node[:gecos_ws_mgmt][:misc_mgmt][:cert_res][
                            :ca_root_certs]

      # When java is only used for runnig apps from the web, there's no need
      # for loading CA root certificates directly in Java;
      # browser keystores are used instead.
      # import gecos custom certs into every mozilla profile
      certs_path = '/usr/share/ca-certificates/gecos/'
      directory certs_path do
        owner 'root'
        group 'root'
        mode '0755'
        action :nothing
      end.run_action(:create)

      # TODO: improve poor performance of idempotenly execute this
      # A bit better: ohai-certs stores installed certs and permisions in node,
      # and it is looked up before installing, avoiding useless reinstalls
      # TODO: Allow permisions to be set by a GECOS administrator
      res_ca_root_certs.each do |cert|
        cert_file = certs_path + cert[:name].tr(' ', '_')
        remote_file cert_file do
          source cert[:uri]
        end
        Dir['/home/*/.mozilla/firefox/*default'].each do |profile|
          begin
            ffox_certs = node.ohai_gecos.ffox_certs
            if ffox_certs.key?(profile.to_s) &&
               ffox_certss[profile.to_s].key?(cert[:name].to_s) &&
               ffox_certs[profile.to_s][cert[:name].to_s] == 'CT,C,C'
            else
              execute "install root cert #{cert[:name]} for profile "\
                "'#{profile}'" do
                command "certutil -A -n '#{cert[:name]}' -t 'CT,C,C' -i "\
                    "'#{cert_file}' -d '#{profile}' &>/dev/null"
                action :nothing
              end.run_action(:run)
            end
          rescue StandardError
            next
          end
        end
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
    gecos_ws_mgmt_jobids 'cert_res' do
      recipe 'misc_mgmt'
    end.run_action(:reset)
  end
end
