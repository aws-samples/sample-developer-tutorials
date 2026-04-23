# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

require_relative 'ec2_wrapper'

def run_scenario
  client = Aws::Ec2::Client.new
  wrapper = Ec2Wrapper.new(client)
  puts "Running Ec2 getting started scenario..."
  # TODO: setup, interact, teardown
  puts "Scenario complete."
end

run_scenario if __FILE__ == $PROGRAM_NAME
