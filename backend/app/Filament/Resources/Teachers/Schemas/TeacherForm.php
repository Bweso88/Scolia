<?php

namespace App\Filament\Resources\Teachers\Schemas;

use App\Models\SchoolClass;
use App\Models\Subject;
use App\Models\User;
use Filament\Forms\Components\Repeater;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\TextInput;
use Filament\Schemas\Schema;
use Illuminate\Support\Facades\Hash;

class TeacherForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                Select::make('user_id')
                    ->label('Compte utilisateur')
                    ->relationship('user', 'name')
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
                        $user->assignRole('teacher');

                        return $user->id;
                    }),
                TextInput::make('employee_number')
                    ->label('Matricule (facultatif)')
                    ->maxLength(255),
                Repeater::make('assignments')
                    ->label('Classes et matières enseignées')
                    ->relationship()
                    ->schema([
                        Select::make('school_class_id')
                            ->label('Classe')
                            ->options(fn () => SchoolClass::pluck('name', 'id'))
                            ->required()
                            ->native(false),
                        Select::make('subject_id')
                            ->label('Matière')
                            ->options(fn () => Subject::pluck('name', 'id'))
                            ->required()
                            ->native(false),
                    ])
                    ->columns(2)
                    ->defaultItems(0)
                    ->addActionLabel('Ajouter une affectation'),
            ]);
    }
}
