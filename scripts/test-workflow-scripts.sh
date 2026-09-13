#!/bin/sh
# Validate .github/workflows/build.yml run scripts against the CI environment.
#
# 1. Every `run:` block must be valid POSIX sh for /bin/sh (dash on trixie).
# 2. The publish step is EXECUTED with a stub curl and fixture .debs, then
#    asserted: sanitized tag, no dbgsym upload, exactly 6 assets, notes written.
#
# Run inside debian:trixie (same shell/curl family as the CI job), e.g.:
#   docker run --rm -v "$PWD:/repo" -w /repo debian:trixie sh scripts/test-workflow-scripts.sh
set -eux
cd "$(dirname "$0")/.."

python3 scripts/extract-step-scripts.py .github/workflows/build.yml /tmp/wf-steps

# --- 1. syntax gate -----------------------------------------------------------
found=0
for s in /tmp/wf-steps/*.sh; do
    [ -f "$s" ] || continue
    found=1
    dash -n "$s"
done
[ "$found" -eq 1 ]

# --- 2. behavior gate: execute the publish step with stubs --------------------
STEP=$(ls /tmp/wf-steps/*[Pp]ublish*.sh)
T=$(mktemp -d)
mkdir -p "$T/bin" "$T/work"
for f in \
    kicad_10.0.6+dfsg-0~local1_amd64.deb \
    kicad-libraries_10.0.6+dfsg-1_all.deb \
    kicad-symbols_10.0.6-1_all.deb \
    kicad-footprints_10.0.6-1_all.deb \
    kicad-templates_10.0.0-1_all.deb \
    kicad-demos_10.0.6+dfsg-1_all.deb \
    kicad-dbgsym_10.0.6+dfsg-0~local1_amd64.deb
do
    : > "$T/work/$f"
done
echo 'deadbeef  kicad_10.0.6+dfsg-0~local1_amd64.deb' > "$T/work/SHA256SUMS"

CURL_LOG="$T/curl.log"
export CURL_LOG
cat > "$T/bin/curl" <<'STUB'
#!/bin/sh
# stub curl: record the invocation, return canned responses
echo "CURL $*" >> "$CURL_LOG"
case "$*" in
    */releases/tags/*)                            exit 22 ;;  # release absent -> create path
    *api.github.com/repos/*/releases*)            echo '{"id": 424242}' ;;
    *uploads.github.com*)                         echo '{"name": "stub-asset"}' ;;
    *) echo "stub curl: unhandled args: $*" >&2;  exit 64 ;;
esac
STUB
chmod +x "$T/bin/curl"

(
    cd "$T/work"
    PATH="$T/bin:$PATH" \
    GITHUB_TOKEN=stub-token \
    GITHUB_REPOSITORY=intel-agency/kicad-trixie-backport \
    GITHUB_SHA=0123456789abcdef0123456789abcdef01234567 \
    SOURCE_VERSION=10.0.6+dfsg-1 \
    LOCAL_VERSION=10.0.6+dfsg-0~local1 \
    FUTURE_BPO=10.0.6+dfsg-1~bpo13+1 \
    RUN_TESTS=true \
    POOL_BASE=https://deb.debian.org/debian/pool/main/k/kicad \
        dash -e "$STEP"
)

# --- 3. assertions ------------------------------------------------------------
grep -q 'releases/tags/v10.0.6+dfsg-0-local1' "$CURL_LOG"   # tag sanitized ~ -> -
grep -q -- '--fail-with-body' "$CURL_LOG"                   # loud failures preserved
grep -q 'releases/424242/assets' "$CURL_LOG"                # uploads hit the created release
if grep -q 'dbgsym' "$CURL_LOG"; then
    echo 'FAIL: dbgsym package was uploaded' >&2; exit 1
fi
uploads=$(grep -c 'uploads.github.com' "$CURL_LOG")
[ "$uploads" -eq 7 ]   # 1 amd64 kicad + 5 arch:all + SHA256SUMS
[ -s "$T/work/release-notes.md" ]
echo 'workflow script harness: PASS'
