#!/bin/bash

# ---------- CONFIG ----------
PREFISSO_NUMERICO=true   # true = "001 - Titolo.mp3" (mantiene l'ordine della playlist)
# ----------------------------

PLAYLIST=$(osascript -e 'try' \
                     -e 'POSIX path of (choose file with prompt "Seleziona il file .m3u8" of type {"m3u8","m3u"})' \
                     -e 'end try')
[ -z "$PLAYLIST" ] && exit 0

DEST=$(osascript -e 'try' \
                 -e 'POSIX path of (choose folder with prompt "Seleziona la cartella di destinazione")' \
                 -e 'end try')
[ -z "$DEST" ] && exit 0

BASEDIR=$(dirname "$PLAYLIST")
LOG="${DEST}_report_copia.txt"
: > "$LOG"

urldecode() { local s="${1//+/ }"; printf '%b' "${s//%/\\x}"; }

copiati=0
mancanti=0
n=0

while IFS= read -r riga || [ -n "$riga" ]; do
    riga="${riga%$'\r'}"                       # toglie CR se il file è CRLF
    riga="${riga#"${riga%%[![:space:]]*}"}"    # trim iniziale
    [ -z "$riga" ] && continue
    case "$riga" in \#*) continue ;; esac

    # gestisce eventuali URL file://
    case "$riga" in
        file://*) riga=$(urldecode "${riga#file://}") ;;
    esac

    # path relativo -> risolto rispetto alla posizione della playlist
    case "$riga" in
        /*) SRC="$riga" ;;
         *) SRC="$BASEDIR/$riga" ;;
    esac

    n=$((n+1))
    NOME=$(basename "$SRC")

    if [ ! -f "$SRC" ]; then
        mancanti=$((mancanti+1))
        echo "MANCANTE: $SRC" >> "$LOG"
        continue
    fi

    if [ "$PREFISSO_NUMERICO" = true ]; then
        TARGET=$(printf "%s%03d - %s" "$DEST" "$n" "$NOME")
    else
        TARGET="${DEST}${NOME}"
    fi

    # evita sovrascritture: aggiunge _1, _2...
    if [ -e "$TARGET" ]; then
        BASE="${TARGET%.*}"; EXT="${TARGET##*.}"; i=1
        while [ -e "${BASE}_${i}.${EXT}" ]; do i=$((i+1)); done
        TARGET="${BASE}_${i}.${EXT}"
    fi

    if cp -p "$SRC" "$TARGET" 2>>"$LOG"; then
        copiati=$((copiati+1))
        echo "OK: $NOME" >> "$LOG"
    else
        mancanti=$((mancanti+1))
        echo "ERRORE COPIA: $SRC" >> "$LOG"
    fi
done < "$PLAYLIST"

osascript -e "display dialog \"Copia completata.

Brani in playlist: $n
Copiati: $copiati
Non trovati / errori: $mancanti

Report: $(basename "$LOG")\" buttons {\"OK\"} default button 1 with title \"Copia da M3U8\""