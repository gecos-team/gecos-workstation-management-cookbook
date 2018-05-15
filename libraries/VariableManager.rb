class VariableManager
	# Add username variables to environ
	# Params:
	# +username+:: Username
	def self.add_to_environ(username)
	  # Add username variables to environ
	  $gecos_environ['user'.to_sym] = username.gsub('###','.')

	  if $node.normal.key?('gecos_info') and $node.normal['gecos_info'].key?('users') and $node.normal['gecos_info']['users'].key?(username)

	    if $node.normal['gecos_info']['users'][username].key?('email')
	      email = $node.normal['gecos_info']['users'][username]['email']
	      $gecos_environ['email'.to_sym] = email
	      $gecos_environ['emailUser'.to_sym] = email.split('@')[0]
	      $gecos_environ['emailDomain'.to_sym] = email.split('@')[1]
	    end

	    if $node.normal['gecos_info']['users'][username].key?('firstName')
	      $gecos_environ['firstName'.to_sym] = $node.normal['gecos_info']['users'][username]['firstName']
	    end

	    if $node.normal['gecos_info']['users'][username].key?('lastName')
	      $gecos_environ['lastName'.to_sym] = $node.normal['gecos_info']['users'][username]['lastName']
	    end

	  end


	end

	# Expand variables in string
	# Params:
	# +str+:: String
	def self.expand_variables(str)
	  
	  begin
	    str = str%($gecos_environ)
	  rescue KeyError => e
	    Chef::Log.error("Error expanding variables: "+ e.message)
	  end

	  return str
	end
end
