# Deliverable verification

Observed after final assembly: v3 has 15 current top-level PNG screen names excluding .v3a variants; v4 has exactly the same 15 PNG names, no missing or extra screen names. All 15 labelled -sbs.jpg boards, _sheet.jpg and SCORES.md exist and were visually inspected. Each board uses ours left/reference right; reference game name and source-video upload date are labelled from refs3/frames.json. Prompts, source selection and subjective checklist results are saved in PROMPTS.md and MANIFEST.json.

Native image dimensions: hud-phone 1843x853 and first-5-min 1844x853 (phone landscape); the remaining 13 PNGs 1672x941 (approximately 16:9). Comparisons use two equal 1280x720 fit regions without cropping. Zone strips retain three player-camera views per source image. Final sheet is 1680x1940.

All artwork redraws/refinements used built-in image_gen. System.Drawing was used only for requested labelled comparison/contact-sheet assembly. Existing v3 assembly code was read and its approach reused; no third-party game art was inserted into the concept PNGs. Reference frames are study/comparison evidence, not licensed production assets. The supplied tools licence is GPL; no tool or reference was added to game dependencies.

Only v4 artifacts were written during this task. Existing source-code/worktree modifications were observed in git status; no game-code edits, git add, commit or reset was performed. No code tests were run because this task changed concept artifacts only. Script execution policy was not changed; assembly ran as ordinary interactive PowerShell script-block commands. No Desktop copy was made because the user explicitly requested v4 and this workspace is the writable destination.

Self-scores are not independent blind judgement or owner acceptance. Pixel-exact generated palette compliance, runtime screenshots, animation timing, phone usability and game performance remain UNKNOWN.
