# Contributing

This is a small macOS utility. Keep changes focused and easy to explain.

1. Describe the problem in an issue, especially if it affects the CLI integration.
2. Make the smallest useful change in the appropriate module.
3. Add tests when parsing, transport, or alert behavior changes.
4. Run `./scripts/test.sh` and `./scripts/build.sh` on macOS.
5. Include manual checks and any remaining limits in the pull request.

Use synthetic data in tests and examples. Do not commit account responses, credentials, usage histories, local build products, or screenshots containing private information.

The repository currently has no license file. Resolve licensing with the owner before assuming permission to redistribute it or submit reusable code under particular terms.
