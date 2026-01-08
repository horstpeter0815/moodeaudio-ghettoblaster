<?php
/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Copyright 2014 The moOde audio player project / Tim Curtis
 * Copyright 2013 The tsunamp player ui / Andrea Coiutti & Simone De Gregori
 * 
 * FIXED VERSION: This file should be used as index.php if index.html redirects incorrectly
 */

require_once __DIR__ . '/inc/common.php';
require_once __DIR__ . '/inc/session.php';

phpSession('open');
$_SESSION['alt_back_link'] = '';
phpSession('close');

$section = basename(__FILE__, '.php');

$tpl = "indextpl.html";
include('header.php');
eval("echoTemplate(\"".getTemplate("/var/www/templates/$tpl")."\");");
include('footer.php');

