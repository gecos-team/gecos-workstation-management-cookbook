#
# Cookbook Name:: gecos-ws-mgmt
# Recipe:: default
#
# Copyright 2013, Junta de Andalucia
# http://www.juntadeandalucia.es/
#
# All rights reserved - EUPL License V 1.1
# http://www.osor.eu/eupl
#

include_recipe "gecos-ws-mgmt::software_mgmt"
include_recipe "gecos-ws-mgmt::misc_mgmt"
include_recipe "gecos-ws-mgmt::network_mgmt"
include_recipe "gecos-ws-mgmt::users_mgmt"
