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

action :setup do
  begin
    printers_list = new_resource.printers_list

    if printers_list.any?

      service "cups" do
        action :restart
      end

      package 'python-cups' 
      package 'cups-driver-gutenprint' 
      package 'foomatic-db' 
      package 'foomatic-db-engine' 
      package 'foomatic-db-gutenprint'
 
      printers_list.each do |printer|
        Chef::Log.info("Instalando impresora #{printer.name}")
  
        name = printer.name
        make = printer.manufacturer
        model = printer.model
        ppd = printer.ppd
        uri = printer.uri
        ppd_uri = printer.ppd_uri

        if ppd_uri != '' and ppd != ''
          FileUtils.mkdir_p("/usr/share/ppd/#{make}/#{model}")    
          remote_file "/usr/share/ppd/#{make}/#{model}/#{ppd}" do
            source ppd_uri
            mode "0644"
          end
        end

        script "install_printer" do
          interpreter "python"
          user "root"
          code <<-EOH
import cups
connection=cups.Connection()
drivers = connection.getPPDs(ppd_make_and_model='#{make} #{model}')
ppd = '#{ppd}'
if ppd != '':
    for key in drivers.keys():
        if key.startswith('lsb/usr') and key.endswith('#{model}/'+ppd):
            ppd = key

if ppd == '':
    ppd = drivers.keys()[0]

connection.addPrinter('#{name}',ppdname=ppd, device='#{uri}')
connection.enablePrinter('#{name}')
connection.acceptJobs('#{name}')

    EOH
         end

      end
    end
    # TODO:
    # save current job ids (new_resource.job_ids) as "ok"

  rescue
    # TODO:
    # just save current job ids as "failed"
    # save_failed_job_ids
    raise
  end
end

