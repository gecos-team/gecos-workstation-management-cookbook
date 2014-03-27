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
    printers_list.each do |printer|
      Chef::Log.info("Instalando impresora #{printer.name}")
      #TODO: a lot of stuff
    end
  rescue 
    raise 
  end 
end
