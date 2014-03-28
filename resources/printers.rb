#
# Cookbook Name:: gecos-ws-mgmt
# Resource:: printers
#
# Copyright 2013, Junta de Andalucia
# http://www.juntadeandalucia.es/
#
# All rights reserved - EUPL License V 1.1
# http://www.osor.eu/eupl
#

actions :setup

attribute :name, :kind_of => String
attribute :manufacturer, :kind_of => String
attribute :model, :kind_of => String
attribute :uri, :kind_of => String
attribute :shared, :kind_of => [TrueClass, FalseClass]
attribute :ppd, :kind_of => String
attribute :ppd_uri, :kind_of => String
attribute :users_allowed, :kind_of => Array
attribute :groups_allowed, :kind_of => Array
