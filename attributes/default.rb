default['jira']['home_path']          = '/var/atlassian/application-data/jira'
default['jira']['install_path']       = '/opt/atlassian/jira'
default['jira']['install_type']       = 'installer'
default['jira']['version']            = '7.0.0'
default['jira']['flavor']             = 'software'
default['jira']['user']               = 'jira'
default['jira']['group']              = 'jira'
default['jira']['backup_when_update'] = false
default['jira']['ssl']                = false

# Defaults are automatically selected from version via helper functions
default['jira']['url']      = nil
default['jira']['checksum'] = nil

default['jira']['apache2']['access_log']         = ''
default['jira']['apache2']['error_log']          = ''
default['jira']['apache2']['port']               = 80

# Defaults are automatically selected from fqdn and hostname via helper functions
default['jira']['apache2']['virtual_host_name']  = nil # node['fqdn']
default['jira']['apache2']['virtual_host_alias'] = nil # node['hostname']


default['jira']['apache2']['ssl']['access_log']       = ''
default['jira']['apache2']['ssl']['error_log']        = ''
default['jira']['apache2']['ssl']['chain_file']       = ''
default['jira']['apache2']['ssl']['port']             = 443

case node['platform_family']
when 'rhel'
  default['jira']['apache2']['ssl']['certificate_file'] = '/etc/pki/tls/certs/localhost.crt'
  default['jira']['apache2']['ssl']['key_file']         = '/etc/pki/tls/private/localhost.key'
else
  default['jira']['apache2']['ssl']['certificate_file'] = '/etc/ssl/certs/ssl-cert-snakeoil.pem'
  default['jira']['apache2']['ssl']['key_file']         = '/etc/ssl/private/ssl-cert-snakeoil.key'
end

default['jira']['database']['host']     = '127.0.0.1'
default['jira']['database']['name']     = 'jira'
default['jira']['database']['password'] = 'changeit'
default['jira']['database']['type']     = 'mysql'
default['jira']['database']['user']     = 'jira'

# Needed for postgresql unfortunately
if node['jira']['database']['type'] == 'postgresql'
  case node['platform_family']
  when 'debian'
    default['apt']['compile_time_update'] = true
  end
end

# Default is automatically selected from database type via helper function
default['jira']['database']['port'] = nil

default['jira']['jvm']['minimum_memory']  = '256m'
default['jira']['jvm']['maximum_memory']  = '768m'
default['jira']['jvm']['maximum_permgen'] = '256m'
default['jira']['jvm']['java_opts']       = ''
default['jira']['jvm']['support_args']    = ''

default['jira']['tomcat']['port'] = '8080'

default['jira']['crowd_sso']['enabled']        = false
default['jira']['crowd_sso']['sso_appname']    = 'jira'
default['jira']['crowd_sso']['sso_password']   = 'changethistosomethingsensible'
default['jira']['crowd_sso']['crowd_base_url'] = 'http://localhost:8095/crowd/'
