#
# Cookbook Name:: gecos-ws-mgmt
# Resource:: cert
#
# Copyright 2013, Junta de Andalucia
# http://www.juntadeandalucia.es/
#
# All rights reserved - EUPL License V 1.1
# http://www.osor.eu/eupl
#

actions :setup
default_action :setup

attribute :ca_root_certs, kind_of: Array
attribute :java_keystores, kind_of: Array
attribute :job_ids, kind_of: Array
attribute :support_os, kind_of: Array
