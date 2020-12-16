# frozen_string_literal: true

#
# Type for interfacing with IBM's Installation Manager.  See the 'imcl'
# provider for more detailed notes.
#
# Basically, we could almost make a package provider for this instead, but we
# need to be able to support all sorts of scenarios that I'm not sure the
# package resource supports.  We can install the same version multiple times
# on a system, for instance, but to different paths.  The source is also
# tricky.  The source is a massive download from IBM that's extracted in a
# certain way.  It includes a 'repository.config' file that the
# Installation Manager tool parses for details on what software is available
# to be installed.
#
require 'pathname'
require 'puppet/parameter/boolean'

Puppet::Type.newtype(:ibm_pkg) do
  desc 'Custom type for installing an IBM package.'

  autorequire(:file) do
    self[:target]
  end

  autorequire(:user) do
    self[:package_owner]
  end

  autorequire(:group) do
    self[:package_group]
  end

  autorequire(:exec) do
    'Install IBM Installation Manager'
  end

  validate do
    if catalog
      unless self[:response]
        raise('target is required when a response file is not provided') if self[:target].nil?
        raise('package is required when a response file is not provided') if self[:package].nil?
        raise('version is required when a response file is not provided') if self[:version].nil?
        raise('repository is required when a response file is not provided') if self[:repository].nil?
      end

      raise("Invalid user #{self[:user]}") unless :user =~ %r{^[0-9A-Za-z_-]+$}

      [:imcl_path, :target, :response].each do |value|
        if self[value]
          raise("#{value} must be an absolute path: #{self[value]}") unless Pathname.new(self[value]).absolute?
        end
      end
    end
  end

  ensurable

  newparam(:name, namevar: true) do
    desc 'An arbitrary name to identify the resource.'
  end

  newparam(:jdk_package_name) do
    desc 'If a JDK must be installed separately (as in the case of Websphere Application Server 9), specify the package_name here (everything before the underscore in the IBM package name).'
  end

  newparam(:jdk_package_version) do
    desc "If a JDK must be installed separately (as in the case of Websphere Application Server 9), specify the version here.
    Like 'version', this parameter refers to the number after the underscore in the IBM package name."
  end

  newparam(:imcl_path) do
    desc "The full path to the imcl executable.
    This is optional. The provider will attempt to locate imcl by parsing /<appDataLocation>/InstallationManager/installed.xml.
    If, for some reason, it cannot be discovered or if you need to provide a specific path, you may do so with this parameter."
  end

  newparam(:target) do
    desc "The full path to install the specified package to. Corresponds to the 'imcl' option '-installationDirectory'."
  end

  newparam(:package) do
    desc "The IBM package name. Example: com.ibm.websphere.IBMJAVA.v71
    This is the first part of the traditional IBM full package name, before the first underscore."

    ## How to best validate this? Are package names consistent?
  end

  newparam(:repository) do
    desc "The full path to the 'repository.config' file for installing this package."
  end

  newparam(:response) do
    desc 'Full path to an optional response file to use. The user is responsible for ensuring this file is present.'
  end

  newparam(:version) do
    desc "The version of the package. Example: 7.1.2000.20141116_0823
    This is the second part of the traditional IBM full package name, after the first underscore."

    ## How to best validate this?  Is the versioning consistent?
  end

  newparam(:options) do
    desc "Any custom options to pass to the 'imcl' tool for installing the package."
  end

  newparam(:user) do
    desc "The user to run the 'imcl' command as."
    defaultto 'root'
  end

  newparam(:manage_ownership, boolean: true, parent: Puppet::Parameter::Boolean) do
    desc 'Whether or not to manage the ownership of installed packages. Allows for packages to not be installed as root.'
    defaultto true
  end

  newparam(:package_owner) do
    desc 'The user that should own this package installation. Only used if manage_ownership is true.'
    defaultto 'root'
  end

  newparam(:package_group) do
    desc 'The group that should own this package installation. Only used if manage_ownership is true.'
    defaultto 'root'
  end
end
