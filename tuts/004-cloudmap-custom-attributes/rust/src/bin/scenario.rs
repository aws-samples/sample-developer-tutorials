// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let config = aws_config::load_defaults(aws_config::BehaviorVersion::latest()).await;
    let client = aws_sdk_servicediscovery::Client::new(&config);
    println!("Running CloudMap getting started scenario...");
    // TODO: setup, interact, teardown
    let _ = client;
    println!("Scenario complete.");
    Ok(())
}
