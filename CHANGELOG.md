# Change log

## Version 0.12.14 (Jul 12, 2017)

Minor enahancements:
  * Added optional package dependency of Jemalloc for Ruby installer
  * Made custom uncompress format of tar in package installer
  * Upgraded dependency on OpenSSL for Curl to version 1.1.0f
  * Upgraded following dependencies for Git
    * OpenSSL to version 1.0.2l
    * Curl to version 7.54.1
  * Upgraded following dependencies for Ruby
    * OpenSSL to version 1.0.2l (Ruby >= 1.9.3 and < 2.4.0)
    * OpenSSL to version 1.1.0f (Ruby >= 2.4.0)
    * Rubygems to version 2.6.12 (Ruby >= 1.9.3)
    * Bundler to version 1.15.1

## Version 0.12.12 (Mar 30, 2017)

Minor enhancements:
  * Added parameter, :base_os, to specify the Dockerfile template by OS
    * By default, :base_os is set to "centos"
    * The original Dockerfile.erb was renamed to Dockerfile.centos.erb
    * Down the road more other OS Dockerfile templates will be added

## Version 0.12.11 (Mar 29, 2017)

Bug fixes:
  * Cleaned up app releases except the most recent one during dockerization
  * Corrected the default value for parameter :user in Luban::Deployment::Runner
  * Fixed typos in the template of Lubanfile.rb.erb

## Version 0.12.9 (Mar 23, 2017)

Minor enhancements:
  * Used Etc.getpwnam to retrieve current user id
  * Speeded up bundle install gems with bundle jobs (default: 4)
  * Added docker config parameters, #docker_workdir, #docker_entrypoint, #docker_command
    * Applied the new docker config parameters in Dockerfile template
    * Also, setup PATH properly instead of using environment resource file in Dockerfile template
  * Added environment variables in docker-compose template
  * Added util method, #cleanup_files, to manage retention of file copies like releases
  * Upgraded dependency of Git on Curl to version 7.53.1
  * Ensured environment dockerization occur if any dockerized components are changed
  * Cleaned up dockerized archives properly
  * Only install packages that are currently used during dockerization
  * Only deploy releases that are currently used during dockerization

Bug fixes:
  * Skipped uninstalling a given package if any other packages depends on it
  * Skipped binstubs updates in package installation if the package is a dependence of another package

## Version 0.12.8 (Feb 23, 2017)

Bug fixes:
  * Changed vendor path to bundler path to ensure bundle config is properly packaged into the docker image
    * Relocated bundle config path (.bundle) into bundler path
    * Relocated vendor path (vendor/bundle and vendor/cache) into bundler path

## Version 0.12.7 (Feb 22, 2017)

Minor enhancements:
  * Upgraded Curl's dependency on OpenSSL to version 1.1.0e
  * Upgraded Git's dependency on OpenSSL to version 1.0.2k
  * Upgraded Ruby's dependency on Rubygems to version 2.6.10
  * Supported Ruby 2.4.0 installation with OpenSSL 1.1.0e
    * For Ruby version between 1.9.3 and 2.4.0, Upgraded dependency on OpenSSL to version 1.0.2k
  * Cleaned up Bundler environment before executing any worker tasks
  * Deprecated docker build command and used docker compose instead
  * Separated packages and releases by stage
    * Although packages and releases are not related to stages directly, there are edge cases that package config and release config could be conflicting between stages; therefore,
    * decided to put back stage into packages and releases deployment
  * Added convenient method, #version_match?, to check version requirements easily
  * Supported OpenSSL 1.1 installation
    * Optimized OpenSSL configuration parameters for 1.1.x and 1.0.x
    * Added switch to enable/disable document generation
    * Decompose OpenSSL version more accurately

Bug fixes:
  * Disabled rdoc/ri generation gracefully based on actual Rubygems version
  * Output exception backtrace regardless what output format is specified

## Version 0.12.6 (Feb 17, 2017)

Minor enhancements:
  * Added new Luban parameter for docker, #base_packages, to specify OS packages/libs/tools
    * As a result, optimized Dockerfile.erb for yum install with this new parameter

## Version 0.12.5 (Feb 16, 2017)

Minor enhancements:
  * Added labels in docker image to show info about installed packages
  * Added new Dockerfile arguments, #luban_user and #luban_uid, to specify user name and user id used in a docker container if necessary
    * This is mainly to address the permission issues on docker volumes
    * It can be changed thru dotenv file for docker-compose
  * Added new Dockerfile argument, #luban_root_path, to specify root path for luban deployments if necessary
    * It can be changed thru dotenv file for docker-compose
  * Refactored luban_user and luban_uid as build arguments
  * Used environment variable TZ to correctly control the timezone for a docker container
  * Cleaned up and optimized Dockerfile
  * Bump up gem dependency on luban-cli to version 0.4.9

Bug fixes:
  * Correctly composed revisions for build sources
  * Fixed a typo in the template of Dockerfile.erb
  * Checked the result of bundle install/package in Repository before proceeding to the rest steps
  * Checked the result of bundle install in Publisher before proceeding to the rest steps
  * Removed redundant add commands in Dockerfile.erb
  * Added proper prefix of build sources in dockerization

## Version 0.12.1 (Feb 09, 2017)

Minor enhancements:
  * Added build context in docker compose file template
  * Used docker-compose to build application

## Version 0.12.0 (Feb 08, 2017)

New features
  * Supported Docker deployment
  * Handled docker options for remote connectivity properly
    * Docker options could be set per stage config as well as per app server

Minor enhancements:
  * Refactored common paths into module Luban::Deployment::Package::Worker::Base
  * Defined root paths for docker, releases, packages and deployment projects
  * Restructured symlinks for vendor/cache and vendor/bundle
  * Deprecated deployment release log
  * Minor bug fixes and code cleanup

## Version 0.11.6 (Feb 07, 2017)

Bug fixes:
  * Corrected symlink creations for profiles when deploying releases

## Version 0.11.6 (Feb 07, 2017)

Bug fixes:
  * Fixed symlinks creation for profile when deploying releases

## Version 0.11.5 (Jan 12, 2017)

Minor enhancements:
  * Added a package option, :deprecated, to manage package deprecation which is similar to release deprecation

Bug fixes:
  * Corrected the package installation path for a given application

## Version 0.11.3 (Jan 09, 2017)

Minor enhancements:
  * Separated package installations by application instead of by project
  * Enhanced the Curl package configure to set a hard-coded path to the run-time linker for SSL
  * Enhanced Git installation:
    * Added package dependency of Curl and an install option to specify Curl version
    * Added install switch, #install_tcltk, to turn on/off tcltk installation (default: off)
    * Turned off localization for Git installation (NO_GETTEXT=1)

Bug fixes:
  * Corrected the long descriptions for package provision commands

## Version 0.11.1 (Jan 04, 2017)

New features:
  * Restructured Luban project prepared for containerization with docker support
    * Relocated packages installation path to luban root
    * Relocated releases deployment path to luban root

Minor enhancements:
  * Added convenient util method, #with_clean_env, to cleanup Bundler environment before yielding the given code block
  * Cleaned up Bundler environment:
    * In Gem Installer before any gem installations
    * In Bundler Installer before checking the version for installed Bundler
    * In Publisher before installing gems from cache
    * In App Repository before bundling gems required by application
    * In Service Controller for process control actions
  * Used md5sum/md5 instead of openssl to calculate md5 digests

Bug fixes:
  * Refined SSHKit::Backend::Local and SSHKit::Runner::Abstract to handle local host object properly

## Version 0.10.13 (Dec 17, 2016)

Minor enhancements:
  * Added switch, :install_static, to install static Ruby library
    * By default, :install_static is turned off
    * Ruby config switch "--enable-shared" will be added if :install_static is off
    * Removed static Ruby library manually if :install_static is off

Bug fixes:
  * Disabled document generation for Rubygems

## Version 0.10.12 (Dec 14, 2016)

Minor enhancements:
  * Added a host property, :local, to indicate if the host is a localhost
    * If local host property is not set, hostname lookup will be carried out to check if the given hostname is a local host
  * Added a general parameter, :skip_promptless_authen, to skip promptless authenticaiton setup
    * By default, :skip_promptless_authen is turned off
  * Skipped prompltess authentication setup for local host

## Version 0.10.11 (Dec 01, 2016)

Minor enhancements:
  * Enforced re-creation of binstubs/symlinks for services after profile deployment
  * Updated decriptions for binstubs to include symlinks for the sake of clarity

## Version 0.10.10 (Nov 29, 2016)

Minor enhancements:
  * Added #control_path to further refractor control file related paths

## Version 0.10.9 (Nov 28, 2016)

Bug fixes:
  * Used proper linker flag to ensure libssl shared library is being linked properly in Curl (Linux)

## Version 0.10.8 (Nov 26, 2016)

Minor enhancements:
  * Added #control_file_dir to specify directory name for control file
    * By default, control_fir_dir is also used in linked_files handling

Bug fixes:
  * Normalized executable name into proper method name when defining executable for a given package

## Version 0.10.6 (Nov 24, 2016)

Minor enhancements:
  * Enhanced linked_files become a convention instead of a configuration
  * Checked md5 for gem cache directory before actually sync each gem in gem cache

Bug fixes:
  * Excluded *.md5 files, if any, when calculating md5 for a given directory
  * Corrected the md5_file path when calculating md5 for each Ruby gem
  * Checked linked files dir's existence before actually linking files
  * Properly composed source path for linked files

## Version 0.10.3 (Nov 22, 2016)

Minor enhancements:
  * Upgraded Bundler for Ruby to version 0.13.6
  * Removed bundle install during deployment project bootstrap
    * Falled back to use "bundle install" which is a more persistent/general practice
  * Ensured shell out bundler commands to setup application gems dependencies
    * Luban deployment project also uses Bundler to manage its gems dependencies, therefore
    * Used with_clean_env to invoke application level bundler commands

Bug fixes:
  * Properly convert require path to string when loading luban package

## Version 0.10.0 (Nov 21, 2016)

New features:
  * Used bundler to manage gem dependencies in Luban deployment projects
    * By default, gems will be bundled in vendor/bundle
    * Added one command-line option, --bundle-path, to customize the bundle path
    * Updated Gemfile template with Luban dependency on version 0.10.x

Minor enhancements:
  * Deprecated Rubygems-update and setup Rubygems directly for Rubygems upgrade
  * Upgraded Rubygems to version 2.6.8

## Version 0.9.17 (Nov 16, 2016)

Minor enhancements:
  * Added convenient method #package_install_path to get package install path for a given package
  * Added command options to customize a shell command for crontab entry
  * Added a convenient file tester, #exists?, in Utils

## Version 0.9.16 (Nov 09, 2016)

Bug fixes:
  * Fixed a bug in checking local gem file existence

## Version 0.9.15 (Nov 06, 2016)

Minor enhancements:
  * Refactored md5 calculation utilities

Bug fixes:
  * Properly synced git-based bundled gems to app servers

## Version 0.9.14 (Oct 31, 2016)

Minor enhancements:
  * Assigned cronjobs to each host after configuration is loaded

Bug fixes:
  * Ensured only one controller from service or application controller can be executed
    * Rolledback the last change and
    * Enforced the logic in the control/monitor actions instead

## Version 0.9.13 (Oct 28, 2016)

New features:
  * Added Luban::Deployment::Script to handle deployment for script-based application

Bug fixes:
  * Ensured only one controller from service or application controller can be executed

## Version 0.9.12 (Oct 27, 2016)

Bug fixes:
  * Fixed local source initialization issue
    * As a side effect, refactored local source handling

## Version 0.9.11 (Oct 24, 2016)

Bug fixes:
  * Eval the parameter default value block (if given) under the context of the instance instead of the class

## Version 0.9.10 (Oct 24, 2016)

Minor enhancements:
  * Refactored and enhanced the design and implementation of parameters in a deployment project
    * Supported default value for a given parameter
      * set method for default value should be in the form of "set_default_for_parameter_name"
      * any methods following the above convention will be called during default value setup
    * Supported parameter validation by convention
      * validation method name should be in the form of "validate_for_parameter_name"
      * any methods following the above convention will be called during parameter validation
    * Injected parameters from service package, if any, into the application
  * Automated default source handling and thus no more manual set_default_source
    * Two default source paths under application base path and stage config path


Bug fixes:
  * Ensured linked dirs to be created in package installer

## Version 0.9.9 (Oct 20, 2016)

Bug fixes:
  * Fixed a template issue for crontab.logrotate.erb.erb

## Version 0.9.8 (Oct 19, 2016)

New features:
  * Added new parameters, #logrotate_max_age, #logrotate_interval and #logrotate_count for log rotation control
    * Refactored these out from logrotate config to make change easier & cleaner
    * Respected the environment variable, #LUBAN_LOGROTATE_INTERVAL, to receive the default value
    * Updated crontab logrotate configuration to utilize the new parameters
  * Bump up gem dependency of luban-cli to 0.4.8

## Version 0.9.7 (Oct 19, 2016)

Bug fixes:
  * Handled empty shell setup appropriately when composing shell command

## Version 0.9.6 (Oct 18, 2016)

Minor enhancements:
  * Added logrotate configuration template for cronjobs in deployment application skeleton

Bug fixes:
  * Checked authorization for all public keys before setting up promptless authentication
    * Especially useful for multiple public keys passed in to setup promptless authentication

## Version 0.9.5 (Oct 18, 2016)

New features:
  * Added package support for Curl

Minor enhancements:
  * Upgraded the dependency on OpenSSL in Git to version 1.0.2j
  * Refactored symlink creation for archived logs
  * Updated package dependency of rubygems-update in Ruby to version 2.6.7 instead of latest to avoid unnecessary network query

## Version 0.9.4 (Oct 17, 2016)

New feature:
  * Supported Rubygems-update for Ruby version 1.9.3 or above

Minor enhancements:
  * Refactored gem installer and applied changes to gem installers for Bundler and RubygemsUpdates
  * Added abstract methods to get latest version in Package::Base
    * Retrieved latest package version if the version is specified as "latest"
  * Upgraded Bundler to 1.13.5 in Ruby

Bug fixes:
  * Fixed a bug in adding host to a given role
  * Ensured symlink for archived logs path to be created for profile-based application publication

## Version 0.9.2 (Oct 13, 2016)

Bug fixes:
  * Checked nullity for #scm_role and #archive_role before setup promptless SSH authentication

## Version 0.9.1 (Oct 13, 2016)

New features:
  * Setup password-less SSH connection to central archives server if it is provided
    * From application servers to central archives server
    * From deployment server to central archives server

Bug fixes:
  * Ensure server set for a given role is updated when an existing server is assigned a new role

## Version 0.9.0 (Oct 12, 2016)

New features:
  * Added package for Logrotate
    * Added dependent package for Popt
  * Added support for log archival which is done thru Uber
  * Added two convenient methods, #touch and #truncate, in module Utils

Minor enhancements:
  * Set keep_releases differently for app and profile publication
  * Made application always deployable
    * Application has/has no cronjobs to update which implies deployable
  * Deprecated symlinks for logrotate configuration files
    * As a result, directory "etc" is removed as well since it is no more necessary
  * No more place holder cronjob entries if there are no more cronjobs defined
  * Refactored profile templates handling in service configurator
  * Cleaned up profile files that have been excluded
  * Made luban_roles as the default roles when setting up cronjobs
  * Added back support for build environment variables like LDFLAGS/CFLAGS
  * Upgraded OpenSSL for Ruby to version 1.0.2j
  * Upgraded Bundler for Ruby to version 1.13.3
  * Added Rubygems dependency for Ruby (version >= 1.9.3)
    * As a side effect, package option #rubygems for Ruby can be set for all Ruby versions
  * Minor code cleanup

Bug fixes:
  * Added an extra validation for URL existence test

## Version 0.8.10 (Sept 29, 2016)

Minor enhancements:
  * Enhanced monitor status check up by service/application

Bug fixes:
  * Increased keep_releases from 1 to 5 in Publisher to solve puma restart failure

## Version 0.8.9 (Sept 28, 2016)

Minor enhancements:
  * Added monitoring support for Luban::Deployment::Project

Bug fixes:
  * Added descriptions for subcommand groups: provision, control, monitor and crontab

## Version 0.8.8 (Sept 28, 2016)

Minor enhancements:
  * Applied subcommand grouping for better clarity
    * As a result, bump up gem dependency of Luban::CLI to version 0.4.6

## Version 0.8.7 (Sept 27, 2016)

Minor enhancements:
  * Added option #format to specify archive file format explicitly
  * Added subcommands to manage process monitor: #monitor_on, #monitor_off and #monitor_reload
  * Refactored convenient methods to handle process monitor

Bug fixes:
  * Fixed local variables in global context in .envrc/.unset_envrc files to void bash warnings
  * Skipped md5 checksum calculation for gem packages if md5 has been generated previously
  * Handled result update more appropriately

## Version 0.8.6 (Sept 23, 2016)

Bug fixes:
  * Fixed a bug for properly updating crontab when other unrelated crontab entries exist

## Version 0.8.5 (Sept 23, 2016)

Minor enhancemnets:
  * Added extra parameter :project in #bundle_via to specify project to find bundler
    * Default project is set to "uber"

## Version 0.8.4 (Sept 22, 2016)

Minor enhancements:
  * Added method #bundle_via to specify Ruby version to bundle gems with
    * This is useful for bundling gems that requires specific Ruby version
  * Forced bundler using the gems already present in vendor/cache thru option "--local"

Bug fixes:
  * Added source release to cronjob deployment if source is provided
  * Properly update cronjob if the crontab contains other unrelated entries

## Version 0.8.3 (Sept 21, 2016)

Minor enhancements:
  * Simplified process_monitor settings
  * Checked if process is monitorable before any monitoring related operations
    * thru convenient method #process_monitorable?
  * Added control file for process monitor
  * Used #include instead of #prepend when loading monitoring public commands

## Version 0.8.2 (Sept 20, 2016)

Minor enhancements:
  * Added option #rubygems to specify the version of Rubygems to install
    * Effective for Ruby v1.9.2 or below

## Version 0.8.1 (Sept 20, 2016)

Minor enhancements:
  * Refactored process monitor commands

Bug fixes:
  * Fixed a typo in output redirection for /dev/null

## Version 0.8.0 (Sept 19, 2016)

# New features:
  * Supported cronjob deployment

Minor enhancements:
  * Refactored Service::Worker#compose_command to be more flexible
  * Enhanced util method #upload_by_template to handle header and footer template rendering
  * Added convenient method #bundle_command to compose command running within the bundler context
  * Refactored the way of composing shell commands including cronjob commands
  * Minor code cleanup

## Version 0.7.15 (Sept 07, 2016)

Minor enhancements:
  * During app packaging, extracted vendor/gems from the source code if any along with Gemfile/Gemfile.lock
    * As a result, bump up gem dependency on luban-cli to version 0.4.5 or above

## Version 0.7.14 (Sept 06, 2016)

Minor enhancements:
  * Properly handled different download URL for recent/old releases of OpenSSL

Bug fixes:
  * Checked if a given package is downloaded first before installing the package
  * Checked the existence of the MD5 file for source package before reading it

## Version 0.7.13 (Sept 05, 2016)

Minor enhancements:
  * Enhanced to check if the remote origin URL matches the specified Git repository URL during build
  * Added two install options #install_tcl and #install_tk for Ruby
    * By default, both install options are turn off
  * Created symlinks for Ruby header files that are needed for native gem installation
    * This is useful to solve native gem installation for Ruby 1.8

Bug fixes:
  * Cleaned up published content before publish it again forcely

## Version 0.7.12 (Sept 02, 2016)

Minor enhancements:
  * Supported specifying shell command output, default "2>&1"
  * Minor refactoring

## Version 0.7.11 (Sept 01, 2016)

Minor enhancements:
  * Supported specifying shell command prefix
  * Minor code refactoring

## Version 0.7.10 (Sept 01, 2016)

Bug fixes:
  * Used "&&" instead of ";" to join shell setup commands to ensure the rest of the commands would not be executed if one is broken
  * Added install dependency on OpenSSL version 0.9.8zh for Ruby 1.8.7 or earlier because OpenSSL 1.x.x version does not support Ruby 1.8 in general
  * Handled first Bundler installation without uninstalling older versions of Bundler

## Version 0.7.9 (Aug 31, 2016)

Minor enhancements:
  * Injected #packages into deployment worker in order to make each package available to others

## Version 0.7.8 (Aug 31, 2016)

Minor enhancements:
  * Refactored to use #profile_name to define the name of the profile folder for applications and services to avoid profile collision between applications and services.
  * Cleanedup leftover from last install if any

## Version 0.7.7 (Aug 31, 2016)

Minor enhancements:
  * Added start_sequence & stop_sequence in Project to customize the way to start/stop apps/serivces

Bug fixes:
  * Used snakecase (instead of downcase) to convert application class name to application name

## Version 0.7.6 (Aug 30, 2016)

Bug fixes:
  * Used --no-rdoc and --no-ri instead of --no-document to be backward compatible
  * Ensured extracting Gemfile and Gemfile.lock without raising any exceptions during app packaging

## Version 0.7.5 (Aug 30, 2016)

Minor enhancements:
  * Extracted linked_dirs/linked_files handling into LinkedPaths module
  * Used LinkedPaths module to change linked_dirs/linked_files into worker level instance variables instead of global configuration to better cope with different linked paths requirements among different worker classes from Application and Service, like Publisher and Installer

Bug fixes:
  * Correctly composed the bundle command when installing gems from cache in Publisher
  * Extracted Gemfile.lock in addition to Gemfile if any from the release tarball to ensure deploy the exact same set of gems specified from the Gemfile.lock in code repository

## Version 0.7.4 (Aug 26, 2016)

Bug fixes:
  * Fixed reading the md5 file for the source package
  * Changed default_templates_paths to an inheritable class instance variable to better handle inheritance for default template paths

## Version 0.7.3 (Aug 25, 2016)

New features:
  * Added default/embeded source to support Ruby application like Fluentd whose source code contains Gemfile only
  * Added .gitkeep to the .gitignore

Bug fixes:
  * Touch the last release mtime to ensure it will NOT be deleted during release cleanup
  * Fixed the helper method #cp

## Version 0.7.2 (Aug 23, 2016)

Minor enhancements:
  * Better handled orphaned pid file removal

## Version 0.7.1 (Aug 19, 2016)

Minor enhancements:
  * Refactor shared symlink creation for linked_dirs and linked_files

Bug fixes:
  * Properly handled backtrace switch from commandline options
  * Removed target directory/file if it exists already during creating symlinks for linked_dirs

## Version 0.7.0 (Aug 18, 2016)

New features:
  * Supported app configuration stored in the environment variables

## Version 0.6.9 (Aug 15, 2016)

Minor enhancements:
  * Set parameter #project in Lubanfile template used in project initiation
  * Added suffix ".deploy" as extension to project target path as a convention

Bug fixes:
  * Handled bundle_without properly based on the deployment stage

## Version 0.6.8 (Aug 05, 2016)

Bug fixes:
  * Fixed missing default templates in application class inheritance

## Version 0.6.7 (Aug 02, 2016)

Minor enhancements:
  * Added convenient class method #applcation_action
  * Removed support for Cluster in Service::Controller
    * Support for Cluster has been moved to Rack::Controller (luban-rack)
  * Added exclude filter, #exclude_template?, for #profile_templates in Service::Configurator
    * Facilitate template filtering during profile rendering

## Version 0.6.6 (Jul 27, 2016)

Bug fixes:
  * Refactored #default_templates_path to fix an inheritance issue

## Version 0.6.5 (Jul 27, 2016)

New features:
  * Remade application release handling to manage multiple releases
    * Supported deployment for multiple releases
    * Supported release deprecation
    * supported release summary
    * Simplified release cleanup

Minor enhancements:
  * Changed release_tag format for git commit in Git scm strategy
  * Used attribute :version to unify :branch, :tag and :ref in Git scm strategy
  * Deprecated parameter #keep_releases
    * Releases retension is changed to control by manual configurations
  * Added option #force for command #deploy
  * Minor code refactor and cleanup

Bug fixes:
  * Fixed display issue for pgrep under CentOS

## Version 0.6.2 (Jul 14, 2016)

New features:
  * Automatically reload process monitor before start any apps/services to ensure process monitor has the most updated process monitoring configurations

Minor enhancements:
  * Added convenient methods to look up project/application instances
  * Added a convenient method to get current app path/symlink

Bug fixes:
  * Checked versions ONLY when the application has source code

## Version 0.6.1 (Jul 11, 2016)

New features:
  * Added subcommand #process to grep and show running service/application processes
  * Subcommands #version and #versions now also show the release info for application
  * Used group to monitor/unmonitor service for cluster mode

## Version 0.6.0 (Jul 08, 2016)

New features:
  * Added support for Cluster in Service::Controller
  * Added control & configuration support for application if it has its own source code

Minor enhancements:
  * Ensured profile updates with the updated release info passed thru task to Configurator
  * Refactored and standardized the following metadata for worker task:
    * :name, :full_name, :version:, :major_version, :patch_level
    * Created correponding instance methods with proper prefix for worker classes:
      * Worker::Base with prefix "target_"
      * Package::Worker with prefix "package_" 
      * Service::Worker with prefix "service_"
      * Application::Worker with prefix "application_"
  * Updated binstubs after source code deployment in case any new bins are deployed
  * Made task dispatcher method as protected
  * Removed two unnecessary parameters: :log_format and :log_level
  * Refactored method #default_templates_path in a DRY way
  * Minor code cleanup

Bug fixes:
  * Returned revision as nill if any unexpected errors occur during revision fetching for Git
  * Do not create symlinks for linked_dirs when publishing application profile
  * Fixed duplicate result output when output format is not blakchole
  * Made task dispatcher methods as protected

## Version 0.5.5 (Jun 29, 2016)

Minor enhancements:
  * Refactored app/service profile templates initialization
  * Refactored Service::Worker to abstract general behavior for Service/Application
  * Refactored Service::Configurator to abstract general configuration for Service/Application
  * Refactored Service::Controller to abstract general control for Service/Application
  * Changed attribute :name to :type in Application::Repository for better naming
  * Changed attribute :release_name to :release_type in Application::Publisher for better naming
  * Removed deploy commands in Service because deploy commands exist ONLY in application level
  * Renamed application Builder to Constructor for better naming convention in Luban
  * Minor refactoring

## Version 0.5.1 (Jun 24, 2016)

New features:
  * Added subcommands #init to initialize deployment application/service profiles

Minor enhancements:
  * Added .gitignore file to the deployment project skeleton

## Version 0.5.0 (Jun 22, 2016)

New features:
  * Added a series of subcommands, #init to
    * Initialize a Luban deployment project
    * Initialize a Luban deployment application
    * Initialize a Luban deployment service
  * Added deployment project and application skeleton and templates

Bug fixes:
  * Corrected the checking for profile existence for a deployment application/service

## Version 0.4.4 (Jun 17, 2016)

Bug fixes:
  * Made #decompose_version to be a class method in order to correctly decompose version for dependent/child packages like PCRE

## Version 0.4.3 (Jun 16, 2016)

Minor enhancements:
  * Changed #default_executable to #define_executable with a better general approach
  * Refactored start/stop/monitor/unmonitor into corresponding commands for better reusability
  * Added convenient methods, #default_pending_seconds and # default_pending_interval
    * These two methods provided a better way to customize timging for process status check
  * Refactored header information into a generic header template for all erb template files

Bug fixes:
  * Fixed monitor/unmonitor timing for start/stop operations
  * Checked process status before killing process

## Version 0.4.2 (Jun 07, 2016)

Minor enhancements:
  * Enhanced process management in controller
  * Added parameters #process_monitor to setup process monitor in Luban
  * Added #process_monitor_via convenient method to setup process monitor in Luban
  * Removed #monitor_process and #unmonitor_process from common control tasks
  * Added option #configure_opts for package installation
  * Optimized format result output message
  * Added convenient methods #env_name and #service_name to standardize naming
  * Minor code refactoring

Bug fixes:
  * Fixed SSHKit output format to handle :airbrussh properly

## Version 0.4.1 (May 13, 2016)

Minor enhancements:
  * Optimized overriding dependent package version thru command-line options
  * Added command-line option to specify OpenSSL version for Git and Ruby
  * Used system default package if the given required package version is "default"

## Version 0.4.0 (May 11, 2016)

Minor enhancements:
  * Upgraded Bundler for Ruby to version 1.12.3
  * Used OpenSSL ftp site to download its source code package
  * Optimized md5 signature generation for both source code package as well as gems downloaded

Bug fixes:
  * Fixed a bug in md5 calculation for a given file
  * Fixed broken installer for Bundler

## Version 0.3.6 (May 09, 2016)

Minor enhancements:
  * Upgraded OpenSSL to 1.0.2h for Git installer
  * Upgraded OpenSSL to 1.0.2h for Ruby installer

## Version 0.3.5 (May 06, 2016)

New features:
  * Created Luban::Deployment::Service::Base to handle service package deployment
  * Added logrotate support
  * Generated profile locally before publishing to remote servers for a given service package

Minor enhancements:
  * Renamed Luban::Deployment::Package::Binary to Luban::Deployment::Package::Base for clarity
  * Added convenient class method #default_executable to define executable method for a given package
  * Minor code refactoring and cleanup

Bug fixes:
  * Fixed a bug in md5 calculation on a given folder

## Version 0.3.3 (Apr 18, 2016)

Bug fixes:
  * Properly handled running luban command-line out of any Luban projects
  * Skip bundling if no gems to be bundled

## Version 0.3.2 (Apr 15, 2016)

Minor enhancements:
  * Revised envrc and unset_envrc resource files
  * Refactored promptless authen and environment bootstrap to task #setup from task #build

Bug fixes:
  * Made required package current one to use in order to ensure proper binstubs generation
  * Fixed revision calculation

## Version 0.3.1 (Apr 13, 2016)

Minor enhancements:
  * Added SSH auth method "password" in addition to "keyboard-interactive"
  * Removed support for production stages

Bug fixes:
  * Ensured pakcage tmp path is created during bootstrapping
  * Built package without setting up build environment varaibles which are problematic
  * Checked third-party package download correctly with MD5

## Version 0.3.0 (Apr 12, 2016)

Minor enhancements:
  * Changed to download third-party source packages locally to save internet access from app servers
  * Refactored remote and local worker paths
  * Moved build repositories to the last building step
  * Fixed wrong clone path when fetching revision in Rsync strategy
  * Upgrade OpenSSL to 1.0.2g for Git installer
  * Code cleanup

## Version 0.2.0 (Apr 01, 2016)

Bug fixes:
  * Removed util method, #md5_for_dir, due to inconsistent hash
  * Upgrade OpenSSL to 1.0.2g for Ruby installer
  * Code cleanup

## Version 0.1.0 (Mar 31, 2016)

New features:
  * Configuration DSL to support environment setup
  * Command-line interface to run Luban project
  * Installer to install 3rd-party software packages
    * OpenSSL installer
    * YAML installer
    * Git installer
    * Ruby installer
    * Rubygems installer
    * Bundler installer
  * Authenticator to setup passwordless SSH to application servers
  * Builder to setup application environment
  * Repository to manage application source and profile 
    * SCM strategy for Git
    * SCM strategy for Rsync
  * Publisher to deploy application release
