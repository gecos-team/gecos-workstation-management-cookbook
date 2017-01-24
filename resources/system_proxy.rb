#
# Cookbook Name:: gecos-ws-mgmt
# Resource:: sytem_proxy
#
# Copyright 2015, Junta de Andalucia
# http://www.juntadeandalucia.es/
#
# All rights reserved - EUPL License V 1.1
# http://www.osor.eu/eupl


actions :presetup, :setup, :warn

attribute :force, :kind_of => [TrueClass, FalseClass], :default => false
attribute :global_config, :kind_of => Object
attribute :mozilla_config, :kind_of => Object
attribute :job_ids, :kind_of => Array
attribute :support_os, :kind_of => Array

