# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

require_relative '../ec2_wrapper'

RSpec.describe Ec2Wrapper do
  let(:client) { Aws::Ec2::Client.new(stub_responses: true) }
  let(:wrapper) { described_class.new(client) }

  it 'creates wrapper' do
    expect(wrapper).not_to be_nil
  end
end
