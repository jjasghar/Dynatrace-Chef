#
# Cookbook Name:: dynatrace
# Recipes:: host_agent
#
# Copyright 2016, Dynatrace
#

name = 'Host Agent'
include_recipe 'dynatrace::upgrade_system'
include_recipe 'dynatrace::prerequisites'
include_recipe 'dynatrace::dynatrace_user'
could_be_installed = false

#determine source tar file to execute
node_kernel_machine = node['kernel']['machine']       # "x86_64"
if platform_family?('rhel') and node_kernel_machine == 'x86_64'
	if node['host_agent']['installer']['bitsize'] == '64'
		#the only platform for which we are able to test this recipe
		could_be_installed = true
	end
  # Currently only tested on linux-x86 platform but there are many more e.g.
  # 'aix-ppc', 'hpux-ia64', 'linux-ppc', 'linux-s390', 'linux-s390x', 'solaris-sparc', 'solaris-x86'
else
	# Unsupported
	puts 'Unsupported platform yet'
end


installer_prefix_dir = node['dynatrace']['host_agent']['installer']['prefix_dir']
installer_file_url   = node['dynatrace']['host_agent']['installer']['file_url']
installer_file_name  = node['dynatrace']['host_agent']['installer']['file_name']
installer_cache_dir = "#{Chef::Config['file_cache_path']}/host_agent"
installer_path      = "#{installer_cache_dir}/#{installer_file_name}"
dynatrace_owner = node['dynatrace']['owner']
dynatrace_group = node['dynatrace']['group']
host_agent_name = node['dynatrace']['host_agent']['host_agent_name']
host_agent_collector = node['dynatrace']['host_agent']['collector']

#if could_be_installed
#  #verification if Host Agent is already installed
#  fileExists = "/etc/init.d/dynaTraceHostagent"
#  if File.exist?(fileExists)
#    # cannot install host_agent because is alredy installed
#	puts 'Host Agent file' + fileExists + ' exists. Host Agent will not be installed. Run host_agent_uninstall recipe first. Be careful - you will lost your configuration.'
#	could_be_installed = false
#  end
#end

if could_be_installed
  if could_be_installed
    #verification if Host Agent is already installed
    fileExists = "/etc/init.d/dynaTraceHostagent"
    if File.exist?(fileExists)
      # Host Agent is already installed
      puts 'Host Agent file' + fileExists + ' exists. Host Agent will override existing installation.'
    end
  end
  
  fileExists = "#{installer_prefix_dir}/dynatrace/agent/conf/dthostagent.ini"
  if File.exist?(fileExists)
    # Host Agent is already installed
    puts 'Host Agent configuration file' + fileExists + ' exists. It will be renamed to ' + fileExists  + '_backup before installation.'
    ruby_block "Rename file #{fileExists} to #{fileExists}_backup" do
      block do
        ::File.rename(fileExists,fileExists + '_backup')
      end
    end
  else
    puts 'Host Agent configuration file' + fileExists + ' do not exists.'
  end
  

	puts 'Initializing directories'
	#creating tmp installer directory
	directory "Create temporrary installer cache directory: #{installer_cache_dir}" do
	  path   installer_cache_dir
	  action :create
	end
		
  puts 'Create user group: ' + dynatrace_group
  group dynatrace_group do
    action :create
    append true
  end
  
  puts 'Create user: ' + dynatrace_owner
  user dynatrace_owner do
    gid dynatrace_group
    supports :manage_home => true
    home "/home/#{dynatrace_owner}"
    shell "/bin/bash"
    system true
  end	

  puts 'download installation tar file'
	dynatrace_copy_or_download_file "Downloading installation tar file: #{installer_file_name}" do
	  file_name       installer_file_name
	  file_url        installer_file_url  
	  path            installer_path
	  dynatrace_owner dynatrace_owner
	  dynatrace_group dynatrace_group
	end

	#creating installation directory. It usually exists, default is /opt
	directory "Create the installation directory #{installer_prefix_dir}" do
	  path      installer_prefix_dir
	  owner     dynatrace_owner unless ::File.exist?(installer_prefix_dir)
	  group     dynatrace_group unless ::File.exist?(installer_prefix_dir)
	  recursive true
	  action    :create
	end

	#perform installation of host_agent
	dynatrace_run_tar_installer_for_hostagent "Installing #{name}" do
		installer_prefix_dir installer_prefix_dir
		installer_path       installer_path
		dynatrace_owner      dynatrace_owner
		dynatrace_group      dynatrace_group
		host_agent_name 	 host_agent_name
		host_agent_collector host_agent_collector
	end
end

