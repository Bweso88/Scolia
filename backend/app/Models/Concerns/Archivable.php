<?php

namespace App\Models\Concerns;

use App\Models\ItemArchive;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Relations\MorphMany;

/**
 * Permet à chaque utilisateur (parent ou enseignant) de masquer un élément
 * de sa propre liste — annonce, observation de comportement, conversation —
 * sans l'affecter pour les autres (docs/PRODUCT_ARCHITECTURE.md). Distinct
 * d'une suppression : réversible, et propre à qui l'a demandé.
 */
trait Archivable
{
    public function archives(): MorphMany
    {
        return $this->morphMany(ItemArchive::class, 'archivable');
    }

    public function scopeNotArchivedBy(Builder $query, int $userId): Builder
    {
        return $query->whereDoesntHave('archives', fn (Builder $q) => $q->where('user_id', $userId));
    }

    public function archiverPour(int $userId): void
    {
        $this->archives()->firstOrCreate(['user_id' => $userId]);
    }

    public function desarchiverPour(int $userId): void
    {
        $this->archives()->where('user_id', $userId)->delete();
    }
}
