# moOde Code Reading Session
**Date:** 2026-01-20  
**Goal:** Understand complete architecture without making fixes  
**Method:** Systematic reading of every component

---

## Reading Log

### Phase 1: System Startup Sequence

#### 1.1 Boot Process
- [ ] /etc/systemd/system/localdisplay.service
- [ ] /usr/lib/systemd/system/mpd.service
- [ ] /etc/systemd/system/fix-audioout-cdsp.service
- [ ] /lib/systemd/system/php8.4-fpm.service
- [ ] /lib/systemd/system/nginx.service

#### 1.2 worker.php Initialization
- [ ] /var/www/daemon/worker.php - main loop
- [ ] /var/www/daemon/worker.php - session loading
- [ ] /var/www/daemon/worker.php - audio initialization
- [ ] /var/www/daemon/worker.php - network setup

#### 1.3 Session Management
- [ ] /var/www/inc/session.php - phpSession function
- [ ] /var/www/inc/session.php - load_system
- [ ] /var/www/inc/session.php - load_radio
- [ ] /var/www/inc/session.php - purgeSessionFiles

#### 1.4 Database Schema
- [ ] cfg_system table structure
- [ ] cfg_radio table structure
- [ ] cfg_network table structure
- [ ] Session ID storage mechanism

---

### Phase 2: Web Request Handling

#### 2.1 nginx Configuration
- [ ] /etc/nginx/sites-available/moode-http.conf
- [ ] /etc/nginx/moode-locations.conf
- [ ] /etc/nginx/fastcgi_params
- [ ] Access log configuration

#### 2.2 PHP Processing
- [ ] /var/www/index.php - entry point
- [ ] /var/www/header.php - session start
- [ ] /var/www/footer.min.php - closing tags
- [ ] Template evaluation mechanism

#### 2.3 Template System
- [ ] /var/www/templates/indextpl.min.html
- [ ] getTemplate() function
- [ ] echoTemplate() evaluation
- [ ] Variable substitution

---

### Phase 3: JavaScript Initialization

#### 3.1 Script Loading
- [ ] How lib.min.js loads (defer attribute)
- [ ] How main.min.js loads (defer attribute)
- [ ] DOMContentLoaded event handling
- [ ] Script execution order

#### 3.2 Data Fetching
- [ ] /var/www/command/cfg-table.php
- [ ] /var/www/command/index.php
- [ ] AJAX request patterns
- [ ] Error handling in JavaScript

#### 3.3 UI Rendering
- [ ] Playlist loading mechanism
- [ ] Color/theme application
- [ ] View switching (playback vs library)
- [ ] current_view parameter usage

---

### Phase 4: Display System

#### 4.1 X11 Initialization
- [ ] /home/andre/.xinitrc
- [ ] fbset configuration
- [ ] xrandr rotation
- [ ] Display environment variables

#### 4.2 Chromium Startup
- [ ] Cache clearing (clearbrcache)
- [ ] --app flag behavior
- [ ] --kiosk mode behavior
- [ ] Offline cache mechanisms

---

## Findings

### Boot Sequence Timeline
```
WILL BE FILLED IN DURING READING
```

### Data Flow Architecture
```
WILL BE FILLED IN DURING READING
```

### Critical Code Sections
```
WILL BE FILLED IN DURING READING
```

### Potential Issues Identified
```
WILL BE FILLED IN DURING READING
```

---

## Next: Actual Reading

Starting systematic read-through...
