# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

require_relative '../cloudfront_wrapper'

RSpec.describe CloudFrontWrapper do
  let(:client) { Aws::CloudFront::Client.new(stub_responses: true) }
  let(:wrapper) { described_class.new(client) }

  it 'creates wrapper' do
    expect(wrapper).not_to be_nil
  end
end
