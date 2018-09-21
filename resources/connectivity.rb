#
# Cookbook Name:: gecos-ws-mgmt
# Resource:: connectivity
#
# Copyright 2013, Junta de Andalucia
# http://www.juntadeandalucia.es/
#
# All rights reserved - EUPL License V 1.1
# http://www.osor.eu/eupl
#

actions :test, :backup, :recovery

attribute :target, kind_of: String
attribute :port, kind_of: Integer
