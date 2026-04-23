# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

require_relative 'cloudfront_wrapper'

def run_scenario
  client = Aws::CloudFront::Client.new
  wrapper = CloudFrontWrapper.new(client)
  puts "Running CloudFront getting started scenario..."
  # TODO: setup, interact, teardown
  puts "Scenario complete."
end

run_scenario if __FILE__ == $PROGRAM_NAME
