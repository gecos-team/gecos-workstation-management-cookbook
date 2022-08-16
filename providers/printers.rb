#
# Cookbook Name:: gecos-ws-mgmt
# Provider:: printers
#
# Copyright 2013, Junta de Andalucia
# http://www.juntadeandalucia.es/
#
# All rights reserved - EUPL License V 1.1
# http://www.osor.eu/eupl
#

#
# Get printer driver name from PPD file
#
def get_printer_driver(prt_model, prt_id)
  temp = `foomatic-ppdfile -P '#{prt_model}'|grep -i "Id='#{prt_id}'"`
  comp = temp.scan(/CompatibleDrivers='(.*)'/)
  driv = temp.scan(/Driver='(\S+)*'/)

  printer_drv = if !comp.empty? && comp[0].is_a?(Array) && !comp[0].empty?
                  comp[0][0]
                else
                  driv[0][0]
                end

  printer_drv
end

#
# Create a PPD file inside /usr/share/cups/model/ directory
#
def create_ppd(prt_name, prt_model, prt_id)
  Chef::Log.info("Creating PPD file for #{prt_name}... ")

  # foomatic needs all compatible drivers (CompatibleDrivers) for one printer
  # in order to create the PPD file. But sometimes, there's only one driver
  # available (Driver).
  printer_drv = get_printer_driver(prt_model, prt_id)

  ppd_file = `foomatic-ppdfile -p #{prt_id} -d #{printer_drv}`
  ppd_f = ::File.open("/usr/share/cups/model/#{prt_name}.ppd", 'w')
  ppd_f.write(ppd_file)
  ppd_f.close
end

#
# Set printer PPD file URI.
#
def set_printer_options(prt_name, prt_ppd_uri)
  lpopt_comm = ShellUtil.shell("/usr/bin/lpoptions -p #{prt_name} -o "\
      "managed-by-GCC=true -o external-ppd-uri=#{prt_ppd_uri}")
  if lpopt_comm.exitstatus.zero?
    Chef::Log.info(' - installed successfully')
  else
    Chef::Log.info(' - error setting policies to '\
        "#{prt_name}: #{lpopt_comm.stderr}")
  end
end

#
# Installs or updates a printer.
#
def install_or_update_printer(prt_name, prt_uri, prt_policy, prt_ppd_uri)
  Chef::Log.info("Installing or updating printer #{prt_name}... ")
  lpadm_comm = ShellUtil.shell("/usr/sbin/lpadmin  -p #{prt_name} -E "\
      "-m #{prt_name}.ppd -v #{prt_uri} -o printer-op-policy=#{prt_policy}"\
      ' -o auth-info-required=negotiate')
  if lpadm_comm.exitstatus.zero?
    set_printer_options(prt_name, prt_ppd_uri)
  else
    Chef::Log.info(' - error creating printer '\
        "#{prt_name}: #{lpadm_comm.stderr}")
  end
end

#
# Delete a printer
#
def delete_printer(prt_name)
  Chef::Log.info("Deleting printer #{prt_name}... ")
  lpadm_dele = ShellUtil.shell("/usr/sbin/lpadmin -x #{prt_name}")
  ppd_dele = ShellUtil.shell("rm /usr/share/cups/model/#{prt_name}.ppd")
  if lpadm_dele.exitstatus.zero? && ppd_dele.exitstatus.zero?
    Chef::Log.info(' - deleted successfully')
  else
    Chef::Log.info(" - error deleting #{prt_name}: #{lpadm_dele.stderr}")
  end
end

#
# Set permissions to PPD
#
def setup_permissions_to_ppd_file(curr_ptr_name)
  file "/usr/share/cups/model/#{curr_ptr_name}.ppd" do
    mode '0644'
    owner 'root'
    group 'root'
  end
end

#
# Download a PPD file
#
def download_ppd_file(ppd_uri, curr_ptr_name)
  FileUtils.mkdir_p('/usr/share/cups/model')
  ppd_uri_dw = ShellUtil.shell('/usr/bin/wget --no-check-certificate -O'\
      " /usr/share/cups/model/#{curr_ptr_name}.ppd '#{ppd_uri}'")
  if ppd_uri_dw.exitstatus.zero?
    setup_permissions_to_ppd_file(curr_ptr_name)
    return true
  else
    Chef::Log.info(" - failed to obtain PPD using #{ppd_uri}")
    return false
  end
end

action :setup do
  begin
    if os_supported? &&
       (policy_active?('printers_mgmt', 'printers_res') || \
        policy_autoreversible?('printers_mgmt', 'printers_res'))
      printers_list = new_resource.printers_list
      cups_ad_fix_needed = 'GECOS V3, GECOS V2, GECOS V3 Lite, Gecos V2 Lite'

      if printers_list.any?
        service 'cups' do
          action :nothing
        end.run_action(:restart)

        $required_pkgs['printers'].each do |pkg|
          Chef::Log.debug("printers.rb - REQUIRED PACKAGE = #{pkg}")
          package "printers_#{pkg}" do
            package_name pkg
            action :nothing
          end.run_action(:install)
        end

        printers_list.each do |printer|
          Chef::Log.info("Processing printer: #{printer.name}")

          if printer.model.casecmp('Other').zero? &&
             !printer.attribute?('ppd_uri')
            Chef::Log.warn("Model \"#{printer.model}\" without external PPD "\
              " for printer \"#{printer.name}\"")
            next
          end

          curr_ptr_name  = printer.name.tr(' ', '+')
          curr_ptr_id    = printer.manufacturer.tr(' ', '_').tr('/', '_') +
                           '-' + printer.model.tr(' ', '_').tr('/', '_')

          oppolicy = 'default'
          oppolicy = printer.oppolicy if printer.attribute?('oppolicy')
          # GECOS V4 and later (I guess) include the fix we provided by
          # "cups_ad_fix" package, but the name of the operation policy
          # is 'kerberos' while cups_ad_fix used the name 'kerberos-ad'
          if oppolicy == 'kerberos-ad' &&
             !cups_ad_fix_needed.include?($gecos_os)
            oppolicy = 'kerberos'
          end

          inst_prt_uri = `lpoptions -p #{curr_ptr_name}`
          inst_prt_uri = inst_prt_uri.scan(/^.*\sdevice-uri=(\S+)\s.*$/)
          inst_prt_uri = [[]] if inst_prt_uri.empty?

          is_prt_in_cups = ShellUtil.shell("lpstat -p #{curr_ptr_name}")
          is_prt_installed = is_prt_in_cups.exitstatus.zero?

          create_ppd_with_ppd_uri = false
          if printer.attribute?('ppd_uri') &&
             !::File.exist?("/usr/share/cups/model/#{curr_ptr_name}.ppd")
            Chef::Log.info(" - using PPD_URI: #{printer.ppd_uri}")
            download_ppd_file(printer.ppd_uri, curr_ptr_name)
            create_ppd_with_ppd_uri = true
          else
            ppd_uri = ''
          end

          if !create_ppd_with_ppd_uri &&
             (!is_prt_installed || !(inst_prt_uri[0][0].eql? printer.uri))
            create_ppd(curr_ptr_name, printer.model, curr_ptr_id)
          end

          install_or_update_printer(
            curr_ptr_name, printer.uri, oppolicy, ppd_uri
          )

          cups_ptr_list = ShellUtil.shell('lpstat -a | egrep \'^\\S\' |'\
              ' awk \'{print $1}\'')
          cups_list = cups_ptr_list.stdout.split(/\r?\n/)

          cups_list.each do |cups_printer|
            ptr_found = false
            printers_list.each do |prntr|
              if cups_printer.eql? prntr.name.tr(' ', '+')
                ptr_found = true
                break
              end
            end

            next if ptr_found

            lpoptions = `/usr/bin/lpoptions -p #{cups_printer}`
            Chef::Log.info(" lpoptions: #{lpoptions}")
            if lpoptions.include? 'managed-by-GCC=true'
              delete_printer(cups_printer)
            end
          end
        end
      else
        cups_ptr_list = ShellUtil.shell('lpstat -a | egrep \'^\\S\' |'\
            ' awk \'{print $1}\'')
        cups_list = cups_ptr_list.stdout.split(/\r?\n/)
        cups_list.each do |cups_printer|
          lpopt = `/usr/bin/lpoptions -p #{cups_printer}`

          delete_printer(cups_printer) if lpopt.include? 'managed-by-GCC=true'
        end
      end
    end

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
    gecos_ws_mgmt_jobids 'printers_res' do
      recipe 'printers_mgmt'
    end.run_action(:reset)
  end
end
