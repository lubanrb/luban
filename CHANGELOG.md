# Change log

## Version 0.3.2 (Apr 15, 2016)

Minor enhancements:
  * Revised envrc and unset_envrc resource files
  * Refactored promptless authen and environment bootstrap to task #setup from task #build

Bug fixes:
  * Made required package current one to use in order to ensure proper binstubs generation
  * Fixed revision calculation

## Version 0.3.1 (Apr 13, 2016)

Minor enhancements:
  * Add SSH auth method "password" in addition to "keyboard-interactive"
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
