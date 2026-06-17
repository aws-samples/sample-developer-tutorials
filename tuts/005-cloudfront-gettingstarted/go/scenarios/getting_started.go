// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

package main

import (
	"context"
	"fmt"
	"github.com/aws/aws-sdk-go-v2/config"
	aws_cloudfront "github.com/aws/aws-sdk-go-v2/service/cloudfront"
)

func main() {
	cfg, _ := config.LoadDefaultConfig(context.TODO())
	client := aws_cloudfront.NewFromConfig(cfg)
	_ = client
	fmt.Println("Running CloudFront getting started scenario...")
	// TODO: setup, interact, teardown
}
