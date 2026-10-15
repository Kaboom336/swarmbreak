# Vendored dependencies

Copied from the owner-approved local vendor tree with only line endings/trailing whitespace normalized by apply_patch; no vendor scripts executed. Source equivalence is checked after that normalization.

| Module | Source | Licence |
|---|---|---|
| ProfileStore.luau | MadStudioRoblox/ProfileStore, vendor/profilestore/ProfileStore.luau | Apache-2.0, ProfileStore-LICENSE |
| Shake.luau | Sleitnick/RbxUtil modules/shake/init.luau | MIT, RbxUtil-LICENSE |
| Spring.luau | Sleitnick/RbxUtil modules/spring/init.luau | MIT, RbxUtil-LICENSE |
| Signal.luau | Sleitnick/RbxUtil modules/signal/init.luau | MIT, RbxUtil-LICENSE |
| Trove.luau | Sleitnick/RbxUtil modules/trove/init.luau | MIT, RbxUtil-LICENSE |

Read implementation and API contracts before integration. ProfileStore owns session locking/auto saving and asynchronous save acknowledgement. Shake/Signal/Trove have no external runtime package dependencies; Spring calls Roblox TweenService:SmoothDamp. Offline tests use MockStore's contract fixture; CoreLoopTest also exercises the actual ProfileStore.Mock in Studio. Package hashes are in prototype/KITS-DEPENDENCIES.json. Keep these source files and licence notices together on redistribution.
