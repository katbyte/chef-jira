settings = Jira.settings(node)

include_recipe 'jira::database' if settings['database']['host'] == '127.0.0.1'
include_recipe "jira::#{node['jira']['install_type']}"
include_recipe 'jira::autotune' if node['jira']['autotune']['enabled'] == true
include_recipe 'jira::configuration'
include_recipe 'jira::container_server_configuration'
include_recipe 'jira::apache2'
include_recipe 'jira::crowd_sso' if node['jira']['crowd_sso']['enabled'] == true

directory "#{node['jira']['install_path']}/" do
  owner node['jira']['user']
  group 'root'
  recursive true
  mode 00755
  action :create
end
