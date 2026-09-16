<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Http\Resources\Api\V1\SubjectResource;
use App\Models\Subject;

/**
 * Donnée de référence simple (matières de l'école), utile aux formulaires
 * (saisie de devoir/note, emploi du temps) côté mobile et back-office.
 * Lecture ouverte à tout utilisateur authentifié de l'école : ce n'est pas
 * une donnée sensible, contrairement aux élèves ou aux notes.
 */
class SubjectController extends Controller
{
    public function index()
    {
        return SubjectResource::collection(Subject::orderBy('name')->get());
    }
}
