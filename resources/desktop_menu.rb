#
# Cookbook Name:: gecos-ws-mgmt
# Resource:: desktop_menu
#
# Copyright 2013, Junta de Andalucia
# http://www.juntadeandalucia.es/
#
# All rights reserved - EUPL License V 1.1
# http://www.osor.eu/eupl
#

gem_depends = [ 'xdg' ]
gem_depends.each do |gem|
  r = gem_package gem do
    gem_binary("/opt/chef/embedded/bin/gem")
    action :nothing
   end
   r.run_action(:install)
end
Gem.clear_paths

actions :setup

attribute :users, :kind_of => Array
attribute :job_ids, :kind_of => Array