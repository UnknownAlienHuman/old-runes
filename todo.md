# Live-client validation

Static and mocked checks are automated. The following rows require an actual Retail client and remain **NOT-RUN** until evidence is recorded with client build, Interface, addon commit, other enabled addons, and first failure.

| Scenario | Required evidence | Status |
| --- | --- | --- |
| Fresh install and upgrade from 2.1.0 | Schema 2 values, legacy keys removed, settings retained | NOT-RUN |
| Login and `/reload` on DK | Player RuneFrame styled once; no duplicate overlays/errors | NOT-RUN |
| All four styles | Correct textures/gray art across six slots | NOT-RUN |
| Specialization changes | Persisted style reapplied for Blood/Frost/Unholy | NOT-RUN |
| PRD hide/show and Edit Mode rebuild | Exact replacement class frame discovered; disable restores Blizzard art | NOT-RUN |
| Combat transitions | No taint/forbidden-action errors; newest deferred state applied once | NOT-RUN |
| Timer and spiral toggles | Player and enabled PRD update; disabled PRD keeps Blizzard defaults | NOT-RUN |
| Coexistence | Default UI only, addon alone, then normal addon stack; no repeating Lua/taint/performance errors | NOT-RUN |

Open issues #1 and #2 remain the live-client evidence gates.
