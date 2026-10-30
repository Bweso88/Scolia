<?php

use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Schedule;

Artisan::command('inspire', function () {
    $this->comment(Inspiring::quote());
})->purpose('Display an inspiring quote');

// Jonction Talenda (docs/JONCTION_TALENDA.md) : élèves, classes, matières,
// enseignants et parents viennent de Talenda.
Schedule::command('scolia:talenda-sync')->everyFifteenMinutes()->withoutOverlapping()->onOneServer();
