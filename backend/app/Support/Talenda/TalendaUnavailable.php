<?php

namespace App\Support\Talenda;

use RuntimeException;

/**
 * Talenda ne répond pas, ou refuse la clé de l'école.
 */
class TalendaUnavailable extends RuntimeException {}
