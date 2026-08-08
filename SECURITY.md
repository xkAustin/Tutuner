# Security Policy

## Supported Versions

Security fixes are applied to the latest code on the default branch and to the latest published release when one exists. Older development snapshots are not maintained.

## Reporting a Vulnerability

Please report suspected vulnerabilities privately through GitHub Security Advisories for this repository. If private reporting is unavailable, contact the repository owner privately before opening a public issue. Include the affected version, platform, reproduction conditions, impact, and the smallest safe proof needed to confirm the issue. Do not include credentials, private signing material, recordings, or other personal data.

## System and Scope

Tutuner is an offline Flutter guitar tuner and metronome for Android, iOS, macOS, and Windows. This policy covers application source, native runners, bundled audio and tuning assets, local settings persistence, build configuration, permissions, release signing, and third-party dependencies.

The application has no account, backend, telemetry, advertising SDK, web view, or product network client. Microphone PCM is processed in memory for pitch estimation and is not intentionally persisted or transmitted.

## Threat Model and Trust Boundaries

Important assets are microphone privacy, release package identity, local settings integrity, predictable real-time processing, and platform sandbox boundaries. Relevant boundaries include:

- operating-system microphone permission into native recording plugins and Dart audio processing;
- bundled assets and private application preferences into parsers and state restoration;
- developer or CI signing secrets into Android, Apple, and Windows release artifacts;
- third-party packages and native build tools into the application binary.

Assume an attacker may provide arbitrary acoustic input, deliver a malicious replacement package, influence public dependency infrastructure, or interact with exported platform entry points. A process already running with the same user privileges and direct write access to the application's private storage is not by itself a separate authorization boundary, but any escalation beyond those privileges remains reportable.

## Security Invariants

- Microphone access requires the platform permission and stops when tuning stops or the app leaves the active lifecycle state.
- Raw or derived microphone samples are not written to disk or sent over a network.
- Production artifacts never fall back to development signing credentials; missing release credentials fail closed.
- Signing keys and local signing properties are never committed to the repository.
- Release entitlements and manifests contain only capabilities required by the application.
- Untrusted data crossing a real process, privilege, package, or network boundary must be validated and processed with bounded resource use.

## Reportable Findings and Severity Context

A reportable issue must show a realistic path from attacker-controlled input or compromised infrastructure to confidentiality, integrity, availability, privilege, sandbox, or release-identity impact. Severity depends on reachability, required privileges, affected platforms, user interaction, persistence, and whether a shipped release is exposed.

Examples include microphone capture outside the stated lifecycle, an unexpected network or file sink for audio, signing-key exposure or release-signing bypass, exploitable exported components, dependency compromise, sandbox escape, or externally triggerable unbounded processing.

## Out of Scope and Limitations

The following are reliability concerns rather than security findings unless they cross a real trust boundary or produce additional impact:

- corruption performed only by the same user directly editing the application's private preference files;
- modification of bundled assets that already requires replacing or re-signing the installed application;
- malformed buffers supplied only by native code already executing inside the application process;
- physical-device latency, tuning accuracy, accessibility quality, and general UI defects without a security impact.

Platform signing, notarization, store review, permission behavior, and acoustic performance still require validation in the relevant release environment and on physical devices.
