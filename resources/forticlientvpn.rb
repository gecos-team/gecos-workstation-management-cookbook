#
# Cookbook Name:: gecos-ws-mgmt
# Resource:: forticlientvpn
#
# Copyright 2013, Junta de Andalucia
# http://www.juntadeandalucia.es/
#
# All rights reserved - EUPL License V 1.1
# http://www.osor.eu/eupl
#

actions :setup
default_action :setup

attribute :proxyserver, :kind_of => String
attribute :proxyport, :kind_of => String
attribute :proxyuser, :kind_of => String
attribute :keepalive, :kind_of => Integer
attribute :autostart, :kind_of => Integer
attribute :connections, :kind_of => Hash
attribute :job_ids, :kind_of => Array
attribute :support_os, :kind_of => Array
