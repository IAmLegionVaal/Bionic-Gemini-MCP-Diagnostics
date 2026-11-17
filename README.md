# Bionic local model + Gemini MCP timeout diagnostics

**Status: not resolved in the source incident.** A Node.js MCP server script was initially zero bytes. Following reconstruction the script was nonempty (2501 bytes in a subsequent check), passed `node --check`, and Bionic displayed one tool ready. A later Gemini invocation nevertheless timed out.

## Separate the layers
1. **File present?** `(Get-Item "$HOME\Bionic-Gemini-MCP\server.mjs").Length` must be nonzero.
2. **Syntax?** `node --check "$HOME\Bionic-Gemini-MCP\server.mjs"` validates grammar but not behavior.
3. **Runtime?** Check `node --version`; PowerShell execution policy may require `npm.cmd`, not `npm.ps1`.
4. **Local endpoint?** Independently check the configured LM Studio local model API, e.g. `http://localhost:1235/v1/models`.
5. **MCP handshake?** Confirm expected tool names appear in Bionic.
6. **Tool call?** Invoke harmless test and record elapsed time and error class.
7. **Cloud API?** Check outbound DNS/TLS, model availability, permissions, quota and server-timeout settings. Retry 429/5xx with bounded backoff; do not retry 401/403 blindly.
8. **Search grounding?** Prior Gemini API test returned HTTP 200 with `searchEnabled=false` and `groundingObserved=false`; do not advertise internet research until explicitly enabled and verified.

## Safe preflight
```powershell
.\scripts\Test-BionicMcpPreflight.ps1 -ServerScript "$HOME\Bionic-Gemini-MCP\server.mjs" -LocalApiUrl 'http://localhost:1235/v1/models'
```
No working Gemini server source or credentials are included because no complete source implementation has been verified. Store keys in an environment variable / secret manager, never Git.

The standalone preflight accepts trusted `.mjs` files and localhost/127.0.0.1
URLs without query strings or fragments. Redirects are disabled. A failed local
HTTP check raises an error; it is not reported as a successful preflight. Node's
syntax diagnostics may include source excerpts and local paths: keep terminal
output private. A successful HTTP response is only reachability, not validation
of the API schema or an MCP handshake.

## Acceptance
At least several successful calls, controlled timeout and offline failure behavior, no sensitive logs, and an independent grounding test. These have not all been observed.

## Repository scope and operating boundaries

This standalone project separates the historical incident outcome from the
diagnostic tooling. The script collects a narrow set of checks; it does not
automatically perform the manual recovery steps described above. Start with a
nonproduction test and capture a baseline before proposing a configuration
change. Use the least-privileged approved identity and preserve rollback values
in private change records. Stop when required inputs or authorization are missing.

## Evidence and acceptance record

For any new investigation, record the product/runtime versions, UTC observation
time, expected behavior, actual result, exact approved change, rollback owner,
and follow-up observation window in private storage. Publish only a redacted
summary. Mark hypotheses as hypotheses. A successful diagnostic command or green
CI run does not prove the business workflow works. Keep unresolved acceptance
items open until an authorized tester verifies the end-user result.

## Quality, security and licensing

- [Tests and limitations](TESTING.md): syntax, hygiene and isolated regressions.
- [Security guidance](SECURITY.md): safe execution and evidence handling.
- [Source and rights](PROVENANCE.md) and [MIT license](LICENSE).
- [CI runs](https://github.com/IAmLegionVaal/Bionic-Gemini-MCP-Diagnostics/actions/workflows/validate.yml).
- [Central incident index](https://github.com/IAmLegionVaal/IT-Support-Toolkit-Launcher/blob/main/incident-projects/README.md).
- [Publication and follow-up tracker](https://github.com/IAmLegionVaal/IT-Support-Toolkit-Launcher/issues/1).

Contributions should include synthetic regression coverage and an explicit
statement of what was actually tested. Do not attach raw client evidence to
issues or pull requests. Preserve the historical status unless new evidence
supports a change.
