<?php

namespace App\Filament\Resources\Students\Tables;

use Filament\Actions\BulkActionGroup;
use Filament\Actions\DeleteBulkAction;
use Filament\Actions\EditAction;
use Filament\Tables\Columns\IconColumn;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;

class StudentsTable
{
    public static function configure(Table $table): Table
    {
        return $table
            ->columns([
                TextColumn::make('last_name')->label('Nom')->searchable()->sortable(),
                TextColumn::make('first_name')->label('Prénom')->searchable()->sortable(),
                TextColumn::make('schoolClass.name')->label('Classe')->sortable(),
                TextColumn::make('status')->label('Statut')->badge(),
                IconColumn::make('activated_at')
                    ->label('Activé')
                    ->boolean()
                    ->getStateUsing(fn ($record) => $record->isActivated()),
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
