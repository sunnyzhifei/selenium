# frozen_string_literal: true

# Licensed to the Software Freedom Conservancy (SFC) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The SFC licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

module Selenium
  module WebDriver
    module Chrome

      #
      # Driver implementation for Chrome.
      # @api private
      #

      class Driver < WebDriver::Driver
        include DriverExtensions::HasNetworkConditions
        include DriverExtensions::HasWebStorage
        include DriverExtensions::HasLocation
        include DriverExtensions::TakesScreenshot
        include DriverExtensions::DownloadsFiles

        def initialize(opts = {})
          opts[:desired_capabilities] = create_capabilities(opts)

          opts[:url] ||= service_url(opts)

          listener = opts.delete(:listener)
          desired_capabilities = opts.delete(:desired_capabilities)

          @bridge = Remote::Bridge.new(opts)
          @bridge.extend Bridge
          @bridge.create_session(desired_capabilities)

          super(@bridge, listener: listener)
        end

        def browser
          :chrome
        end

        def quit
          super
        ensure
          @service&.stop
        end

        def execute_cdp(cmd, **params)
          @bridge.send_command(cmd: cmd, params: params)
        end

        private

        def create_capabilities(opts)
          caps = opts.delete(:desired_capabilities) { Remote::Capabilities.chrome }
          options = opts.delete(:options) { Options.new }

          profile = opts.delete(:profile)
          if profile
            profile = profile.as_json

            options.add_argument("--user-data-dir=#{profile[:directory]}") if options.args.none?(&/user-data-dir/.method(:match?))

            if profile[:extensions]
              WebDriver.logger.deprecate 'Using Selenium::WebDriver::Chrome::Profile#extensions',
                                         'Selenium::WebDriver::Chrome::Options#add_extension'
              profile[:extensions].each do |extension|
                options.add_encoded_extension(extension)
              end
            end
          end

          detach = opts.delete(:detach)
          options.add_option(:detach, true) if detach

          options = options.as_json
          caps.merge!(options) unless options[Options::KEY].empty?

          caps[:proxy] = opts.delete(:proxy) if opts.key?(:proxy)
          caps[:proxy] ||= opts.delete('proxy') if opts.key?('proxy')

          caps
        end
      end # Driver
    end # Chrome
  end # WebDriver
end # Selenium
