#
# Cookbook Name:: runit
# Recipe:: default
#
# Copyright 2008-2010, Opscode, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

case node[:platform]
when "debian","ubuntu", "gentoo"
  execute "start-runsvdir" do
    command value_for_platform(
      "debian" => { "default" => "runsvdir-start" },
      "ubuntu" => { "default" => "start runsvdir" },
      "gentoo" => { "default" => "/etc/init.d/runit-start start" }
    )
    action :nothing
  end

  execute "runit-hup-init" do
    command "telinit q"
    only_if "grep ^SV /etc/inittab"
    action :nothing
  end

  if platform? "gentoo"
    template "/etc/init.d/runit-start" do
      source "runit-start.sh.erb"
      mode 0755
    end
  end

  package "runit" do
    action :install
    if platform?("ubuntu", "debian")
      response_file "runit.seed"
    end
    notifies value_for_platform(
      "debian" => { "4.0" => :run, "default" => :nothing  },
      "ubuntu" => {
        "default" => :nothing,
        "9.04" => :run,
        "8.10" => :run,
        "8.04" => :run },
      "gentoo" => { "default" => :run }
    ), resources(:execute => "start-runsvdir"), :immediately
    notifies value_for_platform(
      "debian" => { "squeeze/sid" => :run, "default" => :nothing },
      "default" => :nothing
    ), resources(:execute => "runit-hup-init"), :immediately
  end

  if node[:platform] =~ /ubuntu/i && node[:platform_version].to_f <= 8.04
    cookbook_file "/etc/event.d/runsvdir" do
      source "runsvdir"
      mode 0644
      notifies :run, resources(:execute => "start-runsvdir"), :immediately
      only_if do ::File.directory?("/etc/event.d") end
    end
  end


when "redhat"
  # I couldn't find any runit packages for RHEL 6, at first... The closest I found were...
  # http://linsec.ca/blog/2010/04/07/runit-and-supervised-services-on-rhelcentos-5/ /
  #   http://repo.annvix.org/media/EL5/x86_64/runit-2.1.1-4.el5.avx.x86_64.rpm -- For RHEL5, not 6
  # http://rpmfind.net/linux/rpm2html/search.php?query=runit -- for Mandriva

  #---------------------------------------------------------------------------------------------------
  # This was my attempt at installing from source, which worked just fine, but I didn't get to testing the upstart init script...
#  version = "2.1.1"
#  filename_gz = "runit-#{version}.tar.gz"
#
#  remote_file "#{Chef::Config[:file_cache_path]}/#{filename_gz}" do
#    source "http://smarden.org/runit/#{filename_gz}"
#    #checksum node['runit']['checksum']
#    #mode 0644
#    action :create_if_missing
#  end
#
#  package 'glibc-static'
#
#  bash "build runit from source" do
#    cwd Chef::Config[:file_cache_path]
#    code <<-End
#    set -o errexit
#    tar zxvf #{filename_gz}
#    cd admin/runit-#{version}
#    package/install
#    package/install-man
#    End
#    not_if { ::File.exists?(node[:runit][:sv_bin]) }
#  end
#
#  directory "/etc/service"
#  directory "/etc/sv"
#
#  # By looking at dpkg --listfiles runit and reading that RHEL6 uses upstart, just like ubuntu,
#  # I figured out that I also need to create these files:
#  # file "/etc/event.d/runsvdir"
#  # file "/etc/init/runsvdir.conf"
#  # and (according to the ubuntu package's DEBIAN/postinst) run:
#  #   /sbin/start runsvdir
#  #

  #---------------------------------------------------------------------------------------------------
  # Then I ran across https://github.com/imeyer/runit-rpm, which appeared to be an runit package for
  # RHEL 6... well, actually, it was simply a script to create the rpm, not the rpm itself.
  #
  # By running:
  #   rpm -qpil /home/tyler/rpmbuild/RPMS/x86_64/runit-2.1.1-6.el6.x86_64.rpm|less
  # I found out where it installed its executables to (/sbin).
  #
  # By running:
  #   rpm -qp --scripts /home/tyler/rpmbuild/RPMS/x86_64/runit-2.1.1-6.el6.x86_64.rpm|less
  # I confirmed that it did know about upstart and did execute 'start runsvdir'.
  # I also confirmed that it wasn't going to attempt to *replace* any existing init system.
  #
  # I don't know how to create an actual RPM repository, so for now I'll just install directly with rpm
  # command...

  filename = "runit-2.1.1-6.el6.x86_64.rpm"
  not_if_block = lambda { ::File.exists?(node[:runit][:sv_bin]) }
  remote_file "#{Chef::Config[:file_cache_path]}/#{filename}" do
    source "https://github.com/TylerRick/runit-rpm/raw/master/packages/#{filename}"
    action :create
    not_if &not_if_block
  end

  execute "rpm -i #{filename}" do
    cwd Chef::Config[:file_cache_path]
    not_if &not_if_block
  end

else
  Chef::Log.warn("Don't know how to install runit on platform '#{platform}'")
end
