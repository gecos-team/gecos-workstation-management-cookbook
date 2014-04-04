#
# Cookbook Name:: gecos-ws-mgmt
# Resource:: user_apps_autostart
#
# Copyright 2013, Junta de Andalucia
# http://www.juntadeandalucia.es/
#
# All rights reserved - EUPL License V 1.1
# http://www.osor.eu/eupl
#

actions :setup

attribute :users, :kind_of => Array
attribute :jobs_id, :kind_of => Array
