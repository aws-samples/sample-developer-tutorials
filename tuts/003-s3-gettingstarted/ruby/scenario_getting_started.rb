# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

require_relative 's3_wrapper'

def run_scenario
  client = Aws::S3::Client.new
  wrapper = S3Wrapper.new(client)
  puts "Running S3 getting started scenario..."
  # TODO: setup, interact, teardown
  puts "Scenario complete."
end

run_scenario if __FILE__ == $PROGRAM_NAME
