#
# Cookbook Name:: gecos-ws-mgmt
# Class VariableManager
#
# Copyright 2018, Junta de Andalucia
# http://www.juntadeandalucia.es/
#
# All rights reserved - EUPL License V 1.1
# http://www.osor.eu/eupl
#

# Class used to add variables to environ.
# After that those variables are used in variable expansion
class VariableManager
  # Add user email variables to environ
  # Params:
  # +username+:: Username
  def self.add_user_email_to_environ(username)
    userdata = $node.normal['gecos_info']['users'][username]
    return unless userdata.key?('email')
    email = userdata['email']
    $gecos_environ['EMAIL'.to_sym] = email
    $gecos_environ['EMAILUSER'.to_sym] = email.split('@')[0]
    $gecos_environ['EMAILDOMAIN'.to_sym] = email.split('@')[1]
  end

  # Add user first name variable to environ
  # Params:
  # +username+:: Username
  def self.add_user_firstname_to_environ(username)
    userdata = $node.normal['gecos_info']['users'][username]
    return unless userdata.key?('firstName')
    $gecos_environ['FIRSTNAME'.to_sym] = userdata['firstName']
  end

  # Add user last name variable to environ
  # Params:
  # +username+:: Username
  def self.add_user_lastname_to_environ(username)
    userdata = $node.normal['gecos_info']['users'][username]
    return unless userdata.key?('lastName')
    $gecos_environ['LASTNAME'.to_sym] = userdata['lastName']
  end

  # Add user variables to environ
  # Params:
  # +username+:: Username
  def self.add_to_environ(username)
    # Add username variables to environ
    $gecos_environ['USER'.to_sym] = username.gsub('###', '.')
    if $node.normal.key?('gecos_info') &&
       $node.normal['gecos_info'].key?('users') &&
       $node.normal['gecos_info']['users'].key?(username)

      add_user_email_to_environ(username)
      add_user_firstname_to_environ(username)
      add_user_lastname_to_environ(username)
    end
  end

  # Add variables to environ
  # Params:
  # +key+:: Key
  # +value+:: Value
  def self.add_key_to_environ(key, value)
    $gecos_environ[key.to_sym] = value
  end

  # Reset known environ variables
  def self.reset_environ
    $gecos_environ['USER'.to_sym] = 'UNKNOWN'
    $gecos_environ['EMAIL'.to_sym] = 'UNKNOWN'
    $gecos_environ['EMAILUSER'.to_sym] = 'UNKNOWN'
    $gecos_environ['EMAILDOMAIN'.to_sym] = 'UNKNOWN'
    $gecos_environ['FIRSTNAME'.to_sym] = 'UNKNOWN'
    $gecos_environ['LASTNAME'.to_sym] =  'UNKNOWN'
  end

  # Normalize variable names in string
  # Params:
  # +str+:: String
  # Returns:
  # String with normalized variable names
  def self.normalize_variables(str)
    # Replace %variable_name% by %{VARIABLE_NAME}
    str.scan(/%([A-Za-z0-9_]+)%/).each do |v|
      v = v[0]
      # To upper case
      vupper = v.upcase
      # Replacement
      str = str.gsub("%#{v}%", "%{#{vupper}}")
    end

    str
  end

  # Expand variables in string
  # Params:
  # +str+:: String
  # Returns:
  # String with expanded variables or nil in case of error.
  def self.expand_variables(str)
    ret = nil
    begin
      str = normalize_variables(str)

      # Replace % by %% to avoid "malformed format string" errors
      # but keeping %{VARIABLE_NAME} markers
      str = str.gsub(/%([^{])/, '%%\1')

      # Replace %{VARIABLE_NAME} by its value
      ret = str % $gecos_environ
    rescue KeyError => e
      Chef::Log.error('Error expanding variables: ' + e.message)
      Chef::Log.error('String was: ' + str)
    end

    ret
  end

  private_class_method :add_user_email_to_environ
  private_class_method :add_user_firstname_to_environ
  private_class_method :add_user_lastname_to_environ
  private_class_method :normalize_variables
end
