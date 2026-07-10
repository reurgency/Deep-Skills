# Deep-Learn taxonomy — pointer

The **authoritative category spine lives in the core deep-skills plugin**: `plugins/deep-skills/directives/taxonomy.md`. deep-goal does not fork the taxonomy — one shared vocabulary is the whole point of the spine.

Any future card in this registry references its `category` by the exact slug defined there, and its `owner_phases` must include `deep-goal` as an exact token (the loader matches exact tokens only). This registry ships **empty** in v1; adding a `deep-goal` token to the core taxonomy's owner-phase roster (and any cross-registry reading) is a deferred extension — see the plan's Deferreds ledger.
