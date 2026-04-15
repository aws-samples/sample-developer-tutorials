// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

package main

import (
	"context"
	"fmt"
	"github.com/aws/aws-sdk-go-v2/config"
	aws_ec2 "github.com/aws/aws-sdk-go-v2/service/ec2"
)

func main() {
	cfg, _ := config.LoadDefaultConfig(context.TODO())
	client := aws_ec2.NewFromConfig(cfg)
	_ = client
	fmt.Println("Running Ec2 getting started scenario...")
	// TODO: setup, interact, teardown
}
