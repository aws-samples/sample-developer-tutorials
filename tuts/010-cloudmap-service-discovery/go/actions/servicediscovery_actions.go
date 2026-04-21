// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

package actions

import (
	"context"
	"log"
	aws_servicediscovery "github.com/aws/aws-sdk-go-v2/service/servicediscovery"
)

type CloudMapActions struct {
	Client *aws_servicediscovery.Client
}

// TODO: Add action methods matching CLI tutorial
