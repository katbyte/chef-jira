settings = Jira.settings(node)

database_connection = {
  :host => settings['database']['host'],
  :port => settings['database']['port']
}

case settings['database']['type']
when 'mysql'
  mysql2_chef_gem 'jira' do
    client_version settings['database']['version'] if settings['database']['version']
    action :install
  end

  mysql_service 'jira' do
    version settings['database']['version'] if settings['database']['version']
    bind_address settings['database']['host']
    port settings['database']['port'].to_s
    initial_root_password node['mysql']['server_root_password']
    data_dir node['mysql']['data_dir'] if node['mysql']['data_dir']
    action [:create, :start]
  end

  database_connection.merge!(:username => 'root', :password => node['mysql']['server_root_password'])

  mysql_database settings['database']['name'] do
    connection database_connection
    collation 'utf8_bin'
    encoding 'utf8'
    action :create
  end

  # See this MySQL bug: http://bugs.mysql.com/bug.php?id=31061
  mysql_database_user '' do
    connection database_connection
    host 'localhost'
    action :drop
  end

  mysql_database_user settings['database']['user'] do
    connection database_connection
    host '%'
    password settings['database']['password']
    database_name settings['database']['name']
    action [:create, :grant]
  end
when 'postgresql'
  # TODO: Should this be in attributes file?
  if node['platform_family'] == 'rhel'
    node.default['postgresql']['enable_pgdg_yum'] = true
  end
  include_recipe 'postgresql::server'
  include_recipe 'database::postgresql'
  database_connection.merge!(:username => 'postgres', :password => node['postgresql']['password']['postgres'])

  postgresql_database_user settings['database']['user'] do
    connection database_connection
    password settings['database']['password']
    action :create
  end

  postgresql_database settings['database']['name'] do
    connection database_connection
    connection_limit '-1'
    encoding 'utf8'
    collation 'C'
    template 'template0'
    owner settings['database']['user']
    action :create
  end
end
