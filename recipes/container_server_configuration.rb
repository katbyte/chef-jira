settings = Jira.settings(node)

template "#{node['jira']['install_path']}/bin/permgen.sh" do
  source 'tomcat/permgen.sh.erb'
  owner node['jira']['user']
  mode '0755'
  notifies :restart, 'service[jira]', :delayed
end

template "#{node['jira']['install_path']}/bin/setenv.sh" do
  source 'tomcat/setenv.sh.erb'
  owner node['jira']['user']
  mode '0755'
  notifies :restart, 'service[jira]', :delayed
end


template "#{node['jira']['install_path']}/conf/server.xml" do
  source 'tomcat/server.xml.erb'
  owner node['jira']['user']
  mode '0640'
  variables :tomcat => settings['tomcat']
  notifies :restart, 'service[jira]', :delayed
end
