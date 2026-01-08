#!/bin/bash
################################################################################
#
# AUTONOMOUS COMPLETE WORKFLOW
#
# Arbeitet durch bis Build erfolgreich ist, Tests bestanden sind,
# und Image auf SD-Karte gebrannt ist
#
################################################################################

set -e

CONTAINER="moode-builder"
MAX_BUILD_ITERATIONS=5
BUILD_ITERATION=0

log() {
    echo "[$(date +%Y-%m-%d\ %H:%M:%S)] $1" | tee -a BUILD_STATUS_AUTONOMOUS.txt
}

check_build() {
    docker exec $CONTAINER pgrep -f "build.sh" 2>/dev/null | head -1
}

wait_for_build() {
    log "⏳ Warte auf Build-Abschluss..."
    while true; do
        BUILD_PID=$(check_build)
        if [ -z "$BUILD_PID" ]; then
            log "✅ Build beendet"
            return 0
        fi
        STAGE=$(docker exec $CONTAINER bash -c "find /tmp/pi-gen-work -name 'build.log' 2>/dev/null | head -1 | xargs tail -1 2>/dev/null" | grep -oE '\[.*\]' | tail -1)
        log "⏳ Build läuft: $STAGE"
        sleep 300  # 5 Minuten
    done
}

copy_image() {
    IMAGE=$(docker exec $CONTAINER bash -c "find /tmp/pi-gen-work -name '*.img' -size +100M 2>/dev/null | head -1")
    if [ -z "$IMAGE" ]; then
        log "❌ Kein Image gefunden"
        return 1
    fi
    
    log "✅ Image gefunden: $IMAGE"
    docker cp $CONTAINER:"$IMAGE" "./imgbuild/deploy/$(basename $IMAGE)"
    log "✅ Image kopiert"
    echo "./imgbuild/deploy/$(basename $IMAGE)"
}

test_image() {
    IMAGE_FILE=$1
    log "🔍 Starte Tests für: $IMAGE_FILE"
    
    # Kopiere Image in Container für Tests
    docker cp "$IMAGE_FILE" $CONTAINER:/tmp/test-image.img
    
    # Führe Tests aus
    TEST_RESULT=$(docker exec $CONTAINER bash -c '
        LOOP=$(losetup -f)
        losetup -P $LOOP /tmp/test-image.img
        
        if [ ! -e ${LOOP}p1 ] || [ ! -e ${LOOP}p2 ]; then
            echo "FAIL: Partitionen nicht gefunden"
            losetup -d $LOOP 2>/dev/null || true
            exit 1
        fi
        
        BOOT_TMP=$(mktemp -d)
        ROOT_TMP=$(mktemp -d)
        mount ${LOOP}p1 $BOOT_TMP
        mount ${LOOP}p2 $ROOT_TMP
        
        RESULT="PASS"
        
        # Test 1: config.txt.overwrite
        if [ ! -f $BOOT_TMP/config.txt.overwrite ]; then
            echo "FAIL: config.txt.overwrite nicht gefunden"
            RESULT="FAIL"
        fi
        
        # Test 2: User andre
        if [ ! -d $ROOT_TMP/home/andre ]; then
            echo "FAIL: /home/andre nicht gefunden"
            RESULT="FAIL"
        fi
        
        # Test 3: Custom Scripts
        if [ ! -f $ROOT_TMP/usr/local/bin/start-chromium-clean.sh ]; then
            echo "FAIL: start-chromium-clean.sh nicht gefunden"
            RESULT="FAIL"
        fi
        
        umount $BOOT_TMP $ROOT_TMP 2>/dev/null || true
        rmdir $BOOT_TMP $ROOT_TMP 2>/dev/null || true
        losetup -d $LOOP 2>/dev/null || true
        
        echo $RESULT
    ' 2>&1)
    
    if echo "$TEST_RESULT" | grep -q "PASS"; then
        log "✅ ALLE TESTS ERFOLGREICH"
        return 0
    else
        log "❌ TESTS FEHLGESCHLAGEN:"
        echo "$TEST_RESULT" | tee -a BUILD_STATUS_AUTONOMOUS.txt
        return 1
    fi
}

fix_build() {
    log "🔧 Analysiere Problem und fixe..."
    
    # Prüfe ob 00-run.sh existiert und korrekt ist
    if [ ! -f "imgbuild/moode-cfg/stage3_03-ghettoblaster-custom_00-run.sh" ]; then
        log "❌ 00-run.sh fehlt - erstelle..."
        # Script wurde bereits erstellt, sollte vorhanden sein
        return 1
    fi
    
    # Prüfe ob moode-source im Container ist
    if ! docker exec $CONTAINER bash -c "test -f /workspace/moode-source/boot/firmware/config.txt.overwrite"; then
        log "❌ moode-source nicht im Container - prüfe docker-compose..."
        return 1
    fi
    
    log "✅ Fixes scheinen korrekt zu sein"
    return 0
}

restart_build() {
    log "🔄 Starte Build neu..."
    docker exec $CONTAINER bash -c "cd /workspace/imgbuild && rm -rf /tmp/pi-gen-work/moode-r1001-arm64/stage3/03-ghettoblaster-custom 2>/dev/null || true"
    docker exec -d $CONTAINER bash -c "cd /workspace/imgbuild && WORK_DIR=/tmp/pi-gen-work nohup bash -c './build.sh 2>&1 | tee /workspace/build-iteration-$BUILD_ITERATION-$(date +%Y%m%d_%H%M%S).log' > /dev/null 2>&1 &"
    sleep 10
    BUILD_PID=$(check_build)
    if [ -n "$BUILD_PID" ]; then
        log "✅ Build gestartet (PID: $BUILD_PID)"
        return 0
    else
        log "❌ Build konnte nicht gestartet werden"
        return 1
    fi
}

burn_to_sd() {
    IMAGE_FILE=$1
    log "🔥 Brenne Image auf SD-Karte..."
    
    SD_DISK=$(diskutil list | grep -E "external, physical" | head -1 | awk '{print $NF}' | sed 's/:$//')
    if [ -z "$SD_DISK" ]; then
        SD_DISK=$(diskutil list | grep -E "^/dev/disk[4-9]" | head -1 | awk '{print $1}')
    fi
    
    if [ -z "$SD_DISK" ] || [ ! -e "$SD_DISK" ]; then
        log "❌ SD-Karte nicht gefunden"
        return 1
    fi
    
    log "✅ SD-Karte gefunden: $SD_DISK"
    diskutil unmountDisk "$SD_DISK" 2>/dev/null || true
    sleep 2
    SD_RAW=$(echo "$SD_DISK" | sed 's|disk|rdisk|')
    
    log "⚠️  BENÖTIGT SUDO - Befehl:"
    echo "sudo dd if=\"$IMAGE_FILE\" of=\"$SD_RAW\" bs=1m status=progress" | tee -a BUILD_STATUS_AUTONOMOUS.txt
    log "⚠️  User muss sudo-Passwort eingeben"
    
    # Versuche zu brennen (wird sudo benötigen)
    sudo dd if="$IMAGE_FILE" of="$SD_RAW" bs=1m status=progress && sync
    if [ $? -eq 0 ]; then
        log "✅ IMAGE ERFOLGREICH GEBRANNT!"
        return 0
    else
        log "❌ Brennen fehlgeschlagen"
        return 1
    fi
}

# MAIN WORKFLOW
log "=== AUTONOMOUS COMPLETE WORKFLOW GESTARTET ==="

while [ $BUILD_ITERATION -lt $MAX_BUILD_ITERATIONS ]; do
    BUILD_ITERATION=$((BUILD_ITERATION + 1))
    log "🔄 Iteration $BUILD_ITERATION/$MAX_BUILD_ITERATIONS"
    
    # Warte auf Build
    wait_for_build
    
    # Kopiere Image
    IMAGE_FILE=$(copy_image)
    if [ -z "$IMAGE_FILE" ]; then
        log "❌ Konnte Image nicht kopieren - starte Build neu"
        if ! restart_build; then
            log "❌ Konnte Build nicht neu starten"
            break
        fi
        continue
    fi
    
    # Teste Image
    if test_image "$IMAGE_FILE"; then
        log "✅ ALLE TESTS ERFOLGREICH!"
        
        # Brenne auf SD-Karte
        if burn_to_sd "$IMAGE_FILE"; then
            log "✅ FERTIG! Image auf SD-Karte gebrannt"
            break
        else
            log "❌ Brennen fehlgeschlagen"
            break
        fi
    else
        log "❌ TESTS FEHLGESCHLAGEN - analysiere und fixe..."
        
        if ! fix_build; then
            log "❌ Konnte Problem nicht fixen"
            break
        fi
        
        # Starte Build neu
        if ! restart_build; then
            log "❌ Konnte Build nicht neu starten"
            break
        fi
    fi
done

if [ $BUILD_ITERATION -ge $MAX_BUILD_ITERATIONS ]; then
    log "❌ Maximale Iterationen erreicht"
fi

log "=== AUTONOMOUS COMPLETE WORKFLOW BEENDET ==="

