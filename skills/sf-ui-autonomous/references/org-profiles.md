# Org-Shape Profiles

The library indexes flows against an `org_profile` because a spec captured against NPSP will fail in NPC (different objects, different field labels, different navigation).

## The four profiles

| Profile | Detection signal | Notes |
|---|---|---|
| **NPSP** | `npsp` namespace present (`SELECT NamespacePrefix FROM Organization` or installed package query) | Legacy nonprofit managed package. Account-Contact-AccountContactRelation model |
| **NPC** | Nonprofit Cloud entitlement + standard `Person Account` or NPC-specific `IndividualApplication__c`-style objects | Native nonprofit. Different data model — Person Accounts central |
| **NPC+EDA** | NPC + EDA managed package (`hed` namespace) | Education-flavored NPC overlay. Different course/program objects |
| **vanilla** | None of the above; standard Sales/Service Cloud only | Baseline. Any flow that works here is the most portable |

## Detection

The capture script auto-detects via:

```bash
sf data query --target-org "$ORG_ALIAS" --json --query "
  SELECT NamespacePrefix
  FROM PackageLicense
  WHERE NamespacePrefix IN ('npsp', 'hed', 'npe01', 'npo02', 'npe03', 'npe04', 'npe5')
"
```

Plus a quick check for NPC-specific objects:

```bash
sf sobject describe --sobject IndividualApplication__c --target-org "$ORG_ALIAS" 2>/dev/null && echo "NPC"
```

## Why this matters for replay

When a user invokes the skill with intent "create a contact + link to account", the library matches:

1. **Same intent** (semantic match against `intent` field)
2. **Same `org_profile`** as the target org

If only step 1 matches, the replay is *risky* — the spec may target objects/fields that don't exist. The skill warns and asks the user to confirm before replaying.

## Multi-profile captures

Some flows work across all four profiles (e.g., creating a standard Account). Those entries set `org_profile: "vanilla"` — vanilla flows are tried first against any org, and only fall back to profile-specific captures if vanilla fails.
