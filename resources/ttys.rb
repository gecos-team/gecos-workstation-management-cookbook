#
# Cookbook Name:: gecos-ws-mgmt
# Resource:: ttys
#
# Copyright 2013, Junta de Andalucia
# http://www.juntadeandalucia.es/
#
# All rights reserved - EUPL License V 1.1
# http://www.osor.eu/eupl
#

actions :setup

attribute :disable_ttys, kind_of: [TrueClass, FalseClass]
attribute :job_ids, kind_of: Array
attribute :support_os, kind_of: Array
