class VariableManager
    # Add username variables to environ
    # Params:
    # +username+:: Username
    def self.add_to_environ(username)
      # Add username variables to environ
      $gecos_environ['USER'.to_sym] = username.gsub('###','.')

      if $node.normal.key?('gecos_info') and $node.normal['gecos_info'].key?('users') and $node.normal['gecos_info']['users'].key?(username)

        if $node.normal['gecos_info']['users'][username].key?('email')
          email = $node.normal['gecos_info']['users'][username]['email']
          $gecos_environ['EMAIL'.to_sym] = email
          $gecos_environ['EMAILUSER'.to_sym] = email.split('@')[0]
          $gecos_environ['EMAILDOMAIN'.to_sym] = email.split('@')[1]
        end

        if $node.normal['gecos_info']['users'][username].key?('firstName')
          $gecos_environ['FIRSTNAME'.to_sym] = $node.normal['gecos_info']['users'][username]['firstName']
        end

        if $node.normal['gecos_info']['users'][username].key?('lastName')
          $gecos_environ['LASTNAME'.to_sym] = $node.normal['gecos_info']['users'][username]['lastName']
        end

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
    def self.reset_environ()
      $gecos_environ['USER'.to_sym] = 'UNKNOWN'
      $gecos_environ['EMAIL'.to_sym] = 'UNKNOWN'
      $gecos_environ['EMAILUSER'.to_sym] = 'UNKNOWN'
      $gecos_environ['EMAILDOMAIN'.to_sym] =  'UNKNOWN'
      $gecos_environ['FIRSTNAME'.to_sym] = 'UNKNOWN'
      $gecos_environ['LASTNAME'.to_sym] =  'UNKNOWN'

    end  
  

  
    # Expand variables in string
    # Params:
    # +str+:: String
    # Returns:
    # String with expanded variables or nil in case of error.
    def self.expand_variables(str)
      ret = nil
      begin
        # Replace %variable_name% by %{VARIABLE_NAME}
        variables = str.scan(/%([A-Za-z0-9_]+)%/)
        for v in variables
            v= v[0]
            # To upper case
        vupper = v.upcase
                # Replacement
        str = str.gsub("%#{v}%", "%{#{vupper}}")
        end

            # Replace % by %% to avoid "malformed format string" errors 
            # but keeping %{VARIABLE_NAME} markers
            str = str.gsub(/%([^{])/, '%%\1')

        # Replace %{VARIABLE_NAME} by its value
        ret = str%($gecos_environ)
      rescue KeyError => e
        Chef::Log.error("Error expanding variables: "+ e.message)
        Chef::Log.error("String was: "+str)
      end

      return ret
    end
end
