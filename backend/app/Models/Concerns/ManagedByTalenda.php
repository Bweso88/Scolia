<?php

namespace App\Models\Concerns;

use App\Support\Talenda\ManagedByTalendaException;
use App\Support\Talenda\Talenda;
use App\Support\Talenda\TalendaSync;
use Illuminate\Database\Eloquent\Model;

/**
 * Fiche synchronisée depuis Talenda, la référence de l'école
 * (docs/JONCTION_TALENDA.md) : ses champs venus de Talenda ne se modifient
 * pas dans Scolia, et la fiche ne se supprime pas, sauf par la
 * synchronisation elle-même. Une école reliée ne crée plus ces fiches dans
 * Scolia. Les champs propres à Scolia (photo,
 * activation…) restent modifiables.
 *
 * Le modèle déclare la colonne qui porte le lien (talendaLinkColumn) et
 * les champs gérés par Talenda (talendaManagedAttributes).
 */
trait ManagedByTalenda
{
    public static function bootManagedByTalenda(): void
    {
        static::creating(function (Model $model): void {
            if ($model->createdInTalenda() && ! TalendaSync::isRunning() && Talenda::connected()) {
                throw new ManagedByTalendaException;
            }
        });

        static::updating(function (Model $model): void {
            if ($model->isManagedByTalenda() && ! TalendaSync::isRunning() && $model->isDirty($model->talendaManagedAttributes())) {
                throw new ManagedByTalendaException;
            }
        });

        static::deleting(function (Model $model): void {
            if ($model->isManagedByTalenda() && ! TalendaSync::isRunning()) {
                throw new ManagedByTalendaException;
            }
        });
    }

    public function isManagedByTalenda(): bool
    {
        return $this->getOriginal($this->talendaLinkColumn()) !== null;
    }

    /**
     * Une école reliée à Talenda crée ces fiches dans Talenda, pas ici.
     */
    public function createdInTalenda(): bool
    {
        return true;
    }

    public function talendaLinkColumn(): string
    {
        return 'talenda_uuid';
    }

    /**
     * @return list<string>
     */
    abstract public function talendaManagedAttributes(): array;
}
