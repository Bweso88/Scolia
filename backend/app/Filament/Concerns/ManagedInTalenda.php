<?php

namespace App\Filament\Concerns;

use App\Support\Talenda\Talenda;
use Illuminate\Database\Eloquent\Model;

/**
 * Ressource dont Talenda est la référence quand l'école y est reliée
 * (docs/JONCTION_TALENDA.md) : pas de création dans Scolia, et les fiches
 * venues de Talenda ne se modifient ni ne se suppriment ici.
 */
trait ManagedInTalenda
{
    public static function canCreate(): bool
    {
        return ! Talenda::connected() && parent::canCreate();
    }

    public static function canEdit(Model $record): bool
    {
        return ! $record->isManagedByTalenda() && parent::canEdit($record);
    }

    public static function canDelete(Model $record): bool
    {
        return ! $record->isManagedByTalenda() && parent::canDelete($record);
    }

    public static function canDeleteAny(): bool
    {
        return ! Talenda::connected() && parent::canDeleteAny();
    }
}
