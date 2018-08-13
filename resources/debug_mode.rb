#
# Cookbook Name:: gecos-ws-mgmt
# Resource:: debug_mode
#
# Copyright 2018, Junta de Andalucia
# http://www.juntadeandalucia.es/
#
# All rights reserved - EUPL License V 1.1
# http://www.osor.eu/eupl
#

actions :setup

attribute :expire_datetime, :kind_of => String
attribute :enable_debug, :kind_of => [TrueClass, FalseClass], :required => false
attribute :job_ids, :kind_of => Array
attribute :support_os, :kind_of => Array
