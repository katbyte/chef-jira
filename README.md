Jira Cookbook
==================
[![Chef cookbook](https://img.shields.io/cookbook/v/jira.svg)](https://supermarket.chef.io/cookbooks/jira)
[![Build Status](https://secure.travis-ci.org/afklm/jira.png?branch=master)](http://travis-ci.org/afklm/jira)

*WARNING* - This cookbook was essentially replaced by a new cookbook starting version 2.0. This is a breaking change.

## Description

Installs/Configures Atlassian JIRA. Please see [COMPATIBILITY.md](COMPATIBILITY.md) for more information about JIRA releases that are tested and supported by this cookbook and its versions.

## Requirements

### Chef

* Chef 11+ for version 2.0.0+ of this cookbook

### Platforms

* CentOS 6,7
* RHEL 6
* Ubuntu 12.04

### Databases

* Microsoft SQL Server
* MySQL
* Postgres

### Cookbooks

Required [Opscode Cookbooks](https://github.com/opscode-cookbooks/)

* [apache2](https://github.com/opscode-cookbooks/apache2) (if using apache2 recipe)
* [ark](https://github.com/opscode-cookbooks/ark)
* [database](https://github.com/opscode-cookbooks/database) (if using database recipe)
* [mysql](https://github.com/opscode-cookbooks/mysql) (if using database recipe with MySQL)
* [postgresql](https://github.com/opscode-cookbooks/postgresql) (if using database recipe with Postgres)

Required Third-Party Cookbooks

* [mysql_connector](https://github.com/bflad/chef-mysql_connector) (if using MySQL database)

Suggested [Opscode Cookbooks](https://github.com/opscode-cookbooks/)

* [java](https://github.com/opscode-cookbooks/java)
* [tomcat](https://github.com/opscode-cookbooks/tomcat)

### JDK/JRE

The Atlassian JIRA Linux installer will automatically configure a bundled JRE. If you wish to use your own JDK/JRE, with say the `java` cookbook, then as of this writing it must be Oracle and version 1.6 ([Supported Platforms](https://confluence.atlassian.com/display/JIRA/Supported+Platforms))

Necessary configuration with `java` cookbook:
* `node['java']['install_flavor'] = "oracle"`
* `node['java']['oracle']['accept_oracle_download_terms'] = true`
* `recipe[java]`

A /ht to [@seekely](https://github.com/seekely) for the [documentation nudge](https://github.com/bflad/chef-jira/issues/2).

## Attributes

These attributes are under the `node['jira']` namespace.

Attribute | Description | Type | Default
----------|-------------|------|--------
checksum | SHA256 checksum for JIRA install | String | auto-detected by helper method
home_path | home directory for JIRA | String | /var/atlassian/application-data/jira
install_path | location to install JIRA | String | /opt/atlassian/jira
install_type | JIRA install type - "installer" or "standalone" | String | installer
init_type | JIRA init service type - "sysv" | String | sysv
url | URL for JIRA install | String | auto-detected by helper method
user | user running JIRA | String | jira
version | JIRA version to install | String | 6.1.5

**Notice:** If `['jira']['install_type']` is set to `installer`, then the installer will try to upgrade your JIRA instance located in `['jira']['install_path']` (if it exists) to the `['jira']['version']`.

If you want to avoid an unexpected upgrade, just set or override `['jira']['version']` attribute value to that of your current JIRA version.

### JIRA Database Attributes

All of these `node['jira']['database']` attributes are overridden by `jira/jira` encrypted data bag (Hosted Chef) or data bag (Chef Solo), if it exists

Attribute | Description | Type | Default
----------|-------------|------|--------
host | FQDN or "localhost" (localhost automatically installs `['database']['type']` server in default recipe) | String | localhost
name | JIRA database name | String | jira
password | JIRA database user password | String | changeit
type | JIRA database type - "mssql", "mysql", or "postgresql" | String | mysql
user | JIRA database user | String | jira

### JIRA JVM Attributes

These attributes are under the `node['jira']['jvm']` namespace.

Attribute | Description | Type | Default
----------|-------------|------|--------
minimum_memory | JVM minimum memory | String | 512m
maximum_memory | JVM maximum memory | String | 768m
maximum_permgen | JVM maximum PermGen memory | String | 256m
java_opts | additional JAVA_OPTS to be passed to JIRA JVM during startup | String | ""
support_args | additional JAVA_OPTS recommended by Atlassian support for JIRA JVM during startup | String | ""

### JIRA Tomcat Attributes

These attributes are under the `node['jira']['tomcat']` namespace.

Attribute | Description | Type | Default
----------|-------------|------|--------
port | Tomcat HTTP port | Fixnum | 8080

## Recipes

* `recipe['jira']` 'Installs/configures Atlassian JIRA'
* `recipe['jira::apache2']` 'Installs/configures Apache 2 as proxy (ports 80/443)'
* `recipe['jira::container_server_configuration']` 'Configures container server for JIRA deployment'
* `recipe['jira::database']` 'Installs/configures MySQL/Postgres server, database, and user for JIRA'
* `recipe['jira::installer']` 'Installs/configures JIRA via installer'
* `recipe['jira::standalone']` 'Installs/configures JIRA via standalone archive'

## Usage

### JIRA Server Data Bag

Optionally for securely overriding attributes on Hosted Chef, create a `jira/jira` encrypted data bag with the model below. Chef Solo can override the same attributes with a `jira/jira` unencrypted data bag of the same information.

_required:_
* `['database']['type']` - "mssql", "mysql", or "postgresql"
* `['database']['host']` - FQDN or "localhost" (localhost automatically installs `['database']['type']` server)
* `['database']['name']` - Name of JIRA database
* `['database']['user']` - JIRA database username
* `['database']['password']` - JIRA database username password

_optional:_
* `['database']['port']` - Database port, defaults to standard database port for `['database']['type']`

Repeat for other Chef environments as necessary. Example:

    {
      "id": "jira",
      "development": {
        "database": {
          "type": "postgresql",
          "host": "localhost",
          "name": "jira",
          "user": "jira",
          "password": "jira_db_password",
        }
      }
    }

### Default JIRA Installation

The simplest method is via the default recipe, which uses `node['jira']['install_type']` (defaults to installer).

* Optionally (un)encrypted data bag or set attributes
  * `knife data bag create jira`
  * `knife data bag edit jira jira --secret-file=path/to/secret`
* Add `recipe[jira]` to your node's run list.

### Standalone JIRA Installation

Operates similarly to installer installation, however has added benefits of using `ark` to create version symlinks of each install. Easily can rollback upgrades by changing `node['jira']['version']`.

* Optionally (un)encrypted data bag or set attributes
  * `knife data bag create jira`
  * `knife data bag edit jira jira --secret-file=path/to/secret`
* Set `node['jira']['install_type']` to standalone
* Add `recipe[jira]` to your node's run list.

### JIRA WAR Support

Starting from JIRA 7, WAR installation is no longer supported:
https://confluence.atlassian.com/jira/installing-jira-war-185729447.html

### Custom JIRA Configurations

Using individual recipes, you can use this cookbook to configure JIRA to fit your environment.

* Optionally (un)encrypted data bag or set attributes
  * `knife data bag create jira`
  * `knife data bag edit jira jira --secret-file=path/to/secret`
* Add individual recipes to your node's run list.

## Testing and Development

* Quickly testing with Vagrant: [VAGRANT.md](VAGRANT.md)
* Full development and testing workflow with Test Kitchen and friends: [TESTING.md](TESTING.md)

For Vagrant, you may need to add the following hosts entries:

* 192.168.50.10 jira-centos-6
* 192.168.50.10 jira-ubuntu-1204
* (etc.)

The running JIRA server is then accessible from the host machine:

CentOS 6 Box:
* Web UI (installer/standalone): https://jira-centos-6/

Ubuntu 12.04 Box:
* Web UI (installer/standalone): https://jira-ubuntu-1204/

## Contributing

Please see contributing information in: [CONTRIBUTING.md](CONTRIBUTING.md)

## Maintainers

* KLM Royal Dutch Airlines

## License

Please see licensing information in: [LICENSE](LICENSE)
