<?php

namespace App\Filament\Resources\Students\RelationManagers;

use App\Models\User;
use Filament\Actions\CreateAction;
use Filament\Actions\DeleteAction;
use Filament\Actions\EditAction;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\Toggle;
use Filament\Resources\RelationManagers\RelationManager;
use Filament\Schemas\Schema;
use Filament\Tables\Columns\IconColumn;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;
use Illuminate\Support\Facades\Hash;

/**
 * Sur la relation studentGuardians() (HasMany vers le modèle pivot
 * StudentGuardian), pas la BelongsToMany guardians() — create() y
 * déclenche correctement le renseignement de tenant_id, contrairement à
 * attach()/sync() sur la relation many-to-many (voir Student::guardians()).
 */
class StudentGuardiansRelationManager extends RelationManager
{
    protected static string $relationship = 'studentGuardians';

    protected static ?string $title = 'Parents / tuteurs';

    public function form(Schema $schema): Schema
    {
        return $schema->components([
            Select::make('user_id')
                ->label('Parent')
                ->relationship('guardianUser', 'name')
                ->searchable()
                ->required()
                ->native(false)
                ->createOptionForm([
                    TextInput::make('name')->label('Nom complet')->required(),
                    TextInput::make('email')->label('Email')->email()->required()
                        ->unique('users', 'email'),
                    TextInput::make('password')->label('Mot de passe')->password()
                        ->required()->minLength(8)->revealable(),
                ])
                ->createOptionUsing(function (array $data): int {
                    $user = User::create([
                        'name' => $data['name'],
                        'email' => $data['email'],
                        'password' => Hash::make($data['password']),
                        'is_active' => true,
                    ]);
                    $user->assignRole('parent');

                    return $user->id;
                }),
            Select::make('relationship_type')
                ->label('Lien de parenté')
                ->options([
                    'mère' => 'Mère',
                    'père' => 'Père',
                    'tuteur' => 'Tuteur/tutrice',
                    'autre' => 'Autre',
                ])
                ->required()
                ->native(false),
            Toggle::make('is_primary_contact')
                ->label('Contact principal'),
        ]);
    }

    public function table(Table $table): Table
    {
        return $table
            ->recordTitleAttribute('relationship_type')
            ->columns([
                TextColumn::make('guardianUser.name')->label('Parent'),
                TextColumn::make('guardianUser.email')->label('Email'),
                TextColumn::make('relationship_type')->label('Lien'),
                IconColumn::make('is_primary_contact')->label('Principal')->boolean(),
            ])
            ->headerActions([
                CreateAction::make(),
            ])
            ->recordActions([
                EditAction::make(),
                DeleteAction::make(),
            ]);
    }
}
