# 🔧 NAS MANUELL MOUNTEN - ALTERNATIVE METHODEN

**Problem:** `mount_smbfs: server rejected the connection: Authentication error`

---

## 🔍 METHODE 1: Finder verwenden (EMPFOHLEN)

1. **Finder öffnen**
2. **Cmd+K** drücken (oder: Gehe zu > Mit Server verbinden)
3. **Adresse eingeben:**
   ```
   smb://fritz.box/IllerNAS
   ```
4. **Verbinden klicken**
5. **Als Benutzer anmelden:**
   - Benutzername: `Andre`
   - Passwort: (Ihr Fritz Box Passwort)
6. **Nach erfolgreichem Mount:**
   - Das NAS erscheint in Finder
   - Mount-Point ist normalerweise: `/Volumes/IllerNAS`

---

## 🔍 METHODE 2: Terminal mit interaktivem Passwort

```bash
# Mount-Point erstellen
mkdir -p ~/fritz-nas-archive

# Mounten (wird Passwort interaktiv abfragen)
mount_smbfs //Andre@fritz.box/IllerNAS ~/fritz-nas-archive
```

Das System fragt dann nach dem Passwort.

---

## 🔍 METHODE 3: Mit Domain

```bash
mkdir -p ~/fritz-nas-archive
mount_smbfs //Andre@fritz.box/IllerNAS ~/fritz-nas-archive -o domain=WORKGROUP
```

---

## 🔍 METHODE 4: Share-Name prüfen

Möglicherweise ist der Share-Name anders. Prüfen Sie verfügbare Shares:

```bash
smbutil view //fritz.box
```

Oder mit Authentifizierung:
```bash
smbutil view //Andre@fritz.box
```

---

## ✅ NACH ERFOLGREICHEM MOUNT

Prüfen Sie ob das NAS gemountet ist:

```bash
mount | grep smbfs
df -h | grep IllerNAS
```

Dann können Sie `ARCHIVE_TO_NAS.sh` verwenden (nach Anpassung des Mount-Points im Script).

---

**Tipp:** Finder-Methode ist am einfachsten und zuverlässigsten!

