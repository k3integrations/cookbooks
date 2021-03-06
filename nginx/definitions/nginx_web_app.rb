#
# Cookbook Name:: nginx
# Definition:: nginx_web_app
#
# Copyright 2008-2009, Opscode, Inc.
# Copyright 2012, K3 Integrations, LLC
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

# Based on apache2/definitions/web_app.rb

define :nginx_web_app, :template => "web_app.conf.erb", :enable => true, :app => nil do

  # This is necessary so that we can refer to the 'nginx' resource without
  # having to load the nginx::default recipe (which we might not want to do if
  # are run_list is for simply deploying an app rather than configuring the
  # entire server).
  service "nginx" do
    supports :status => true, :restart => true, :reload => true
    action [ :enable, :start ]
  end
  
  name = params[:name]

  path = "#{node[:nginx][:dir]}/sites-available/#{name}"
  template path do
    #source "default-site.erb"
    source params[:template]
    owner "root"
    group "root"
    mode 0644
    variables(
      :app => params[:app],
      :name => name,
      :params => params
    )
    if ::File.exists?(path)
      notifies :reload, resources(:service => "nginx"), :delayed
    end
  end
  
  nginx_site name do
    enable params[:enable]
  end
end
