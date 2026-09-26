<?php

namespace App\Filament\Resources\SchoolClasses\Tables;

use Filament\Actions\BulkActionGroup;
use Filament\Actions\DeleteBulkAction;
use Filament\Actions\EditAction;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;

class SchoolClassesTable
{
    public static function configure(Table $table): Table
    {
        return $table
            ->columns([
                TextColumn::make('name')->label('Classe')->searchable()->sortable(),
                TextColumn::make('level')->label('Niveau')->toggleable(),
                TextColumn::make('schoolYear.label')->label('Année scolaire'),
                TextColumn::make('homeroomTeacher.user.name')->label('Professeur principal')->placeholder('—'),
                TextColumn::make('students_count')->label('Élèves')->counts('students'),
            ])
            ->filters([
                //
            ])
            ->recordActions([
                EditAction::make(),
            ])
            ->toolbarActions([
                BulkActionGroup::make([
                    DeleteBulkAction::make(),
                ]),
            ]);
    }
}
