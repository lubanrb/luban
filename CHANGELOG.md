# Change log

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
