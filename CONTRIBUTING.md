# Contributing

Thanks for your interest. Bug reports, ideas and pull requests are all welcome.

## Reporting a bug

Open an issue and include:

- which tool, and what you did step by step
- what you expected, and what happened instead (the exact error text helps a lot)
- your org type (production, sandbox, Developer Edition, scratch org) and any relevant org
  features, such as Person Accounts or multi-currency

Please don't paste session IDs, record data, or anything else sensitive from your org.

## Making a change

1. Fork the repo and create a branch.
2. Deploy to a scratch org or Developer Edition org:
   ```bash
   sf org create scratch --definition-file config/project-scratch-def.json --alias inspector-dev
   sf project deploy start --target-org inspector-dev
   ```
3. Run the tests:
   ```bash
   npm install
   npm run test:unit
   sf apex run test --target-org inspector-dev --wait 20
   ```
4. Bump `APP_VERSION` in `main/default/lwc/inspectorNativeApp/inspectorNativeApp.js` and add a line
   to [CHANGELOG.md](CHANGELOG.md).
5. Open a pull request that says what changed and how you tested it.

## Conventions

Read [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) before adding a tool. In short:

- Prefer the UI API (`lightning/graphql` and the base wire adapters). Add Apex only where the
  platform offers no UI API route, and keep each class narrow and single-purpose.
- Don't add external scripts, static resources or third-party libraries.
- Keep every bundle under the `inspectorNative` prefix. The project must deploy on its own.
- Tools that write should stage changes and write only on an explicit Save/Apply.
- New tools need a `Salesforce_Inspector_Native_Tab__mdt` record, an entry in `TABS` in
  `inspectorNativeApp.js`, access in the permission set, and Jest tests for any `*Utils` module.
