#
# Cookbook Name:: gecos-ws-mgmt
# Resource:: remote_control
#
# Copyright 2018, Junta de Andalucia
# http://www.juntadeandalucia.es/
#
# All rights reserved - EUPL License V 1.1
# http://www.osor.eu/eupl
#

actions :setup

attribute :enable_helpchannel, kind_of: [TrueClass, FalseClass], required: false
attribute :enable_ssh, kind_of: [TrueClass, FalseClass], required: false
attribute :tunnel_url, kind_of: String
attribute :ssl_verify, kind_of: [TrueClass, FalseClass], required: false
attribute :job_ids, kind_of: Array
attribute :support_os, kind_of: Array
