#
# Cookbook Name:: gecos-ws-mgmt
# Class XMLUtil
#
# NOTE: this class depends on libxml
#
# Copyright 2018, Junta de Andalucia
# http://www.juntadeandalucia.es/
#
# All rights reserved - EUPL License V 1.1
# http://www.osor.eu/eupl
#

begin
  require 'libxml'

  # Utility class used to work with XML files
  class XMLUtil
    # Return true if the libxml library is loaded
    def self.loaded?
      true
    end

    # Parse a XML string
    def self.parse_string(str)
      include LibXML
      XML::Document.string(str)
    end

    # Parse a XML file
    def self.parse_file(file)
      include LibXML
      XML::Document.file(file)
    end

    # Save a XML document to a file
    def self.save_file(document, file)
      include LibXML
      document.save(file, indent: true, encoding: XML::Encoding::UTF_8)
    end

    # Replace content in a XML document
    def self.replace_content(document, dst, src)
      include LibXML

      # Remove all elements from destination node
      dst.each_element(&:remove!)

      # Copy all elements from source to destination
      src.each_element do |elm|
        dst << document.import(elm)
      end
    end

    # Appends a node to a XML document
    def self.append_node(document, node)
      include LibXML
      document.root << document.import(node)
      document
    end
  end
rescue LoadError
  Chef::Log.warn('Can not load libxml gem in XMLUtil library. '\
                 'A recipe will install requirements when needed.')

  # Empty stub
  class XMLUtilStub
    # Return true if the libxml library is loaded
    def self.loaded?
      false
    end

    # Parse a XML string
    def self.parse_string(_str)
      nil
    end

    # Parse a XML file
    def self.parse_file(_file)
      nil
    end

    # Save a XML document to a file
    def self.save_file(_document, _file); end

    # Replace content in a XML document
    def self.replace_content(_document, _dst, _src); end

    # Appends a node to a XML document
    def self.append_node(_document, _node)
      nil
    end
  end
  # XMLUtil class definition based on stub
  class XMLUtil < XMLUtilStub
  end
end
