# Copyright 2021 The Sigstore Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'rubygems/command_manager'
require "rubygems/sigstore/config"
require 'rubygems/sigstore/options'

Gem::CommandManager.instance.register_command :sign

# overde the generic gem build command to lay are own --sign option on top
b = Gem::CommandManager.instance[:build]
b.add_option("--sign", "Sign gem with sigstore.") do |value, options|
  Gem::Sigstore.options[:sign] = true
end

class Gem::Commands::BuildCommand
  alias_method :original_execute, :execute
  def execute
    
    config = SigStoreConfig.new().config
    
    if Gem::Sigstore.options[:sign]
        puts "sign called"
    end
    # original_execute calls the native command
    original_execute
  end
end
