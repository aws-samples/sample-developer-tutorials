// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

package actions

import (
	"context"
	"log"
	aws_lightsail "github.com/aws/aws-sdk-go-v2/service/lightsail"
)

type LightsailActions struct {
	Client *aws_lightsail.Client
}

// TODO: Add action methods matching CLI tutorial
