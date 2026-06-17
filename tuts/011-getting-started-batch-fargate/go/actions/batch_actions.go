// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

package actions

import (
	"context"
	"log"
	aws_batch "github.com/aws/aws-sdk-go-v2/service/batch"
)

type BatchActions struct {
	Client *aws_batch.Client
}

// TODO: Add action methods matching CLI tutorial
