#!/usr/bin/env bash
set -euo pipefail

# Declare (and optionally deploy) stark_loot, then verify the class on Voyager.
#
# stark_loot is stateless -- `struct Storage {}` is empty and every entrypoint takes
# @ContractState -- so consumers can use it via library_call with only the class hash.
# Declaration alone is therefore sufficient for library use, and is the default here.
# An instance is only needed for off-chain reads (JSON-RPC starknet_call targets an
# address, not a class hash) or for call_contract_syscall. An instance can be deployed
# from the same class hash later, at any time, without re-declaring.
#
# Signing uses sncast throughout. It reads the starknet-foundry accounts file directly, so no
# private key is placed in .env, passed on the command line, or exposed to the
# process table.
#
# Usage:
#   ./scripts/deploy.sh --account <name>                  # declare + verify
#   ./scripts/deploy.sh --account <name> --estimate-only   # fee estimate, sends nothing
#   ./scripts/deploy.sh --account <name> --deploy-instance # also deploy an instance
#   ./scripts/deploy.sh --account <name> --no-verify       # skip Voyager submission
#
#   RPC_URL='https://...' ./scripts/deploy.sh --account <name>
#
# List available accounts with: sncast account list

ACCOUNT="${STARKNET_ACCOUNT:-}"
DEPLOY_INSTANCE=false
RUN_VERIFY=true
ESTIMATE_ONLY=false
LICENSE="${LICENSE:-MIT}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    -a|--account) ACCOUNT="$2"; shift ;;
    --deploy-instance) DEPLOY_INSTANCE=true ;;
    --no-verify) RUN_VERIFY=false ;;
    --estimate-only) ESTIMATE_ONLY=true ;;
    --license) LICENSE="$2"; shift ;;
    -h|--help) sed -n '3,28p' "$0"; exit 0 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
  shift
done

# Values supplied on the command line win over .env, so the target network can be
# stated explicitly at the call site instead of being edited into a secrets file.
PRESET_RPC_URL="${RPC_URL:-}"

if [[ -f .env ]]; then
  set -a
  # shellcheck disable=SC1091
  source .env
  set +a
fi

[[ -n "$PRESET_RPC_URL" ]] && RPC_URL="$PRESET_RPC_URL"

if [[ -z "${RPC_URL:-}" ]]; then
  echo "Error: RPC_URL is not set. Put it in .env or pass it inline:" >&2
  echo "    RPC_URL='https://...' ./scripts/deploy.sh --account <name>" >&2
  exit 1
fi

list_accounts() {
  echo "Available accounts:" >&2
  sncast account list 2>/dev/null | awk '/^- /{name=$2} /network:/{print "    " name " (" $2 ")"}' >&2
}

if [[ -z "$ACCOUNT" ]]; then
  echo "Error: no account selected. Pass --account <name>." >&2
  echo >&2
  list_accounts
  exit 1
fi

# sncast identifies accounts by name, not by descriptor path. A STARKNET_ACCOUNT that
# points at an accounts JSON file would otherwise reach sncast as a nonsensical name.
if [[ "$ACCOUNT" == */* || "$ACCOUNT" == *.json ]]; then
  echo "Error: --account expects an sncast account NAME, not a file path." >&2
  echo "       Got: $ACCOUNT" >&2
  echo "       Remove STARKNET_ACCOUNT from .env (sncast reads the accounts file itself)," >&2
  echo "       and pass --account <name> instead. .env now needs only RPC_URL." >&2
  echo >&2
  list_accounts
  exit 1
fi

for tool in scarb sncast jq; do
  command -v "$tool" >/dev/null 2>&1 || { echo "Error: $tool is required but not installed." >&2; exit 1; }
done
if [[ "$RUN_VERIFY" == true ]]; then
  command -v voyager >/dev/null 2>&1 || { echo "Error: voyager is required for verification (or pass --no-verify)." >&2; exit 1; }
fi

# Ask sncast for the class hash. It builds with the same profile it declares with
# (release), so the hash reported here is by construction the one that reaches the
# chain. Computing it from a separately-built artifact risks hashing the dev profile,
# which emits different Sierra and therefore a different class hash.
echo "Building stark_loot and computing class hash..."
CLASS_HASH=$(sncast utils class-hash --contract-name stark_loot 2>&1 \
  | sed -n 's/^Class Hash:[[:space:]]*\(0x[0-9a-fA-F]*\).*/\1/p' | tail -1)
if [[ ! "$CLASS_HASH" =~ ^0x[0-9a-fA-F]+$ ]]; then
  echo "Error: could not compute class hash for contract 'stark_loot'." >&2
  sncast utils class-hash --contract-name stark_loot >&2 || true
  exit 1
fi

# Confirm which chain we are about to spend on before signing anything.
CHAIN_ID_HEX=$(curl -s --max-time 20 -X POST "$RPC_URL" -H 'Content-Type: application/json' \
  -d '{"jsonrpc":"2.0","id":1,"method":"starknet_chainId","params":[]}' | jq -r '.result // empty')
CHAIN_NAME=$(printf '%s' "${CHAIN_ID_HEX#0x}" | xxd -r -p 2>/dev/null || true)

case "$CHAIN_NAME" in
  SN_MAIN) VERIFY_NETWORK="mainnet" ;;
  SN_SEPOLIA) VERIFY_NETWORK="sepolia" ;;
  *) VERIFY_NETWORK="" ;;
esac

echo "RPC_URL:    $RPC_URL"
echo "Chain:      ${CHAIN_NAME:-unknown} ($CHAIN_ID_HEX)"
echo "Account:    $ACCOUNT"
echo "Class hash: $CLASS_HASH"
if [[ "$ESTIMATE_ONLY" == true ]]; then
  echo "Mode:       estimate only (nothing will be sent)"
else
  echo "Mode:       $([[ "$DEPLOY_INSTANCE" == true ]] && echo 'declare + deploy instance' || echo 'declare only (library use)')"
fi
echo

# ------------------------------------------------------------------- estimate only
if [[ "$ESTIMATE_ONLY" == true ]]; then
  estimate_output=$(sncast --account "$ACCOUNT" declare --contract-name stark_loot \
    --url "$RPC_URL" --dry-run --detailed 2>&1) || true
  echo "$estimate_output"
  echo
  # Fee estimation runs the declare against the current state, so an already-declared
  # class surfaces here as an execution error. That is the answer, not a failure.
  if grep -qi "is already declared" <<<"$estimate_output"; then
    echo "This class is already declared on $CHAIN_NAME; there is nothing to pay for."
    echo "To verify it on Voyager without re-declaring:"
    echo "  voyager verify --network ${VERIFY_NETWORK:-mainnet} --class-hash 0x$(sed 's/^0*//' <<<"${CLASS_HASH#0x}") \\"
    echo "    --contract-name stark_loot --license $LICENSE --lock-file --watch"
  else
    echo "Nothing was sent. Re-run without --estimate-only to declare."
  fi
  exit 0
fi

mkdir -p deployments
TS=$(date +%s)
LOG_FILE="deployments/log-$TS.txt"
log_line() { echo "$1" | tee -a "$LOG_FILE"; }

log_line "timestamp=$TS"
log_line "rpc_url=$RPC_URL"
log_line "chain=${CHAIN_NAME:-unknown}"
log_line "account=$ACCOUNT"
log_line "class_hash=$CLASS_HASH"

# ------------------------------------------------------------------------- declare
echo
echo "Declaring class $CLASS_HASH ..."
declare_output=$(sncast --account "$ACCOUNT" declare --contract-name stark_loot --url "$RPC_URL" 2>&1) || {
  echo "$declare_output" >&2
  # An already-declared class is not a failure: the class hash is what matters, and
  # verification below works against it regardless of who declared it.
  if grep -qi "is already declared\|ClassAlreadyDeclared" <<<"$declare_output"; then
    echo "Class is already declared on chain; continuing to verification." >&2
    log_line "declare=already-declared"
  else
    echo "Error: declare failed." >&2
    exit 1
  fi
}
echo "$declare_output"

# Match the labelled field. A bare "last hex string" grep picks up the class hash from
# sncast's trailing "to deploy, run: ... --class-hash 0x..." hint instead of the tx.
DECLARE_TX=$(sed -n 's/^Transaction Hash:[[:space:]]*\(0x[0-9a-fA-F]*\).*/\1/p' <<<"$declare_output" | tail -1)
log_line "declare_tx=${DECLARE_TX:-none (already declared)}"

# ------------------------------------------------------------------------- deploy
CONTRACT_ADDRESS=""
if [[ "$DEPLOY_INSTANCE" == true ]]; then
  echo
  echo "Deploying an instance (stark_loot has no constructor) ..."
  deploy_output=$(sncast --account "$ACCOUNT" deploy --class-hash "$CLASS_HASH" --url "$RPC_URL" 2>&1) || {
    echo "$deploy_output" >&2
    echo "Error: deploy failed. The class is still declared and usable via library_call." >&2
    exit 1
  }
  echo "$deploy_output"
  CONTRACT_ADDRESS=$(grep -oE 'contract_address: *0x[0-9a-fA-F]+' <<<"$deploy_output" | grep -oE '0x[0-9a-fA-F]+' | tail -1)
  log_line "contract_address=${CONTRACT_ADDRESS:-unknown}"
else
  log_line "contract_address=none (declare-only; use library_call with the class hash)"
fi

# ------------------------------------------------------------------------- verify
if [[ "$RUN_VERIFY" == true ]]; then
  echo
  if [[ -z "$VERIFY_NETWORK" ]]; then
    echo "Warning: unrecognised chain '${CHAIN_NAME:-}'; skipping verification." >&2
    log_line "verification=skipped (unknown chain)"
  else
    # Voyager's examples use the canonical short form; sncast reports 64 hex digits,
    # left-padded. Normalising costs nothing and keeps the API path consistent.
    CANON_HASH="0x$(sed 's/^0*//' <<<"${CLASS_HASH#0x}")"

    # Voyager indexes new classes some minutes behind the chain. Submitting before it
    # has caught up returns 400 "Invalid contract address or class hash", which reads
    # like a malformed request but simply means "not indexed yet". Wait for its
    # indexer rather than reporting a spurious failure.
    if [[ -n "$(command -v voyager)" ]]; then
      echo "Waiting for Voyager to index the class ..."
      for _ in $(seq 1 "${VERIFY_INDEX_ATTEMPTS:-40}"); do
        if ! voyager check --network "$VERIFY_NETWORK" --class-hash "$CANON_HASH" 2>&1 \
             | grep -q "not found on-chain"; then
          break
        fi
        sleep "${VERIFY_INDEX_INTERVAL:-30}"
      done
    fi

    echo "Submitting source to Voyager ($VERIFY_NETWORK) ..."
    # Verification is keyed on the class hash, so it works for declare-only classes.
    if voyager verify --network "$VERIFY_NETWORK" --class-hash "$CANON_HASH" \
         --contract-name stark_loot --license "$LICENSE" --lock-file --watch; then
      log_line "verification=submitted (license=$LICENSE)"
    else
      echo "Warning: Voyager verification did not succeed." >&2
      echo "         The class is declared regardless; retry with:" >&2
      echo "         voyager verify --network $VERIFY_NETWORK --class-hash $CANON_HASH --contract-name stark_loot --license $LICENSE --lock-file --watch" >&2
      log_line "verification=failed"
    fi
  fi
else
  log_line "verification=skipped"
fi

echo
echo "Done."
echo "Class hash: $CLASS_HASH"
[[ -n "$CONTRACT_ADDRESS" ]] && echo "Contract address: $CONTRACT_ADDRESS"
echo "Log written to $LOG_FILE"
