# GitHub Environments Setup Guide

This guide explains how to configure GitHub Environments for protecting staging and production deployments with required approvals.

## Overview

With GitHub Environments, deployments to `staging` and `production` require manual approval from designated reviewers. This prevents accidental deployments and provides an audit trail.

**Key Benefits:**
- ✅ Prevents accidental deployments
- ✅ Cost-effective (no runner cost while waiting for approval)
- ✅ Provides audit trail of who approved deployments
- ✅ Enforces deployment windows and branch restrictions

## Setup Instructions

### Step 1: Create Staging Environment

1. Navigate to your repository on GitHub
2. Go to **Settings** → **Environments**
3. Click **New environment**
4. Name it: `staging`
5. Configure the following:

   **Required reviewers:**
   - Click **Add reviewer**
   - Add team members who should approve staging deployments (e.g., release managers, team leads)
   - You can add multiple reviewers (any one can approve)

   **Deployment branches:**
   - Select **Selected branches**
   - Add branch pattern: `main`
   - This ensures only code from `main` branch can deploy to staging

   **Wait timer (optional):**
   - Leave at 0 minutes for faster staging deployments
   - Or set 5 minutes for a brief cooling-off period

6. Click **Save protection rules**

### Step 2: Create Production Environment

1. Still in **Settings** → **Environments**
2. Click **New environment** again
3. Name it: `production`
4. Configure the following:

   **Required reviewers:**
   - Add senior release managers, engineering leads, or production deployment team
   - Consider requiring multiple approvals for extra safety (GitHub Enterprise feature)

   **Deployment branches:**
   - Select **Selected branches**
   - Add branch pattern: `main`
   - This ensures only code from `main` branch can deploy to production

   **Wait timer:**
   - Set to **5-10 minutes** (recommended)
   - This adds a cooling-off period before production deployment
   - Prevents hot-headed deployments

6. Click **Save protection rules**

### Step 3: Verify Dev Environment (Optional)

1. Check if `dev` environment exists
2. If it does, ensure it has **NO required reviewers**
3. This allows automatic deployments to dev without approval gates

## How It Works

### Deployment Flow

1. **Developer triggers promotion** from service workflow
   - Checks "promote_to_stag" or "promote_to_prod" checkbox
   - Workflow runs through validation and dev deployment

2. **Workflow reaches approval gate**
   - When `deploy` job runs with `environment: staging` or `environment: production`
   - Workflow **pauses** and runner is **released** (no cost)

3. **Reviewers get notified**
   - Email notification
   - GitHub notification bell
   - GitHub Actions page shows pending deployment

4. **Reviewer approves or rejects**
   - Reviewer sees deployment details (service, image tag, reason)
   - Clicks "Approve" or "Reject"
   - If rejected, workflow fails immediately

5. **Workflow continues**
   - New runner spins up (after approval)
   - Deployment executes
   - Post-deployment verification runs

### Cost Efficiency

- ⏸️ **While waiting for approval**: No runner allocated, **NO COST**
- ▶️ **During job execution**: Runner allocated, billed normally
- ✅ **Result**: Only pay for actual compute time, not waiting time

## Testing the Setup

### Test Staging Approval

1. Trigger a service workflow (e.g., "CI for Accounts Service")
2. Check "promote_to_stag" checkbox
3. Run workflow from `main` branch
4. Wait for workflow to reach "Waiting for review..."
5. As a reviewer, approve the deployment
6. Verify workflow continues and deploys successfully

### Verify Branch Protection

1. Try triggering promotion from a feature branch
2. The promotion jobs should be **skipped** (due to `github.ref == 'refs/heads/main'` check)
3. Only deployments from `main` branch should proceed

## Troubleshooting

### Workflow Not Pausing

- Verify environment name matches exactly: `staging` or `production`
- Check that the `deploy` job has `environment:` set correctly
- Ensure GitHub Environments are configured in repository settings

### Approvals Not Required

- Verify reviewers are added to the environment
- Check that the environment name is correct (case-sensitive)
- Ensure branch restrictions allow the current branch

### Timeout Issues

- Default: workflows wait indefinitely
- Set a timeout in environment settings if desired
- Workflows fail if timeout expires

## Best Practices

1. **Reviewer Selection**
   - Staging: Team leads, senior developers
   - Production: Release managers, engineering managers

2. **Wait Timers**
   - Staging: 0-5 minutes (fast iteration)
   - Production: 5-10 minutes (prevent hasty decisions)

3. **Branch Restrictions**
   - Always restrict to `main` branch for staging/production
   - Allow feature branches for dev environment only

4. **Documentation**
   - Document who should approve deployments
   - Create a runbook for emergency deployments
   - Track deployment approvals for audit purposes

## Current Workflow Configuration

The workflows are configured as follows:

- **Deployment workflow** (`.applications-deploy.yaml`):
  - Uses `environment: staging` for `stag` deployments
  - Uses `environment: production` for `prod` deployments
  - No changes needed - already configured correctly

- **Service workflows** (accounts, cards, gateway, loans):
  - Promotion jobs only run from `main` branch
  - Require `workflow_dispatch` trigger
  - Call reusable deployment workflow

## Additional Security Options

### Require Multiple Approvers (GitHub Enterprise)

If using GitHub Enterprise, you can require multiple approvals:
- Set "Required reviewers" to 2 or more
- All must approve before deployment proceeds

### Deployment Windows

Configure deployment windows to block deployments during business hours:
- Already implemented via `validate-deployment-window.sh` script
- Blocks production deployments 9 AM - 5 PM EST, Monday-Friday

### Environment Secrets

You can add environment-specific secrets:
- Configure in Environment settings → Secrets
- These are only available to jobs using that environment
- Useful for environment-specific credentials

## Support

For issues or questions:
- Check workflow logs in GitHub Actions
- Review environment configuration in repository settings
- Consult [GitHub Environments documentation](https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment)

