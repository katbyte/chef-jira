Jira Cookbook
==================
[![Chef cookbook](https://img.shields.io/cookbook/v/jira.svg)](https://supermarket.chef.io/cookbooks/jira)
[![Build Status](https://secure.travis-ci.org/afklm/jira.png?branch=master)](http://travis-ci.org/afklm/jira)

## Description

Installs/Configures Atlassian JIRA. Starting from release 2.8.0 of this cookbook, the default DB used is Postgres due to various bugs and speed issues with MySQL.

## Requirements

### Chef

* Chef 11.14+ for version 2.7.1+ of this cookbook

### Platforms

* CentOS 6
* RHEL 6
* Ubuntu 12.04

### Databases

* MySQL
* Postgres

### JDK/JRE

The Atlassian JIRA Linux installer will automatically configure a bundled JRE. If you wish to use your own JDK/JRE, with say the `java` cookbook, then as of this writing it must be Oracle and version 1.7 or 1.8.

For the up-to-date list, please see [Supported Platforms](https://confluence.atlassian.com/display/JIRA/Supported+Platforms)

Necessary configuration with `java` cookbook:
* `node['java']['install_flavor'] = "oracle"`
* `node['java']['oracle']['accept_oracle_download_terms'] = true`
* `recipe[java]`

A /ht to [@seekely](https://github.com/seekely) for the [documentation nudge](https://github.com/bflad/chef-jira/issues/2).

## Attributes

These attributes are under the `node['jira']` namespace.

Attribute    | Description                                           | Type   | Default
-------------|-------------------------------------------------------|--------|---------------------------------------
checksum     | SHA256 checksum for JIRA install                      | String | auto-detected by helper method
home_path    | home directory for JIRA                               | String | /var/atlassian/application-data/jira
install_path | location to install JIRA                              | String | /opt/atlassian/jira
install_type | JIRA install type - "installer" or "standalone"       | String | installer
init_type    | JIRA init service type - "sysv"                       | String | sysv
url          | URL for JIRA install                                  | String | auto-detected by helper method
user         | user running JIRA                                     | String | jira
version      | JIRA version to install                               | String | 7.0.4
flavor       | JIRA product flavor to install - 'core' or 'software' | String | software

**Notice:** If `['jira']['install_type']` is set to `installer`, then the installer will try to upgrade your JIRA instance located in `['jira']['install_path']` (if it exists) to the `['jira']['version']`.

If you want to avoid an unexpected upgrade, just set or override `['jira']['version']` attribute value to that of your current JIRA version.

### JIRA Database Attributes

All of these `node['jira']['database']` attributes are overridden by `jira/jira` encrypted data bag (Hosted Chef) or data bag (Chef Solo), if it exists

Attribute | Description                                   | Type   | Default
----------|-----------------------------------------------|--------|------------
host      | FQDN or "127.0.0.1"                           | String | 127.0.0.1
name      | JIRA database name                            | String | jira
password  | JIRA database user password                   | String | changeit
type      | JIRA database type - "mysql", or "postgresql" | String | postgresql
user      | JIRA database user                            | String | jira

The Postgres DB is automatically tuned for 'web' and with 1GB of memory for Postgres. Please see the https://github.com/hw-cookbooks/postgresql cookbook for more details, specifically the config_pgtune section.

Please note that specifying "127.0.0.1" for the host automatically installs `['database']['type']` server in the default recipe.

### JIRA JVM Attributes

These attributes are under the `node['jira']['jvm']` namespace.

Attribute       | Description                                                                       | Type   | Default
----------------|-----------------------------------------------------------------------------------|--------|--------
minimum_memory  | JVM minimum memory (set by autotune recipe if autotune enabled, see below)        | String | 512m
maximum_memory  | JVM maximum memory (set by autotune recipe if autotune enabled, see below)        | String | 768m
maximum_permgen | JVM maximum PermGen memory                                                        | String | 256m
java_opts       | additional JAVA_OPTS to be passed to JIRA JVM during startup                      | String | ""
support_args    | additional JAVA_OPTS recommended by Atlassian support for JIRA JVM during startup | String | ""

### JIRA Autotune Attributes

These attributes are under the `node['jira']['autotune']` namespace. Autotune automatically determines appropriate settings for certain
attributes. This feature is inspired by the `config_pgtune` recipe in the https://github.com/hw-cookbooks/postgresql cookbook. This
initial version only supports JVM min and max memory size tuning.

There are several tuning types that can be set:

* 'mixed' - JIRA and DB run on the same system
* 'dedicated' - JIRA has the system all to itself
* 'shared' - JIRA shares the system with the DB and other applications

Total available memory is auto discovered using Ohai but can be overridden by setting your own value in kB.

Attribute    | Description                                                           | Type    | Default
-------------|-----------------------------------------------------------------------|---------|------------
enabled      | Whether or not to autotune settings.                                  | Boolean | false
type         | Type of tuning to apply. One of 'mixed', 'dedicated' and 'shared'.    | String  | mixed
total_memory | Total system memory to use for autotune calculations.                 | String  | Ohai value

### JIRA Tomcat Attributes

These attributes are under the `node['jira']['tomcat']` namespace.

Attribute | Description      | Type   | Default
----------|------------------|--------|--------
port      | Tomcat HTTP port | Fixnum | 8080

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

For information on how to contribute to this cookbook, please see: [CONTRIBUTING.md](CONTRIBUTING.md)

Development of this cookbook has been generously supported in part by the code contributions of the following organizations and/or users:

* [University of Pennsylvania](http://www.upenn.edu/) ([@bflad](https://github.com/afklm/jira/commits?author=bflad))
* [KLM Royal Dutch Airlines](https://www.klm.com/) ([@mvdkleijn](https://github.com/afklm/jira/commits?author=mvdkleijn))
* [Parallels Inc.](https://www.parallels.com/) ([@legal90](https://github.com/afklm/jira/commits?author=legal90))
* [Blended Perspectives Inc.](http://www.blendedperspectives.com/) ([@patcon](https://github.com/afklm/jira/commits?author=patcon))

For a full list of contributors, please see [Github](https://github.com/afklm/jira/graphs/contributors)

## Current maintainers

* KLM Royal Dutch Airlines

## Sponsors

Development of this cookbook has been generously supported in part by
the code contributions of the following organizations:

* [University of Pennsylvania](http://www.upenn.edu/)
  ([@bflad](https://github.com/afklm/jira/commits?author=bflad))
* [KLM Royal Dutch Airlines](https://www.klm.com/)
  ([@mvdkleijn](https://github.com/afklm/jira/commits?author=mvdkleijn))
* [Parallels Inc.](https://www.parallels.com/)
  ([@legal90](https://github.com/afklm/jira/commits?author=legal90))
* [Blended Perspectives Inc.](http://www.blendedperspectives.com/)
  ([@patcon](https://github.com/afklm/jira/commits?author=patcon))

## License

Please see licensing information in: [LICENSE](LICENSE)
