# Emberwood production expansion

Baseline: main a277452. The earlier unfinished campaign draft is preserved in a Git stash; it is not the production baseline. All six baseline suites pass (279 HUD assertions).

## Phase 1: shared motion diagnosis

The imported native Run is a 0.8s grounded cycle. The controller sampled its upper body at a fixed 2.7x, while the lower body ran at measured speed / 2.27272727. At 5m/s this is 2.2x: torso/foot phases drifted, creating a visible beat. Movement already has input acceleration; a second velocity filter also drove foot distance, causing sliding on acceleration and after collision. Finally, toggling between Shoot and RunShoot at the movement threshold restarted blends mid-draw despite the independent lower-body layer. Release sockets were read before advancing the animation, one simulation sample behind.

Fix: sample whole Run from the continuous distance phase; integrate foot phase from actual displacement (retain smoothing for posture/turning); use one Shoot upper-body state through movement changes; sample attack pose before release sockets. Authored clips, attack release timestamps, damage and cooldowns remain unchanged. Existing substeps are bounded variable steps, not a true fixed accumulator; they do not restart animations each frame.

## Completed implementation

Phases 2–11 have individual checkpoint commits: five unlocked selection cards, shared ability timelines, purchased quivers, purchased pets/upgrades, twenty-wave schedule, nonlinear pressure/scaling, four guardian controllers, collected chest queue, native reveal, and kill-only Mythic rewards. Phase 12 completes conservative currency tuning, tier-specific guardian balance, reward/ownership eligibility, restart UI and full progression validation. The former uncommitted pet draft was selectively reused after updating to main; its older item catalog was not restored.

The completion pass fixed the typed-array assignment in the campaign test that prevented the test process from exiting, added validation timeouts, checked real wolf/beetle behavior, and corrected reward-card reveal synchronization. It also preserves defensive animation priority during overlapping skills and purchased attack-speed scaling for Ash/Nyx.

Implementation details, scaling tables, visual evidence, controls and limitations are recorded in `godot-native/README.md`. The production trader design and formula remain authoritative.

## Release verification

Production source `67f826b35d4bb5194fd17af17322e6163da22cc6` passes all seven suites locally and in the universal macOS release workflow. The expanded campaign suite passes 1,702 checks, including repeated pet stability samples; the HUD suite passes its live callbacks and layout checks (count varies with randomized offers). Universal export verifies Apple Silicon and Intel slices, ad-hoc signature hashes, executable permissions and ZIP integrity.

Published release: https://github.com/maddoxmoye/Codex/releases/tag/emberwood-mac-v0.2.0

Successful release workflow: https://github.com/maddoxmoye/Codex/actions/runs/39897175089

The public Mac ZIP was downloaded again and verified against the release SHA-256 and ZIP CRCs. `godot-native/release-info.json` records the published CI artifact, whose packed archive differs slightly from the separately verified local export. The editable source ZIP hashes match.

Mac runtime/FPS remain unmeasured; the Linux software-rendered reveal is visual evidence only. Forward+ software-render captures report shutdown texture/ObjectDB warnings; headless gameplay validation and exported bundle checks pass. No macOS notarization or unfinished-run persistence is included in this playtest build.


## Presentation update 0.2.1

Replaced five title-screen model SubViewports with native 2D archer crests: bow, flame, shield, crescent and clockwork. Whole-card buttons preserve keyboard focus, hover/selection feedback, role and ability information. Gameplay character assets and the trader are unchanged.

The chest reveal now drives a projected mouth position and normalized flight progress from its existing timeline. The real reward PanelContainer scales, rotates and follows an arc to its readable dock. No duplicate floating icon or separate animation timer is used. Claim buttons remain disabled until landing. Tests cover pre-release concealment, intermediate card motion, final upright size and unchanged sequential rewards.

All seven suites passed during the universal Mac export; the campaign suite now has 1,705 assertions. Screenshots and native frame-captured reveal video were reviewed. Windows/Linux are supported export targets but remain unshipped and untested as standalone release builds.
