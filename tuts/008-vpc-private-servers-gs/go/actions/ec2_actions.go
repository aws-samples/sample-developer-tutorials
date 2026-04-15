// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

package actions

import (
	"context"
	"log"
	aws_ec2 "github.com/aws/aws-sdk-go-v2/service/ec2"
)

type Ec2Actions struct {
	Client *aws_ec2.Client
}

// TODO: Add action methods matching CLI tutorial
