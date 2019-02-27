#
# Cookbook Name:: gecos-ws-mgmt
# Provider:: package
#
# Copyright 2013, Junta de Andalucia
# http://www.juntadeandalucia.es/
#
# All rights reserved - EUPL License V 1.1
# http://www.osor.eu/eupl
#

def pin_package_version(pkg_name, pkg_version)
  file '/etc/apt/preferences.d/' + pkg_name + '.pref' do
    content "Package: #{pkg_name}\nPin: "\
      "version #{pkg_version}\nPin-Priority: 1000\n"
    mode '0644'
    owner 'root'
    group 'root'
    action :create
  end
end

def remove_package_pinning(pkg_name)
  file '/etc/apt/preferences.d/' + pkg_name + '.pref' do
    action(:delete)
  end
end

def add_package_current_ver(pkg)
  # Remove the version pinning of this package (if exists)
  remove_package_pinning(pkg.name)

  # Install the current version of the package
  # or ensure that any version of this package is installed
  package pkg.name do
    action :install
  end
end

def add_package_latest_ver(pkg)
  # Remove the version pinning of this package (if exists)
  remove_package_pinning(pkg.name)

  # Install a package and/or ensure that a package is the
  # latest version.
  package pkg.name do
    action :upgrade
  end
end

def add_package_certain_ver(pkg)
  # Install a certain version of the package
  package pkg.name do
    version pkg.version
    # Added to support package downgrade
    options '--force-yes'
    action :install
  end

  # Ping this version to prevent updates
  pin_package_version(pkg.name, pkg.version)
end

def add_package(pkg)
  # Check the version parameter
  case pkg.version
  when 'current'
    add_package_current_ver(pkg)
  when 'latest'
    add_package_latest_ver(pkg)
  else
    add_package_certain_ver(pkg)
  end
end

action :setup do
  begin
    if !is_supported?
      Chef::Log.info('This resource is not supported in your OS')
    elsif has_applied_policy?('software_mgmt','package_res') || \
          is_autoreversible?('software_mgmt','package_res')
      if new_resource.package_list.any?
        Chef::Log.info('Installing package list')
        new_resource.package_list.each do |pkg|
          Chef::Log.debug("Package: #{pkg}")
          case pkg.action
          when 'add'
            # Add a package

            # Execute apt-get update every 24 hours
            execute 'apt-get-update-periodic' do
              command 'apt-get update'
              ignore_failure true
              only_if do
                ::File.exist?('/var/lib/apt/periodic/update-success-stamp') &&
                  ::File.mtime('/var/lib/apt/periodic/update-success-stamp') <
                    Time.now - 86_400
              end
            end

            add_package(pkg)

          when 'remove'
            # Remove a package
            package pkg.name do
              action :purge
            end

            # Remove the version pinning of this package (if exists)
            file '/etc/apt/preferences.d/' + pkg.name + '.pref' do
              action(:delete)
            end
          else
            raise "Action for package #{pkg.name}=#{pkg.version} is not"\
              " add nor remove (#{pkg.action})"
          end
        end
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
    gecos_ws_mgmt_jobids 'package_res' do
      recipe 'software_mgmt'
    end.run_action(:reset)
  end
end
