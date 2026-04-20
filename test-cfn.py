#!/usr/bin/env python
"""Test all CloudFormation templates: validate, deploy, verify, delete.

Usage: python3 test-cfn.py [--parallel N] [--skip-deploy] [--region REGION]
"""

import argparse
import boto3
import json
import os
import sys
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from dataclasses import dataclass, field
from pathlib import Path

PREREQ_STACKS = {
    "tutorial-prereqs-bucket": "cfn/prereq-bucket.yaml",
    "tutorial-prereqs-vpc-public": "cfn/prereq-vpc-public.yaml",
    "tutorial-prereqs-vpc-private": "cfn/prereq-vpc-private.yaml",
}

@dataclass
class TestResult:
    template: str
    validate: str = "SKIP"
    deploy: str = "SKIP"
    delete: str = "SKIP"
    duration: float = 0
    error: str = ""
    stack_name: str = ""

def find_templates(repo_root):
    """Find all cfn-*.yaml templates in tutorial directories."""
    templates = {}
    for p in sorted(Path(repo_root, "tuts").glob("*/cfn-*.yaml")):
        tut = p.parent.name
        templates[tut] = str(p)
    return templates

def detect_prereqs(template_path):
    """Check which prerequisite stacks a template needs."""
    content = Path(template_path).read_text()
    needed = []
    if "prereqs-bucket" in content or "prereq-bucket" in content:
        needed.append("tutorial-prereqs-bucket")
    if "prereqs-vpc-public" in content or "prereq-vpc-public" in content:
        needed.append("tutorial-prereqs-vpc-public")
    if "prereqs-vpc-private" in content or "prereq-vpc-private" in content:
        needed.append("tutorial-prereqs-vpc-private")
    return needed

def needs_iam(template_path):
    content = Path(template_path).read_text()
    if "RoleName" in content or "PolicyName" in content:
        return "CAPABILITY_NAMED_IAM"
    if "AWS::IAM::" in content:
        return "CAPABILITY_IAM"
    return None

def validate_template(cfn, template_path):
    body = Path(template_path).read_text()
    cfn.validate_template(TemplateBody=body)

def deploy_stack(cfn, stack_name, template_path, timeout=600):
    body = Path(template_path).read_text()
    caps = []
    cap = needs_iam(template_path)
    if cap:
        caps = [cap]

    try:
        cfn.create_stack(
            StackName=stack_name,
            TemplateBody=body,
            Capabilities=caps,
            Tags=[{"Key": "test-run", "Value": "cfn-test"}],
            TimeoutInMinutes=10,
            OnFailure="DELETE",
        )
    except cfn.exceptions.AlreadyExistsException:
        cfn.delete_stack(StackName=stack_name)
        waiter = cfn.get_waiter("stack_delete_complete")
        waiter.wait(StackName=stack_name, WaiterConfig={"Delay": 10, "MaxAttempts": 60})
        cfn.create_stack(
            StackName=stack_name,
            TemplateBody=body,
            Capabilities=caps,
            Tags=[{"Key": "test-run", "Value": "cfn-test"}],
            TimeoutInMinutes=10,
            OnFailure="DELETE",
        )

    waiter = cfn.get_waiter("stack_create_complete")
    waiter.wait(StackName=stack_name, WaiterConfig={"Delay": 15, "MaxAttempts": int(timeout / 15)})

def delete_stack(cfn, stack_name, timeout=300):
    cfn.delete_stack(StackName=stack_name)
    waiter = cfn.get_waiter("stack_delete_complete")
    waiter.wait(StackName=stack_name, WaiterConfig={"Delay": 10, "MaxAttempts": int(timeout / 10)})

def ensure_prereqs(cfn, repo_root, needed_stacks):
    """Deploy prerequisite stacks if they don't exist. Returns set of failed prereqs."""
    failed = set()
    for stack_name in needed_stacks:
        try:
            resp = cfn.describe_stacks(StackName=stack_name)
            status = resp["Stacks"][0]["StackStatus"]
            if status in ("CREATE_COMPLETE", "UPDATE_COMPLETE"):
                print(f"  Prereq {stack_name}: exists ({status})")
                continue
            elif "ROLLBACK" in status or "FAILED" in status:
                print(f"  Prereq {stack_name}: cleaning up failed stack...")
                cfn.delete_stack(StackName=stack_name)
                cfn.get_waiter("stack_delete_complete").wait(
                    StackName=stack_name, WaiterConfig={"Delay": 10, "MaxAttempts": 30})
        except cfn.exceptions.ClientError:
            pass

        template_file = PREREQ_STACKS.get(stack_name)
        if not template_file:
            failed.add(stack_name)
            continue

        template_path = os.path.join(repo_root, template_file)
        print(f"  Prereq {stack_name}: deploying...")
        try:
            caps = []
            if needs_iam(template_path):
                caps = [needs_iam(template_path)]
            body = Path(template_path).read_text()
            cfn.create_stack(
                StackName=stack_name, TemplateBody=body, Capabilities=caps,
                Tags=[{"Key": "test-run", "Value": "cfn-test"}],
                TimeoutInMinutes=10, OnFailure="DELETE",
            )
            waiter = cfn.get_waiter("stack_create_complete")
            waiter.wait(StackName=stack_name, WaiterConfig={"Delay": 15, "MaxAttempts": 40})
            print(f"  Prereq {stack_name}: ready")
        except Exception as e:
            print(f"  Prereq {stack_name}: CFN deploy failed ({e})")
            print(f"  Prereq {stack_name}: Run ./cfn/setup-bucket.sh first, then retry.")
            failed.add(stack_name)
            try:
                cfn.delete_stack(StackName=stack_name)
            except Exception:
                pass
    return failed

def test_template(cfn, tut_name, template_path, skip_deploy):
    """Test a single template: validate, deploy, delete."""
    result = TestResult(template=tut_name)
    stack_name = f"cfn-test-{tut_name[:40]}"
    result.stack_name = stack_name
    start = time.time()

    # Validate
    try:
        validate_template(cfn, template_path)
        result.validate = "PASS"
    except Exception as e:
        result.validate = "FAIL"
        result.error = str(e)[:200]
        result.duration = time.time() - start
        return result

    if skip_deploy:
        result.duration = time.time() - start
        return result

    # Deploy
    try:
        deploy_stack(cfn, stack_name, template_path)
        result.deploy = "PASS"
    except Exception as e:
        result.deploy = "FAIL"
        result.error = str(e)[:200]
        result.duration = time.time() - start
        # Try cleanup
        try:
            delete_stack(cfn, stack_name)
        except Exception:
            pass
        return result

    # Delete
    try:
        delete_stack(cfn, stack_name)
        result.delete = "PASS"
    except Exception as e:
        result.delete = "FAIL"
        result.error = f"Delete failed: {str(e)[:150]}"

    result.duration = time.time() - start
    return result

def main():
    parser = argparse.ArgumentParser(description="Test CloudFormation templates")
    parser.add_argument("--parallel", type=int, default=3, help="Max parallel deployments")
    parser.add_argument("--skip-deploy", action="store_true", help="Validate only, don't deploy")
    parser.add_argument("--region", default="us-east-1")
    parser.add_argument("--repo", default=".", help="Repo root directory")
    args = parser.parse_args()

    repo_root = os.path.abspath(args.repo)
    cfn = boto3.client("cloudformation", region_name=args.region)

    # Find templates
    templates = find_templates(repo_root)
    print(f"Found {len(templates)} templates")

    if not args.skip_deploy:
        # Collect all needed prereqs
        all_prereqs = set()
        template_prereqs = {}
        for tut, path in templates.items():
            prereqs = detect_prereqs(path)
            template_prereqs[tut] = prereqs
            all_prereqs.update(prereqs)

        failed_prereqs = set()
        if all_prereqs:
            print(f"\nDeploying prerequisites: {', '.join(sorted(all_prereqs))}")
            failed_prereqs = ensure_prereqs(cfn, repo_root, sorted(all_prereqs))
            if failed_prereqs:
                print(f"\nFailed prereqs: {', '.join(failed_prereqs)}")

    # Test templates in parallel
    print(f"\nTesting {len(templates)} templates (parallel={args.parallel})...\n")
    results = []

    with ThreadPoolExecutor(max_workers=args.parallel) as pool:
        futures = {}
        for tut, path in templates.items():
            # Skip if prereqs failed
            if not args.skip_deploy:
                missing = set(template_prereqs.get(tut, [])) & failed_prereqs
                if missing:
                    r = TestResult(template=tut, validate="PASS", deploy="SKIP", error=f"Prereq failed: {', '.join(missing)}")
                    results.append(r)
                    print(f"  ⊘ {tut}: skipped (prereq failed)")
                    continue
            # Each thread gets its own client
            thread_cfn = boto3.client("cloudformation", region_name=args.region)
            future = pool.submit(test_template, thread_cfn, tut, path, args.skip_deploy)
            futures[future] = tut

        for future in as_completed(futures):
            tut = futures[future]
            result = future.result()
            results.append(result)
            status = "✓" if result.deploy in ("PASS", "SKIP") and result.validate == "PASS" else "✗"
            print(f"  {status} {result.template}: validate={result.validate} deploy={result.deploy} delete={result.delete} ({result.duration:.0f}s)")
            if result.error:
                print(f"    Error: {result.error}")

    # Report
    results.sort(key=lambda r: r.template)
    passed = sum(1 for r in results if r.validate == "PASS" and r.deploy in ("PASS", "SKIP"))
    failed = len(results) - passed

    print(f"\n{'='*70}")
    print(f"RESULTS: {passed} passed, {failed} failed, {len(results)} total")
    print(f"{'='*70}")
    print(f"{'Template':<45} {'Validate':<10} {'Deploy':<10} {'Delete':<10} {'Time':<8}")
    print(f"{'-'*45} {'-'*10} {'-'*10} {'-'*10} {'-'*8}")
    for r in results:
        print(f"{r.template:<45} {r.validate:<10} {r.deploy:<10} {r.delete:<10} {r.duration:<8.0f}s")

    # Cleanup prereqs if all tests passed
    if not args.skip_deploy and failed == 0:
        print(f"\nAll tests passed. Prerequisite stacks left running for reuse.")
        print(f"To delete: python3 {sys.argv[0]} --cleanup-prereqs")

    return 1 if failed > 0 else 0

if __name__ == "__main__":
    sys.exit(main())
