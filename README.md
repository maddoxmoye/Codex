# Wildfall — Into the Hollow

A self-contained, top-down browser survival roguelite. No backend, account, API keys, or runtime packages are required. Artwork is drawn procedurally on Canvas.

## Play without a server

Download `wildfall.html` and open it directly in your browser. It contains all code and artwork and works offline. To regenerate it after editing the source, run `npm run build`.

## Run

Requires Node.js 20 or newer (the cloud environment has Node.js 24).

```sh
cd /workspace/Codex
npm run dev
```

The server listens on port 3000 on all interfaces. Set `PORT` to select another port. Open the served page in your browser through your platform's port access, or run locally with Node.js. You can also serve the repository with any static HTTP server. Keep `src` alongside `index.html`.

```sh
npm test
```

Tests cover combat, movement, progression, purchases, cooldowns, boss patterns, and the win/lose loop. No build step is needed; the browser uses native ES modules.

## Play

- **WASD / arrow keys:** Move. Bolts automatically target the nearest enemy.
- **Space:** Dash, with brief invulnerability. Recharges in 2.6 seconds.
- **E:** Arcane nova, once unlocked. Damages nearby enemies and clears nearby projectiles.
- **B:** Open the shop. Time stops while shopping.
- **Escape:** Pause / resume. Losing browser focus also pauses the game.
- Touch movement, dash, and ability buttons appear on small screens.

Collect purple XP shards to level up and choose one of three stacking upgrades. Collect gold coins to buy upgrades. The shop offers healing, damage, arcane nova (level 2), slowing bolts (level 3), triple shot (level 4), and regeneration (level 5).

Survive nine waves. Regular waves last 25 seconds; guardian waves end when the boss falls. You heal 15 between waves. The Briar King charges at you on wave 3, the Frost Oracle fires radial barrages on wave 6, and the Hollow Monarch fires spirals and summons minions on wave 9. Defeat all three to win.

Coins, levels, and abilities reset each run. Your highest defeat count persists in this browser's local storage. Sound is optional and off by default.

## Files

- `src/game.js`: DOM-independent simulation and progression rules.
- `src/main.js`: Canvas art, UI, sound, and input.
- `src/style.css`: Responsive interface.
- `server.mjs`: Dependency-free local development server.

The environment is already isolated. Work in the existing checkout; a separate Git worktree is unnecessary.

## Publish on GitHub Pages

The included `.github/workflows/pages.yml` tests and builds the game, then deploys only `dist/` to GitHub Pages. The output is self-contained and works under the `/Codex/` project path without external assets or packages. No secrets are required for the workflow beyond GitHub’s built-in token.

1. Push the game and workflow to the repository’s `main` branch.
2. In GitHub, open **Settings → Pages → Build and deployment** and set **Source** to **GitHub Actions**.
3. Under **Actions**, run **Publish Wildfall to GitHub Pages** (or rerun it if the initial push happened before Pages was enabled).
4. When the deployment succeeds, GitHub displays the site address on the Pages settings page and in the workflow’s deployment summary. The expected default address is `https://maddoxmoye.github.io/Codex/`; it is playable only after deployment succeeds.

Subsequent pushes to `main` test and redeploy automatically. If this is a private repository, Pages availability depends on the account plan.
