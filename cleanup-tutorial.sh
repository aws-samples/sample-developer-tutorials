#!/bin/bash
# cleanup-tutorial.sh — Find and clean up resources created by a tutorial
#
# Usage:
#   bash cleanup-tutorial.sh                    # List all tutorial resources
#   bash cleanup-tutorial.sh --tutorial 043     # List resources for tutorial 043
#   bash cleanup-tutorial.sh --delete           # Delete all tutorial resources
#   bash cleanup-tutorial.sh --delete --tutorial 043  # Delete resources for tutorial 043
#
# Resources are identified by the tag: project=doc-smith, tutorial={id}
# Untagged resources are identified by naming patterns (tutorial-*, mq-broker-*, etc.)

set -uo pipefail

DELETE=false
TUTORIAL_FILTER=""
REGION="${AWS_REGION:-$(aws configure get region 2>/dev/null || echo us-west-2)}"

while [[ $# -gt 0 ]]; do
    case $1 in
        --delete) DELETE=true; shift ;;
        --tutorial) TUTORIAL_FILTER="$2"; shift 2 ;;
        --region) REGION="$2"; shift 2 ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

FOUND=0
DELETED=0

found() {
    local type=$1 id=$2 name=$3 tutorial=$4 cost=$5
    FOUND=$((FOUND+1))
    if $DELETE; then
        printf "  🗑️  %-20s %-40s %s\n" "$type" "$id" "$name"
    else
        printf "  %-20s %-40s %-30s %-20s %s\n" "$type" "$id" "$name" "$tutorial" "$cost"
    fi
}

delete_resource() {
    local type=$1 id=$2
    if ! $DELETE; then return; fi
    DELETED=$((DELETED+1))
    case $type in
        mq-broker)
            aws mq delete-broker --broker-id "$id" --region "$REGION" --output text 2>/dev/null ;;
        opensearch-domain)
            aws opensearch delete-domain --domain-name "$id" --region "$REGION" --output text 2>/dev/null > /dev/null ;;
        msk-cluster)
            aws kafka delete-cluster --cluster-arn "$id" --region "$REGION" --output text 2>/dev/null ;;
        rds-instance)
            aws rds delete-db-instance --db-instance-identifier "$id" --skip-final-snapshot --delete-automated-backups --region "$REGION" --output text 2>/dev/null > /dev/null ;;
        rds-cluster)
            aws rds delete-db-cluster --db-cluster-identifier "$id" --skip-final-snapshot --region "$REGION" --output text 2>/dev/null > /dev/null ;;
        rds-subnet-group)
            aws rds delete-db-subnet-group --db-subnet-group-name "$id" --region "$REGION" 2>/dev/null ;;
        docdb-instance)
            aws docdb delete-db-instance --db-instance-identifier "$id" --region "$REGION" --output text 2>/dev/null > /dev/null ;;
        docdb-cluster)
            aws docdb delete-db-cluster --db-cluster-identifier "$id" --skip-final-snapshot --region "$REGION" --output text 2>/dev/null > /dev/null ;;
        neptune-instance)
            aws neptune delete-db-instance --db-instance-identifier "$id" --region "$REGION" --output text 2>/dev/null > /dev/null ;;
        neptune-cluster)
            aws neptune delete-db-cluster --db-cluster-identifier "$id" --skip-final-snapshot --region "$REGION" --output text 2>/dev/null > /dev/null ;;
        elasticache)
            aws elasticache delete-serverless-cache --serverless-cache-name "$id" --region "$REGION" --output text 2>/dev/null > /dev/null ;;
        redshift-serverless-wg)
            aws redshift-serverless delete-workgroup --workgroup-name "$id" --region "$REGION" --output text 2>/dev/null > /dev/null ;;
        redshift-serverless-ns)
            aws redshift-serverless delete-namespace --namespace-name "$id" --region "$REGION" --output text 2>/dev/null > /dev/null ;;
        redshift-cluster)
            aws redshift delete-cluster --cluster-identifier "$id" --skip-final-cluster-snapshot --region "$REGION" --output text 2>/dev/null > /dev/null ;;
        emr-cluster)
            aws emr terminate-clusters --cluster-ids "$id" --region "$REGION" 2>/dev/null ;;
        ecs-service)
            local cluster=$(echo "$id" | cut -d/ -f1)
            local svc=$(echo "$id" | cut -d/ -f2)
            aws ecs update-service --cluster "$cluster" --service "$svc" --desired-count 0 --region "$REGION" --no-cli-pager 2>/dev/null > /dev/null
            aws ecs delete-service --cluster "$cluster" --service "$svc" --force --region "$REGION" --no-cli-pager 2>/dev/null > /dev/null ;;
        ecs-cluster)
            aws ecs delete-cluster --cluster "$id" --region "$REGION" --output text 2>/dev/null > /dev/null ;;
        network-firewall)
            aws network-firewall delete-firewall --firewall-name "$id" --region "$REGION" --output text 2>/dev/null > /dev/null ;;
        vpc-lattice-service)
            aws vpc-lattice delete-service --service-identifier "$id" --region "$REGION" --output text 2>/dev/null > /dev/null ;;
        dms-instance)
            aws dms delete-replication-instance --replication-instance-arn "$id" --region "$REGION" --output text 2>/dev/null > /dev/null ;;
        qbusiness-app)
            aws qbusiness delete-application --application-id "$id" --region us-east-1 2>/dev/null ;;
    esac
}

match_tutorial() {
    local tutorial=$1
    [ -z "$TUTORIAL_FILTER" ] && return 0
    [[ "$tutorial" == *"$TUTORIAL_FILTER"* ]] && return 0
    return 1
}

echo "Scanning $REGION for tutorial resources..."
$DELETE || printf "  %-20s %-40s %-30s %-20s %s\n" "TYPE" "ID" "NAME" "TUTORIAL" "COST"
$DELETE || echo "  $(printf '%.0s-' {1..130})"

# --- MQ Brokers ---
while IFS=$'\t' read -r bid bname bstate; do
    [ -z "$bid" ] && continue
    tags=$(aws mq describe-broker --broker-id "$bid" --region "$REGION" --query 'Tags' --output json 2>/dev/null)
    tutorial=$(echo "$tags" | python3 -c "import sys,json; t=json.load(sys.stdin) or {}; print(t.get('tutorial',''))" 2>/dev/null)
    match_tutorial "$tutorial" || continue
    found "mq-broker" "$bid" "$bname" "${tutorial:-untagged}" "~\$0.20/hr"
    delete_resource "mq-broker" "$bid"
done < <(aws mq list-brokers --region "$REGION" --query 'BrokerSummaries[*].[BrokerId,BrokerName,BrokerState]' --output text 2>/dev/null)

# --- OpenSearch Domains ---
for domain in $(aws opensearch list-domain-names --region "$REGION" --query 'DomainNames[*].DomainName' --output text 2>/dev/null); do
    tags=$(aws opensearch list-tags --arn "arn:aws:es:${REGION}:$(aws sts get-caller-identity --query Account --output text):domain/$domain" --region "$REGION" --query 'TagList' --output json 2>/dev/null)
    tutorial=$(echo "$tags" | python3 -c "import sys,json; t={i['Key']:i['Value'] for i in json.load(sys.stdin) or []}; print(t.get('tutorial',''))" 2>/dev/null)
    match_tutorial "$tutorial" || continue
    found "opensearch-domain" "$domain" "$domain" "${tutorial:-untagged}" "~\$0.10/hr"
    delete_resource "opensearch-domain" "$domain"
done

# --- MSK Clusters ---
while IFS=$'\t' read -r carn cname cstate; do
    [ -z "$carn" ] && continue
    tags=$(aws kafka list-tags-for-resource --resource-arn "$carn" --region "$REGION" --query 'Tags' --output json 2>/dev/null)
    tutorial=$(echo "$tags" | python3 -c "import sys,json; t=json.load(sys.stdin) or {}; print(t.get('tutorial',''))" 2>/dev/null)
    match_tutorial "$tutorial" || continue
    found "msk-cluster" "$carn" "$cname" "${tutorial:-untagged}" "~\$0.25/hr"
    delete_resource "msk-cluster" "$carn"
done < <(aws kafka list-clusters-v2 --region "$REGION" --query 'ClusterInfoList[*].[ClusterArn,ClusterName,State]' --output text 2>/dev/null)

# --- RDS Instances ---
while IFS=$'\t' read -r dbid engine status; do
    [ -z "$dbid" ] && continue
    tags=$(aws rds list-tags-for-resource --resource-name "arn:aws:rds:${REGION}:$(aws sts get-caller-identity --query Account --output text):db:$dbid" --region "$REGION" --query 'TagList' --output json 2>/dev/null)
    tutorial=$(echo "$tags" | python3 -c "import sys,json; t={i['Key']:i['Value'] for i in json.load(sys.stdin) or []}; print(t.get('tutorial',''))" 2>/dev/null)
    match_tutorial "$tutorial" || continue
    found "rds-instance" "$dbid" "$engine" "${tutorial:-untagged}" "~\$0.10/hr"
    delete_resource "rds-instance" "$dbid"
done < <(aws rds describe-db-instances --region "$REGION" --query 'DBInstances[*].[DBInstanceIdentifier,Engine,DBInstanceStatus]' --output text 2>/dev/null)

# --- ElastiCache Serverless ---
for cache in $(aws elasticache describe-serverless-caches --region "$REGION" --query 'ServerlessCaches[*].ServerlessCacheName' --output text 2>/dev/null); do
    found "elasticache" "$cache" "$cache" "check-tags" "~\$0.05/hr"
    delete_resource "elasticache" "$cache"
done

# --- Redshift Serverless ---
for wg in $(aws redshift-serverless list-workgroups --region "$REGION" --query 'workgroups[*].workgroupName' --output text 2>/dev/null); do
    found "redshift-serverless-wg" "$wg" "$wg" "check-tags" "~\$0.25/hr"
    delete_resource "redshift-serverless-wg" "$wg"
done

# --- ECS Clusters with services ---
for cluster_arn in $(aws ecs list-clusters --region "$REGION" --query 'clusterArns[]' --output text 2>/dev/null); do
    cluster=$(echo "$cluster_arn" | awk -F/ '{print $NF}')
    [[ "$cluster" == "DocSmith"* ]] && continue  # Skip pipeline cluster
    svcs=$(aws ecs list-services --region "$REGION" --cluster "$cluster" --query 'serviceArns[]' --output text 2>/dev/null)
    for svc_arn in $svcs; do
        svc=$(echo "$svc_arn" | awk -F/ '{print $NF}')
        found "ecs-service" "$cluster/$svc" "$svc" "check-tags" "per-task"
        delete_resource "ecs-service" "$cluster/$svc"
    done
    # Delete empty clusters
    task_count=$(aws ecs describe-clusters --region "$REGION" --clusters "$cluster" --query 'clusters[0].runningTasksCount' --output text 2>/dev/null)
    svc_count=$(aws ecs describe-clusters --region "$REGION" --clusters "$cluster" --query 'clusters[0].activeServicesCount' --output text 2>/dev/null)
    if [ "${task_count:-0}" = "0" ] && [ "${svc_count:-0}" = "0" ]; then
        found "ecs-cluster" "$cluster" "(empty)" "check-tags" "free"
        delete_resource "ecs-cluster" "$cluster"
    fi
done

# --- Q Business Apps (us-east-1) ---
while IFS=$'\t' read -r appid appname status; do
    [ -z "$appid" ] && continue
    found "qbusiness-app" "$appid" "$appname" "check-tags" "per-query"
    delete_resource "qbusiness-app" "$appid"
done < <(aws qbusiness list-applications --region us-east-1 --query 'applications[*].[applicationId,displayName,status]' --output text 2>/dev/null)

echo ""
if $DELETE; then
    echo "Found $FOUND resources, deleted $DELETED."
else
    echo "Found $FOUND tutorial resources. Run with --delete to remove them."
fi
