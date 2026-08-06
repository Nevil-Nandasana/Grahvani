# Backup and Disaster Recovery (DR) Specification

## Purpose
This document defines Grahvani's backup strategy, disaster recovery plan, Recovery Point Objective (RPO), and Recovery Time Objective (RTO). It provides actionable runbooks for the on-call team to restore service after an outage or data loss event.

## Scope
Covers all stateful systems: Amazon RDS PostgreSQL, Amazon ElastiCache Redis, and Amazon S3.

---

## 1. Recovery Objectives

| Objective | Target | Rationale |
| :--- | :--- | :--- |
| **RPO** (Recovery Point Objective) | < 5 minutes | Maximum tolerable data loss; birth charts and chat history created in the last 5 minutes may be lost. |
| **RTO** (Recovery Time Objective) | < 1 hour | Maximum tolerable service downtime; restore to operational state within 60 minutes. |

---

## 2. Backup Strategy by Service

### 2.1 Amazon RDS PostgreSQL

| Backup Type | Configuration | Frequency | Retention |
| :--- | :--- | :--- | :--- |
| **Automated Snapshots** | AWS RDS Automated Backups | Daily (at 02:00 IST) | 35 days |
| **Point-in-Time Recovery (PITR)** | Continuous transaction log shipping to S3 | Continuous | 35 days |
| **Manual Snapshots** | Before every major deployment | Manual (CI/CD pre-deploy step) | 90 days |
| **Cross-Region Backup** | AWS Backup Vault with cross-region copy | Daily | 7 days in `ap-southeast-1` |

**PITR granularity**: 5-minute window. The RPO of < 5 minutes is achieved via PITR -- we can restore the database to any 5-minute interval within the retention period.

### 2.2 Amazon ElastiCache Redis

Redis is treated as an **ephemeral hot cache** -- it stores rate limit counters, session tokens, and task queue messages. Data loss is acceptable because:
- Rate limit counters reset within minutes.
- Session tokens can be re-acquired from Firebase.
- Task queue messages (Dramatiq) are re-submitted automatically on worker restart.

**Configuration**: Redis AOF (Append-Only File) persistence is **disabled** to prioritise performance. Daily RDB snapshots are taken and retained for 7 days as a convenience (not for RPO compliance).

### 2.3 Amazon S3

| Bucket Content | Backup Method | Retention |
| :--- | :--- | :--- |
| `docs/` (curated knowledge base texts) | S3 Versioning + Cross-Region Replication to `ap-southeast-1` | Indefinite (versions kept 1 year) |
| `exports/` (user PDF chart exports) | S3 Versioning | 90 days |

---

## 3. Disaster Recovery Runbook

### Scenario A: Database Corruption or Accidental Mass Deletion

```
1. IMMEDIATELY: Set App Runner minimum instances to 0 to stop write traffic.
   aws apprunner update-service --service-arn <API_ARN> --instance-configuration MinSize=0

2. Identify the PITR restore point (5 minutes before the incident).
   aws rds describe-db-instances --db-instance-identifier grahvani-prod

3. Restore to a new RDS instance from PITR:
   aws rds restore-db-instance-to-point-in-time \
     --source-db-instance-identifier grahvani-prod \
     --target-db-instance-identifier grahvani-prod-restored \
     --restore-time <ISO_8601_TIMESTAMP>

4. Verify data integrity on restored instance (spot check key tables).

5. Update DATABASE_URL in AWS Secrets Manager to point to restored instance.

6. Restart App Runner services (they reload secrets on startup).

7. Re-enable minimum instances to 2.

8. Monitor error rate in CloudWatch for 10 minutes.

Estimated RTO: 20-45 minutes.
```

### Scenario B: Complete Region Failure (`ap-south-1` outage)

```
1. Declare disaster in incident Slack channel; notify users via Statuspage.io.

2. Promote the cross-region RDS backup in `ap-southeast-1` to a standalone instance.
   (Note: This instance will lag by up to 35 days -- negotiate acceptable data loss with leadership.)

3. Update Route 53 DNS to point api.grahvani.app to Singapore App Runner service.

4. Launch App Runner services in `ap-southeast-1` using Singapore ECR images (mirror maintained by CI/CD).

5. Update all Secrets Manager secrets in `ap-southeast-1` (pre-seeded during normal operations).

Estimated RTO: 1-2 hours (exceeds MVP RTO target -- acceptable for full-region failure).
```

---

## 4. Pre-Deployment Backup Procedure

Before every production deployment (CI/CD enforced):

```bash
# Take a manual RDS snapshot before deploying
aws rds create-db-snapshot \
  --db-instance-identifier grahvani-prod \
  --db-snapshot-identifier "pre-deploy-$(date +%Y%m%d%H%M)"

# Wait for snapshot to complete
aws rds wait db-snapshot-completed \
  --db-snapshot-identifier "pre-deploy-$(date +%Y%m%d%H%M)"

# Proceed with deployment only after snapshot is available
```

---

## 5. Rationale

**Why 35-day backup retention?**
RDS automated backup allows restoration up to 35 days in the past. This protects against slow-burn data corruption bugs that go undetected for weeks. The cost of 35 days of transaction logs (~$15-30/month for the expected database size) is negligible compared to the risk of irrecoverable user data loss.

**Why is Redis not in the RPO target?**
Redis stores only ephemeral state that either self-heals (rate limit windows reset) or can be reconstructed from the database (session tokens, Dasha cache). Making Redis meet a 5-minute RPO would require Cluster Mode with AOF persistence, which adds ~2x cost and 10-15ms latency overhead. The trade-off is not justified.

---

## 6. Future Improvements

- **AWS Elastic Disaster Recovery (DRS)**: Implement continuous replication to `ap-southeast-1` for sub-minute RTO in future Phase 3.
- **Chaos Engineering**: Quarterly DR drills where the team practises the Scenario A runbook to validate actual RTO.
- **Automated Backup Verification**: Schedule a weekly Lambda function to restore the most recent backup to a test instance and verify row counts.

---

## 7. Related Documents

- [AWS.md](AWS.md) -- Full AWS service configuration including RDS and ElastiCache
- [MONITORING.md](MONITORING.md) -- CloudWatch alarms for data anomaly detection
- [infrastructure/SECURITY.md](SECURITY.md) -- IAM roles and access control
