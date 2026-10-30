# Changelog

## 0.8.1 - 2026-10-30

- **FLS Matrix:** saving Account access in an org with Person Accounts no longer fails with "Read
  Account depends on Read Contact". Contact Read is now granted alongside Account Read, as Setup
  does.
- **FLS Matrix:** saving object access for a permission set with no access yet, with every box
  left unchecked, no longer fails with "You must enable at least one permission".
- **User Comparison:** no longer lists each user's internal profile permission set (shown as a raw
  Id like `00e...`) among their permission sets.
- **Picklist Manager:** the "Global Value Set" error now carries its message to Apex callers too.
- Docs: a setup video and expanded Install steps on the project site (assigning access, granting
  admins Customize Application and Assign Permission Sets, hiding tools). Public groups need the
  right to manage groups (normally Manage Users); there's no "Manage Public Groups" permission.
- Apex tests now pass in any org: they use standard fields instead of custom fields that only
  existed in the original dev org, and cover Person Accounts orgs.

## 0.8.0 - 2026-10-29

First standalone release, split out from a larger monorepo of Lightning components.

- Sixteen tools in four sections: **Data** (Create Records, Query Records, Data Export, Data
  Masking), **Schema** (Schema Explorer, Relationship Map, Field Creator, Picklist Manager, Impact
  Analysis, Translation Finder), **Users & Security** (Permissions and Groups, FLS Matrix, Org
  Chart, Record Access Inspector, User Comparison) and **Org Info** (Limits and Licenses).
- Per-tool visibility through the `Salesforce_Inspector_Native_Tab__mdt` custom metadata type.
