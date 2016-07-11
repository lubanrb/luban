# Change log

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
