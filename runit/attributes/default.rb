#
# Cookbook Name:: runit
# Attribute File:: sv_bin
#
# Copyright 2008-2009, Opscode, Inc.
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

set[:runit][:service_dir] = "/etc/service"
set[:runit][:sv_dir]      = "/etc/sv"

case platform
when "redhat"
  # If installed from source...
  # Installing from source installs commands to /usr/local/bin/
  #set[:runit][:sv_bin]    = "/usr/local/bin/sv"
  #set[:runit][:chpst_bin] = "/usr/local/bin/chpst"

  set[:runit][:sv_bin]    = "/sbin/sv"
  set[:runit][:chpst_bin] = "/sbin/chpst"

else
  set[:runit][:sv_bin]    = "/usr/bin/sv"
  set[:runit][:chpst_bin] = "/usr/bin/chpst"
end
