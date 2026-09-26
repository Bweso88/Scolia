<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Http\Resources\Api\V1\SchoolYearResource;
use App\Models\SchoolYear;

/**
 * Donnée de référence simple, nécessaire au formulaire de création d'une
 * classe (choix de l'année scolaire) — lecture seule pour l'instant, la
 * création d'année scolaire restant manuelle (hors MVP).
 */
class SchoolYearController extends Controller
{
    public function index()
    {
        return SchoolYearResource::collection(SchoolYear::orderByDesc('start_date')->get());
    }
}
