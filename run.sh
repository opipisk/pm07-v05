#!/usr/bin/env bash
# ПМ.07, вариант 05 (гостиница). Каркас маршрута MariaDB 10 · Linux.
# Обязательная операция варианта: сжатие старых бэкапов .sql в .sql.gz
# и удаление архивов старше 14 суток.
set -Eeuo pipefail
umask 077

WORK="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$WORK/config.env"

mkdir -p "$WORK/out" "$WORK/backups" "$WORK/logs"
LOG="$WORK/logs/run.log"
STAMP="$(date +%Y%m%d_%H%M%S)"

log() { printf '%s [%s] %s\n' "$(date -Is)" "$1" "$2" >> "$LOG"; }
trap 'rc=$?; log ERROR "exit=$rc"; exit "$rc"' ERR

db_query() {
    "$CLIENT" --defaults-file="$AUTH" --batch --raw --skip-column-names \
        --database="$DB" --execute="$1"
}

dump_db() {
    "$DUMP" --defaults-file="$AUTH" --single-transaction \
        --default-character-set=utf8mb4 --result-file="$1" "$DB"
}

run_task() {
    local retention_days="${RETENTION_DAYS:-14}"
    local gzip_level="${GZIP_LEVEL:-6}"
    local mtime_days=$(( retention_days - 1 ))
    local compressed=0 deleted=0
    local file old

    if (( retention_days < 1 )); then
        log ERROR "RETENTION_DAYS=$retention_days must be >= 1"
        return 2
    fi
    log INFO "params retention_days=$retention_days gzip_level=$gzip_level"

    shopt -s nullglob
    for file in "$WORK/backups/${DB}_"*.sql; do
        gzip -"$gzip_level" -- "$file"
        compressed=$(( compressed + 1 ))
        log INFO "compressed=${file}.gz"
    done

    while IFS= read -r old; do
        rm -f -- "$old"
        deleted=$(( deleted + 1 ))
        log INFO "retention_deleted=$old"
    done < <(find "$WORK/backups" -maxdepth 1 -type f -name "${DB}_*.sql.gz" -mtime +"$mtime_days" -print)

    log INFO "compression and retention completed compressed=$compressed deleted=$deleted"
}

log INFO "START db=$DB"
run_task
log INFO "END result=OK"
exit 0
