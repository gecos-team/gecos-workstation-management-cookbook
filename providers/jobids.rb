action :reset do
  node.set['gecosws_mgmt'][new_resource.recipe][new_resource.resource]['job_ids'] = []
end