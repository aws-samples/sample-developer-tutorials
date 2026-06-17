// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

package actions

import (
	"context"
	"log"
	aws_s3 "github.com/aws/aws-sdk-go-v2/service/s3"
)

type S3Actions struct {
	Client *aws_s3.Client
}

// TODO: Add action methods matching CLI tutorial
