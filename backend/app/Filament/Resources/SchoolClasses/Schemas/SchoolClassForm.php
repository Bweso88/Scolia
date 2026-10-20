<?php

namespace App\Filament\Resources\SchoolClasses\Schemas;

use App\Models\SchoolYear;
use App\Models\Teacher;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\TextInput;
use Filament\Schemas\Schema;

class SchoolClassForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                TextInput::make('name')
                    ->label('Nom de la classe')
                    ->placeholder('Ex : CM2')
                    ->required()
                    ->maxLength(255),
                TextInput::make('level')
                    ->label('Niveau (facultatif)')
                    ->placeholder('Ex : Primaire'),
                Select::make('school_year_id')
                    ->label('Année scolaire')
                    ->options(fn () => SchoolYear::orderByDesc('start_date')->pluck('label', 'id'))
                    ->default(fn () => SchoolYear::where('is_current', true)->value('id'))
                    ->required()
                    ->native(false),
                Select::make('homeroom_teacher_id')
                    ->label('Professeur principal (facultatif)')
                    ->relationship('homeroomTeacher', 'employee_number')
                    ->getOptionLabelFromRecordUsing(fn (Teacher $teacher) => $teacher->user?->name ?? $teacher->employee_number)
                    ->searchable()
                    ->native(false),
            ]);
    }
}
