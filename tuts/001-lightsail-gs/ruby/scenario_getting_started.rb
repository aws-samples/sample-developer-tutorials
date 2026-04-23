# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

require_relative 'lightsail_wrapper'

def run_scenario
  client = Aws::Lightsail::Client.new
  wrapper = LightsailWrapper.new(client)
  puts "Running Lightsail getting started scenario..."
  # TODO: setup, interact, teardown
  puts "Scenario complete."
end

run_scenario if __FILE__ == $PROGRAM_NAME
