# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

require_relative '../lightsail_wrapper'

RSpec.describe LightsailWrapper do
  let(:client) { Aws::Lightsail::Client.new(stub_responses: true) }
  let(:wrapper) { described_class.new(client) }

  it 'creates wrapper' do
    expect(wrapper).not_to be_nil
  end
end
