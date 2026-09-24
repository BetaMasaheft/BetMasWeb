# Catalog facade

`modules/catalog.xqm` is the shared Web/API contract for labels, institution
options, text parts, bibliography entries, and retired identifiers.

Each consumer reads its own `CATALOG_BACKEND_<CONSUMER>` value from
`services.xml`; names are uppercased and non-alphanumeric characters become
underscores. Supported values are `legacy` and `catalog`. Missing or invalid
values always select `legacy`.

Current consumers and variables:

- `exptit`: `CATALOG_BACKEND_EXPTIT`
- Web lists: `CATALOG_BACKEND_WEB_LIST`
- item bibliography rendering: `CATALOG_BACKEND_VIEW_ITEM`
- API titles: `CATALOG_BACKEND_API_TITLES`
- API repository list: `CATALOG_BACKEND_API_REST`

The deployment initializer copies configured environment variables into
`services.xml`, following the same mechanism as other service configuration.
No backend is flipped by this phase.

The CI no-writes gate permits writes only in explicitly listed install,
editor, expansion/admin, and test modules. Request-serving modules are not
allow-listed.
