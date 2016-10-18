action :reset do
  node.normal['gecos_ws_mgmt'][new_resource.recipe][new_resource.resource]['job_ids'] = []
end