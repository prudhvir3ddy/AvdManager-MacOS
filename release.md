#### Release Process

1. **Tag a version**: Create and push a git tag starting with `v` (e.g., `v1.0.0`)
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```

2. **Automatic build**: GitHub Actions will automatically:
   - Build the app for Release
   - Create a DMG with installation setup
   - Generate checksums
   - Create a GitHub release with assets

#### Manual Trigger

You can also trigger the build manually from the GitHub Actions tab.

#### Release Assets

Each release includes:
- `AVD-Manager-{version}.dmg` - The installable DMG file
- `AVD-Manager-{version}.dmg.sha256` - SHA256 checksum for verification
