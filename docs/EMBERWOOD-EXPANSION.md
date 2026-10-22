# Emberwood production expansion

Baseline: main a277452. The earlier unfinished campaign draft is preserved in a Git stash; it is not the production baseline. All six baseline suites pass (279 HUD assertions).

## Phase 1: shared motion diagnosis

The imported native Run is a 0.8s grounded cycle. The controller sampled its upper body at a fixed 2.7x, while the lower body ran at measured speed / 2.27272727. At 5m/s this is 2.2x: torso/foot phases drifted, creating a visible beat. Movement already has input acceleration; a second velocity filter also drove foot distance, causing sliding on acceleration and after collision. Finally, toggling between Shoot and RunShoot at the movement threshold restarted blends mid-draw despite the independent lower-body layer. Release sockets were read before advancing the animation, one simulation sample behind.

Fix: sample whole Run from the continuous distance phase; integrate foot phase from actual displacement (retain smoothing for posture/turning); use one Shoot upper-body state through movement changes; sample attack pose before release sockets. Authored clips, attack release timestamps, damage and cooldowns remain unchanged. Existing substeps are bounded variable steps, not a true fixed accumulator; they do not restart animations each frame.
