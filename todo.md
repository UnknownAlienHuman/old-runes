# Live-client validation

Static and mocked checks are automated. The following rows require an actual Retail client and remain **NOT-RUN** until evidence is recorded with client build, Interface, addon commit, other enabled addons, and first failure.

| Scenario | Required evidence | Status |
| --- | --- | --- |
| Fresh install and upgrade from 2.1.0 | Schema 2 values, legacy keys removed, settings retained | NOT-RUN |
| Login and `/reload` on DK | Player RuneFrame styled once; no duplicate overlays/errors | NOT-RUN |
| Initial readiness | No rune is falsely dimmed while `lastRuneState` or `GetRuneCooldown` is temporarily unavailable | NOT-RUN |
| All four styles | Correct textures/gray art across six slots; classic texture paths resolve | NOT-RUN |
| Specialization changes | Persisted style reapplied for Blood/Frost/Unholy | NOT-RUN |
| PRD lifecycle | Hide/show, late `SetupClassBar`, Edit Mode, and defensive replacement recovery; disabling styling restores Blizzard art | NOT-RUN |
| Combat transitions | No taint/forbidden-action errors; newest deferred state applied once | NOT-RUN |
| Timer and spiral toggles | Player and enabled PRD update; disabled PRD keeps Blizzard defaults | NOT-RUN |
| Coexistence | Default UI only, addon alone, then normal addon stack; no repeating Lua/taint/performance errors | NOT-RUN |
| Package/install | ZIP root and files install cleanly; addon metadata/icon render correctly | NOT-RUN |

Open issues #1 and #2 remain the live-client evidence gates. Source review and mocks must not be recorded as a client PASS.
