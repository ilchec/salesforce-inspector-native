<img width="1376" height="768" alt="Salesforce Inspector Native banner" src="https://github.com/user-attachments/assets/37c4f72c-890c-45c7-90b2-311028304c6c" />

# Salesforce Inspector Native

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
![Salesforce API 67.0](https://img.shields.io/badge/Salesforce%20API-67.0-00A1E0)
![No browser extension](https://img.shields.io/badge/install-metadata%20only-0176D3)

Sixteen admin and developer tools in one Lightning app: query and bulk-edit data, export and mask
it, explore and change schema, manage permissions, and inspect users and org limits. It installs as
plain Salesforce metadata, so there's no browser extension, Data Loader or local install.

**[Watch the demo and read the usage guide →](https://ilchec.github.io/salesforce-inspector-native/)**

## Who this is for

It's built for people on **managed, locked-down devices**. That includes places where IT policy, a
lack of local admin rights, or a browser-extension allowlist rules out Data Loader or Salesforce
Inspector Reloaded. This app runs entirely inside your org, on Salesforce's own domain. You open it
from the App Launcher like any other app. You don't need to install anything locally or get an
extension approved, and IT gets the same review as any other custom Lightning app.

## Quickstart

You need the [Salesforce CLI](https://developer.salesforce.com/tools/salesforcecli) (`sf`).

```bash
git clone https://github.com/ilchec/salesforce-inspector-native.git
cd salesforce-inspector-native

sf org login web --alias myorg
sf project deploy start --target-org myorg
```

Then:

1. Assign the **Salesforce Inspector Native** permission set: Setup → Permission Sets →
   Salesforce Inspector Native → Manage Assignments → Add Assignment.
2. Open the App Launcher and search for **Salesforce Inspector Native**.

Try it in a sandbox or Developer Edition org first. Several tools change data, schema or
security (see [What writes to your org](#what-writes-to-your-org)).

## The tools

| Section | Tool | What it does |
|---|---|---|
| **Data** | Create Records | Bulk create or upsert records in a grid. Paste from Excel, import a CSV with column auto-mapping, or type rows directly. |
| | Query Records | Run SOQL (parent fields like `Owner.Name` included), then view, inline-edit, export to CSV or bulk-delete the results. |
| | Data Export | Choose an object and fields, then download a full CSV. Pages through results past the 200-row limit, up to 50,000 rows. |
| | Data Masking | Overwrite names, emails, phones and text with fake values on filtered records, for scrubbing a sandbox. Preview first, then apply. |
| **Schema** | Schema Explorer | Every field on an object in one searchable table: type, references, required, unique, external ID, createable, updateable. |
| | Relationship Map | What an object looks up to and what looks up to it. Click any node to re-center the map on it. |
| | Field Creator | Define several custom fields at once, with type-specific options and field-level security, and deploy them in one go. |
| | Picklist Manager | Add, rename, reorder, activate and deactivate custom picklist values. |
| | Impact Analysis | What references a custom field or object (flows, Apex, layouts, formulas, validation rules), from the Dependency API. |
| | Translation Finder | Type text you see in the UI and find which custom label, object, field or picklist value it comes from. |
| **Users & Security** | Permissions and Groups | Assign permission sets, permission set groups and public groups to many users at once, with an optional expiry date. |
| | FLS Matrix | Every field crossed with every permission set, with Read/Edit checkboxes plus object-level access, saved in one call. |
| | Org Chart | Browse the manager hierarchy: who someone reports to and who reports to them. |
| | Record Access Inspector | Why a user can or can't see a record: Read, Edit, Delete, Transfer and max access level. |
| | User Comparison | Two users side by side: settings, profile, role, permission sets, groups and queues, with differences highlighted. |
| **Org Info** | Limits and Licenses | Org limits as gauges and license usage as bars, highest usage first. |

The [project site](https://ilchec.github.io/salesforce-inspector-native/) has a walkthrough video and
step-by-step instructions for every tool.

## Setting it up

The bundled permission set grants access to the app, its tab, its Apex classes and one internal
Visualforce page. It **doesn't** grant access to any object or field. Every tool only works with
data and metadata the user can already reach through their profile or other permission sets.

A few tools also need a system permission that the permission set can't grant:

| Tool | Extra permission needed |
|---|---|
| Field Creator, Picklist Manager, FLS Matrix (saving) | **Customize Application** (Salesforce requires it for any schema change) |
| Permissions and Groups | **Assign Permission Sets** for permission sets/groups, and **Manage Public Groups** for public groups |
| Query Records, Data Masking | None, but Query Records allows general-purpose SOQL. Grant it as carefully as you would Data Loader or Workbench. |
| All other tools | None |

No Remote Site Setting, Named Credential or Connected App is needed. The tools that use the Tooling
API call your org's own domain.

## What writes to your org

| Changes data | Changes schema or security | Read-only |
|---|---|---|
| Create Records, Query Records (edit, delete), Data Masking | Field Creator, Picklist Manager, FLS Matrix, Permissions and Groups | Data Export, Schema Explorer, Relationship Map, Impact Analysis, Translation Finder, Org Chart, Record Access Inspector, User Comparison, Limits and Licenses |

Each tool that writes stages changes first and only writes when you click Save, Apply or Deploy.
The one exception is **Delete Selected** in Query Records, which deletes as soon as you confirm.

## Showing or hiding tools

Each tool has a record in the **Salesforce Inspector Native Tab** custom metadata type with an
**Is Enabled** checkbox. All sixteen are enabled by default. To hide one: Setup → Custom Metadata
Types → Salesforce Inspector Native Tab → Manage Records → edit the record → clear Is Enabled. The
change takes effect the next time the app loads, with no redeploy. In the app, **Tab Settings**
links straight there.

## Known limitations

- **Field Creator** supports the 12 standalone field types (Text, Text Area (Long), Checkbox, Number,
  Currency, Percent, Date, Date/Time, Email, Phone, URL, Picklist). It doesn't support Lookup or
  Master-Detail.
- **Picklist Manager** works on custom picklist fields with their own value set. It doesn't support
  standard picklists or global value sets. Salesforce's API can't delete a value, so the tool can
  only deactivate one.
- **Query Records** doesn't support child-relationship subqueries. Results show one row per
  top-level record.
- **Impact Analysis** depends on the Dependency API. That API doesn't cover Reports, returns at most
  2,000 references, and reports Flow references less completely than Apex or formula references.
- **Data Masking** handles up to 200 records per run.

## Development

```bash
npm install
npm run test:unit                                    # LWC Jest tests
sf apex run test --target-org myorg --wait 20        # Apex tests
```

[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) explains how each tool works, where and why Apex is
used, and what every component in the package does. Contributions are welcome. See
[CONTRIBUTING.md](CONTRIBUTING.md).

## Acknowledgements

- Field Creator is modeled on the
  [Salesforce Inspector Reloaded](https://github.com/tprouvot/Salesforce-Inspector-reloaded)
  browser extension's tool of the same name.
- Org Chart is inspired by (but not a port of)
  [svierk/awesome-lwc-collection's `orgChartViewer`](https://github.com/svierk/awesome-lwc-collection/tree/main/force-app/main/default/lwc/orgChartViewer)
  (MIT).

## License

[MIT](LICENSE) © 2026 Ilia Chechuro.

This is an independent open-source project and isn't affiliated with or endorsed by Salesforce, Inc.
