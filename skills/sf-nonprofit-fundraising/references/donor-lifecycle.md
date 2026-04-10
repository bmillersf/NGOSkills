# Donor Lifecycle Reference

## Donor Journey Stages

```
Prospect → First-Time Donor → Repeat Donor → Committed Donor → Major Donor → Legacy Donor
    ↕              ↕                ↕               ↕              ↕
  Lapsed ←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←
```

---

## Engagement Scoring

### Recency-Frequency-Monetary (RFM) Model

| Dimension | Scoring Criteria | Points |
|-----------|-----------------|--------|
| **Recency** | Last gift within 6 months: 5 / 12 months: 3 / 24 months: 1 | 1-5 |
| **Frequency** | 5+ gifts/year: 5 / 3-4: 4 / 2: 3 / 1: 2 | 1-5 |
| **Monetary** | Based on org-specific thresholds | 1-5 |

### Composite Score

Total RFM Score (3-15) maps to engagement tier:

| Score | Tier | Action |
|-------|------|--------|
| 13-15 | Champion | Personal stewardship, major gift cultivation |
| 10-12 | Loyal | Upgrade ask, event invitations |
| 7-9 | Engaged | Regular communication, retention focus |
| 4-6 | At-Risk | Re-engagement campaign |
| 3 | Lapsed | Win-back campaign or archive |

---

## Stewardship Matrix

| Donor Tier | Touchpoints/Year | Channel | Owner |
|-----------|-----------------|---------|-------|
| Major ($10K+) | 12+ | Personal calls, visits, exclusive events | Major Gift Officer |
| Mid-Level ($1K-$10K) | 6-8 | Personal email, phone, small events | Development Associate |
| Annual ($100-$1K) | 4-6 | Email, newsletter, annual event | Communications |
| Entry (<$100) | 2-4 | Email, social media | Marketing automation |

---

## LYBUNT / SYBUNT Queries

### LYBUNT (Last Year But Unfortunately Not This year)

Donors who gave last fiscal year but have not yet given this fiscal year.

```sql
SELECT Id, Name, PersonEmail,
  (SELECT Amount, GiftDate FROM Gifts__r
   WHERE GiftDate >= LAST_YEAR ORDER BY GiftDate DESC LIMIT 1)
FROM Account
WHERE Id IN (
  SELECT DonorId FROM Gift WHERE CALENDAR_YEAR(GiftDate) = :lastYear
)
AND Id NOT IN (
  SELECT DonorId FROM Gift WHERE CALENDAR_YEAR(GiftDate) = :thisYear
)
AND IsPersonAccount = true
```

### SYBUNT (Some Year But Unfortunately Not This year)

```sql
SELECT Id, Name, PersonEmail
FROM Account
WHERE Id IN (
  SELECT DonorId FROM Gift WHERE CALENDAR_YEAR(GiftDate) < :thisYear
)
AND Id NOT IN (
  SELECT DonorId FROM Gift WHERE CALENDAR_YEAR(GiftDate) = :thisYear
)
AND IsPersonAccount = true
```

---

## Upgrade Strategy

### Identification

- 2+ consecutive years of giving
- Increasing average gift amount
- Engaged with events or volunteer activities
- Opens/clicks fundraising emails at high rate

### Ask Array

| Current Level | Suggested Ask | Rationale |
|--------------|--------------|-----------|
| $25-$49 | $50, $75, $100 | 2x, 3x, 4x current |
| $50-$99 | $100, $150, $250 | Round numbers, step-up |
| $100-$499 | $250, $500, $1,000 | Mid-level threshold |
| $500-$999 | $1,000, $1,500, $2,500 | Major gift entry |

---

## Reporting Dimensions

| Report | Key Metrics |
|--------|------------|
| **Revenue Summary** | Total gifts, average gift, median gift, gift count |
| **Donor Retention** | Year-over-year retention rate, new vs returning |
| **Campaign Performance** | ROI, cost per dollar raised, donor acquisition cost |
| **Recurring Giving** | Active commitments, monthly revenue, churn rate |
| **Channel Analysis** | Online vs offline, event vs appeal, major vs annual |
| **Pipeline** | Pledges, expected revenue, solicitation stage |
