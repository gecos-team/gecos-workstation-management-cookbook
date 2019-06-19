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
    if os_supported? &&
       (policy_active?('misc_mgmt', 'cert_res') ||
        policy_autoreversible?('misc_mgmt', 'cert_res'))
      # install depends
      $required_pkgs['cert'].each do |pkg|
        Chef::Log.debug("cert.rb - REQUIRED PACKAGE = #{pkg}")
        package "cert_#{pkg}" do
          package_name pkg
          action :nothing
        end.run_action(:install)
      end

      # Install PK11 kit if needeed by overwritting Firefox's
      # libnssckbi.so file. By doing this Firefox will trust
      # system certificates
      libnssckbi = ShellUtil.shell(
        'dpkg -L firefox | grep libnssckbi.so | head -n 1'
      ).stdout.chomp

      p11_kit_trust = ShellUtil.shell(
        'dpkg -L p11-kit-modules | grep p11-kit-trust.so | head -n 1'
      ).stdout.chomp

      if ::File.exist?(libnssckbi) && ::File.exist?(p11_kit_trust) &&
         !::File.symlink?(libnssckbi)
        Chef::Log.info('Divert libnssckbi.so file')
        ShellUtil.shell(
          "dpkg-divert --add --rename --divert #{libnssckbi}.original "\
            "#{libnssckbi}"
        )
        # Create a symbolic link
        ::FileUtils.ln_s p11_kit_trust, libnssckbi
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

      if ::File.exist?('/etc/ca-certificates.conf')
        ca_certificates_file = ::File.readlines('/etc/ca-certificates.conf')

        update = false
        # Download and install certificates
        res_ca_root_certs.each do |cert|
          # Download certificate file
          cert_name = cert[:name].tr(' ', '_') + '.crt'
          cert_file_dst = certs_path + cert_name
          cert_file = certs_path + cert[:name].tr(' ', '_') + '.cer'
          remote_file cert_file do
            source cert[:uri]
            action :nothing
          end.run_action(:create)

          mustupdate = (!::File.exist?(cert_file_dst) ||
            ::File.mtime(cert_file) > ::File.mtime(cert_file_dst))

          execute "convert to PEM #{cert_file}" do
            command "openssl x509 -inform DER -in #{cert_file} > "\
              "#{cert_file_dst}"
            only_if mustupdate
            not_if "file #{cert_file} | grep PEM"
          end

          link cert_file_dst do
            to cert_file
            only_if "file #{cert_file} | grep PEM "
          end

          # Check if the certificate is installed
          next unless ca_certificates_file.grep(
            /#{Regexp.quote('gecos/' + cert_name)}/
          ).empty?

          # Add the certificate file to /etc/ca-certificates.conf
          update = true
          ::File.open('/etc/ca-certificates.conf', 'a') do |file|
            file.puts 'gecos/' + cert_name
          end
        end

        if update
          # Update certificate list
          ShellUtil.shell('update-ca-certificates')
        end
      else
        Chef::Log.error('Can\'t find /etc/ca-certificates.conf file!')
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
    gecos_ws_mgmt_jobids 'cert_res' do
      recipe 'misc_mgmt'
    end.run_action(:reset)
  end
end
