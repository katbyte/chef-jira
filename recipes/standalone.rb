directory File.dirname(node['jira']['home_path']) do
  owner 'root'
  group 'root'
  mode 00755
  action :create
  recursive true
end

user node['jira']['user'] do
  comment 'JIRA Service Account'
  home node['jira']['home_path']
  shell '/bin/bash'
  manage_home true
  system true
  action :create
end

ark 'jira' do
  url jira_artifact_url
  prefix_root File.dirname(node['jira']['install_path'])
  home_dir node['jira']['install_path']
  checksum jira_artifact_checksum
  owner 'root'
  group 'root'
  version "#{node['jira']['flavor']}-#{node['jira']['version']}"
  notifies :restart, 'service[jira]'
end

# See: https://confluence.atlassian.com/jira/installing-jira-from-an-archive-file-on-windows-linux-or-solaris-240910362.html
#
# Note: the need for `conf/Catalina` is a workaround for an edge-case bug on
# CentOS 6, in which the directory remains empty.
# See: https://jira.atlassian.com/browse/JRA-31444
%w(logs temp work conf/Catalina).each do |d|
  directory "#{node['jira']['install_path']}/#{d}" do
    owner node['jira']['user']
    group 'root'
    mode 00700
    action :create
  end
end
