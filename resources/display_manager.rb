#
# Cookbook Name:: gecos-ws-mgmt
# Resource:: display_manager
#
# Copyright 2013, Junta de Andalucia
# http://www.juntadeandalucia.es/
#
# All rights reserved - EUPL License V 1.1
# http://www.osor.eu/eupl
#

actions :setup

attribute :dm, kind_of: String
attribute :session_script, kind_of: String
attribute :autologin, kind_of: [TrueClass, FalseClass], default: false
attribute :autologin_options, kind_of: Hash
attribute :job_ids, kind_of: Array
attribute :support_os, kind_of: Array
