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
DEST="${DEST%/}"   # normalizza: niente slash finale

BASEDIR=$(dirname "$PLAYLIST")
LOG="${DEST}/_report_copia.txt"
: > "$LOG"

urldecode() { printf '%b' "${1//%/\\x}"; }   # niente conversione + -> spazio

# conta le righe valide per calcolare la larghezza del prefisso
TOTALE=$(grep -vc '^\s*#\|^\s*$' "$PLAYLIST")
WIDTH=${#TOTALE}
[ "$WIDTH" -lt 3 ] && WIDTH=3   # minimo 3 cifre come prima

copiati=0
mancanti=0
n=0

while IFS= read -r riga || [ -n "$riga" ]; do
    riga="${riga%$'\r'}"
    riga="${riga#"${riga%%[![:space:]]*}"}"
    [ -z "$riga" ] && continue
    case "$riga" in \#*) continue ;; esac

    case "$riga" in
        file://*) riga=$(urldecode "${riga#file://}") ;;
    esac

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
        TARGET=$(printf "%s/%0${WIDTH}d - %s" "$DEST" "$n" "$NOME")
    else
        TARGET="$DEST/$NOME"
    fi

    # evita sovrascritture: aggiunge _1, _2...
    if [ -e "$TARGET" ]; then
        if [[ "$TARGET" == *.* ]]; then
            BASE="${TARGET%.*}"; EXT=".${TARGET##*.}"
        else
            BASE="$TARGET"; EXT=""
        fi
        i=1
        while [ -e "${BASE}_${i}${EXT}" ]; do i=$((i+1)); done
        TARGET="${BASE}_${i}${EXT}"
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
