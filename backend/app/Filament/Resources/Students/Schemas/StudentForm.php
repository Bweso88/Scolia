<?php

namespace App\Filament\Resources\Students\Schemas;

use App\Models\SchoolClass;
use Filament\Forms\Components\DatePicker;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\Toggle;
use Filament\Schemas\Schema;

class StudentForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                Select::make('school_class_id')
                    ->label('Classe')
                    ->options(fn () => SchoolClass::pluck('name', 'id'))
                    ->required()
                    ->native(false),
                TextInput::make('first_name')->label('Prénom')->required()->maxLength(255),
                TextInput::make('last_name')->label('Nom')->required()->maxLength(255),
                DatePicker::make('birth_date')->label('Date de naissance'),
                Select::make('gender')
                    ->label('Genre')
                    ->options(['m' => 'Masculin', 'f' => 'Féminin'])
                    ->native(false),
                TextInput::make('enrollment_number')->label('Numéro d\'inscription (facultatif)'),
                Select::make('status')
                    ->label('Statut')
                    ->options([
                        'active' => 'Actif',
                        'transferred' => 'Transféré',
                        'graduated' => 'Diplômé',
                    ])
                    ->default('active')
                    ->required()
                    ->native(false),
                Toggle::make('activated_at')
                    ->label('Abonnement activé')
                    ->helperText("Simule l'activation payante par enfant : tant que c'est désactivé, le parent voit l'enfant dans sa liste mais aucun détail (docs/PRODUCT_ARCHITECTURE.md §18).")
                    ->afterStateHydrated(fn (Toggle $component, $state) => $component->state(filled($state)))
                    ->dehydrateStateUsing(fn (bool $state) => $state ? now() : null),
            ]);
    }
}
