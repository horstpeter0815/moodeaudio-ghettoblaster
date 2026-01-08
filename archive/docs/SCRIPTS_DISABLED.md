# Scripts deaktiviert

## Status: ✅ Alle Scripts sind deaktiviert

Alle Scripts haben keine Ausführungsrechte mehr.

### Um Scripts wieder zu aktivieren:

```bash
# Einzelnes Script
chmod +x <script-name>

# Alle Scripts
find . -maxdepth 1 -name "*.sh" -type f -exec chmod +x {} \;
find . -maxdepth 1 -name "*.py" -type f -exec chmod +x {} \;
```

### Oder mit DISABLE_SCRIPTS.sh:

```bash
chmod +x DISABLE_SCRIPTS.sh
./DISABLE_SCRIPTS.sh
```

---

**Deaktiviert:** $(date)

