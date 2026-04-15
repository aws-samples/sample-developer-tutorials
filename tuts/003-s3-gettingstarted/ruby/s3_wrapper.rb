# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

require 'aws-sdk-s3'
require 'logger'

class S3Wrapper
  def initialize(client, logger: Logger.new($stdout))
    @client = client
    @logger = logger
  end

  # TODO: Add wrapper methods matching CLI tutorial actions
end
