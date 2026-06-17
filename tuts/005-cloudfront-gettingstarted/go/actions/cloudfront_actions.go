// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

package actions

import (
	"context"
	"log"
	aws_cloudfront "github.com/aws/aws-sdk-go-v2/service/cloudfront"
)

type CloudFrontActions struct {
	Client *aws_cloudfront.Client
}

// TODO: Add action methods matching CLI tutorial
