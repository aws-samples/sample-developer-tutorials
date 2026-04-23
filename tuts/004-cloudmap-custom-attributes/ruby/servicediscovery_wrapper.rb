# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

require 'aws-sdk-servicediscovery'
require 'logger'

class CloudMapWrapper
  def initialize(client, logger: Logger.new($stdout))
    @client = client
    @logger = logger
  end

  # TODO: Add wrapper methods matching CLI tutorial actions
end
