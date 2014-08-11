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
  	os = `lsb_release -d`.split(":")[1].chomp().lstrip()
    if new_resource.support_os.include?(os)
      printers_list = new_resource.printers_list
    else
      Chef::Log.info("This resource are not support into your OS")
    end
#    printers_list.each do |printer|
#      Chef::Log.info("Instalando impresora #{printer.name}")
#    end
#    # TODO:
#    # save current job ids (new_resource.job_ids) as "ok"
#
  rescue
#    # TODO:
#    # just save current job ids as "failed"
#    # save_failed_job_ids
    raise
  end
end

