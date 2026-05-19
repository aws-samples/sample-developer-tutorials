#!/bin/bash
set -e

cleanup_resources() {
    for resource in "${CREATED_RESOURCES[@]}"; do
        case "$resource" in
            "component:"*)
                component_id="${resource#*:}"
                echo "Deleting component $component_id"
                aws proton delete-component --name "$component_id" || true
                ;;
            "environment:"*)
                environment_id="${resource#*:}"
                echo "Deleting environment $environment_id"
                aws proton delete-environment --name "$environment_id" || true
                ;;
            "environment-account-connection:"*)
                environment_account_connection_id="${resource#*:}"
                echo "Deleting environment account connection $environment_account_connection_id"
                aws proton delete-environment-account-connection --id "$environment_account_connection_id" || true
                ;;
            "environment-template:"*)
                environment_template_id="${resource#*:}"
                echo "Deleting environment template $environment_template_id"
                aws proton delete-environment-template --name "$environment_template_id" || true
                ;;
            "environment-template-version:"*)
                environment_template_version_id="${resource#*:}"
                environment_template_name="${environment_template_version_id%:*}"
                version="${environment_template_version_id##*:}"
                echo "Deleting environment template version $version of $environment_template_name"
                aws proton delete-environment-template-version --template-name "$environment_template_name" --major-version "$version" || true
                ;;
        esac
    done
}

trap cleanup_resources EXIT

SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)
TEMP_DIR=$(mktemp -d)
CREATED_RESOURCES=()

echo "Creating an environment template..."
ENVIRONMENT_TEMPLATE_NAME="template-$SUFFIX"
ENVIRONMENT_TEMPLATE_ID=$(aws proton create-environment-template --name "$ENVIRONMENT_TEMPLATE_NAME" --display-name "Template $SUFFIX" --description "Environment template for tutorial" --tags '{"Purpose":"Tutorial","CreatedBy":"Script"}' --query 'template.name' --output text)
CREATED_RESOURCES+=("environment-template:$ENVIRONMENT_TEMPLATE_ID")

echo "Creating an environment template version..."
ENVIRONMENT_TEMPLATE_VERSION="1"
ENVIRONMENT_TEMPLATE_VERSION_ID="$ENVIRONMENT_TEMPLATE_NAME:$ENVIRONMENT_TEMPLATE_VERSION"
aws proton create-environment-template-version --template-name "$ENVIRONMENT_TEMPLATE_NAME" --major-version "$ENVIRONMENT_TEMPLATE_VERSION" --source-branch '{"branchName":"main","directory":"environment"}' --query 'templateVersion.templateName' --output text
CREATED_RESOURCES+=("environment-template-version:$ENVIRONMENT_TEMPLATE_VERSION_ID")

echo "Creating an environment..."
ENVIRONMENT_NAME="environment-$SUFFIX"
ENVIRONMENT_ID=$(aws proton create-environment --name "$ENVIRONMENT_NAME" --template-name "$ENVIRONMENT_TEMPLATE_NAME" --template-major-version "$ENVIRONMENT_TEMPLATE_VERSION" --spec "$TEMP_DIR/environment-spec.yaml" --tags '{"EnvironmentType":"Tutorial","CreatedBy":"Script"}' --query 'environment.name' --output text)
CREATED_RESOURCES+=("environment:$ENVIRONMENT_ID")

echo "Creating a component..."
COMPONENT_NAME="component-$SUFFIX"
COMPONENT_ID=$(aws proton create-component --name "$COMPONENT_NAME" --environment-name "$ENVIRONMENT_NAME" --template-file "$TEMP_DIR/component-template.yaml" --tags '{"ComponentType":"Tutorial","CreatedBy":"Script"}' --query 'component.name' --output text)
CREATED_RESOURCES+=("component:$COMPONENT_ID")

echo "PASS"
