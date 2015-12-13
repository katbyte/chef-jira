name 'jira'
maintainer 'KLM Royal Dutch Airlines'
maintainer_email 'martijn.vanderkleijn@klm.com'
license 'Apache 2.0'
description 'Installs/Configures Atlassian JIRA.'
version '2.7.4'

recipe 'jira', 'Installs/configures Atlassian JIRA'
recipe 'jira::apache2', 'Installs/configures Apache 2 as proxy (ports 80/443)'
recipe 'jira::container_server_configuration', 'Configures container server for JIRA deployment'
recipe 'jira::database', 'Installs/configures MySQL/Postgres server, database, and user for JIRA'
recipe 'jira::installer', 'Installs/configures JIRA via installer'
recipe 'jira::standalone', 'Installs/configures JIRA via standalone archive'
recipe 'jira::sysv', 'Installs/configures JIRA SysV init service'

depends 'apache2'
depends 'ark'
depends 'database'
depends 'java'
depends 'mysql', '~> 6.0'
depends 'mysql_connector'
depends 'mysql2_chef_gem'
# Due to revert of PR hw-cookbooks/postgresql#201
# See: https://github.com/hw-cookbooks/postgresql/pull/201
# See: https://github.com/hw-cookbooks/postgresql/commit/b76660bb225b6b09c8bd54273abe5092164114a6
depends 'postgresql', '3.4.16'

supports 'centos', '>= 6.0'
supports 'redhat', '>= 6.0'
supports 'ubuntu', '>= 12.04'
