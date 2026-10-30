<?php

namespace App\Filament\Pages;

use App\Models\TenantSetting;
use App\Services\Talenda\SyncFromTalenda;
use App\Services\Talenda\UnlinkFromTalenda;
use App\Support\Talenda\TalendaUnavailable;
use App\Support\Tenancy\TenantContext;
use BackedEnum;
use Filament\Actions\Action;
use Filament\Facades\Filament;
use Filament\Forms\Components\TextInput;
use Filament\Notifications\Notification;
use Filament\Pages\Page;
use Filament\Schemas\Components\EmbeddedSchema;
use Filament\Schemas\Components\Section;
use Filament\Schemas\Components\Text;
use Filament\Schemas\Schema;
use Filament\Support\Icons\Heroicon;

/**
 * Relie l'école à Talenda, son logiciel de gestion (docs/JONCTION_TALENDA.md) :
 * l'adresse et la clé se créent dans Talenda (Paramètres → Applications
 * connectées → Scolia). Une fois reliée, Scolia se synchronise toutes les
 * 15 minutes.
 *
 * @property-read Schema $form
 */
class TalendaConnection extends Page
{
    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedArrowPathRoundedSquare;

    protected static ?string $slug = 'talenda';

    protected static ?string $title = 'Jonction Talenda';

    protected static ?string $navigationLabel = 'Talenda';

    protected static ?int $navigationSort = 90;

    /**
     * @var array<string, mixed>
     */
    public array $data = [];

    public static function canAccess(): bool
    {
        return Filament::auth()->user()?->can('tenant.settings.manage') ?? false;
    }

    public function mount(): void
    {
        $this->form->fill(['talenda_url' => $this->settings()->talenda_url]);
    }

    public function content(Schema $schema): Schema
    {
        return $schema->components([EmbeddedSchema::make('form')]);
    }

    public function form(Schema $schema): Schema
    {
        $settings = $this->settings();

        return $schema
            ->statePath('data')
            ->components([
                Section::make('État')
                    ->components([
                        Text::make(match (true) {
                            ! $settings->isConnectedToTalenda() => 'Non reliée : élèves, classes, matières, enseignants et parents se gèrent dans Scolia.',
                            $settings->talenda_sync_error !== null => 'Dernière synchronisation en échec : '.$settings->talenda_sync_error,
                            $settings->talenda_synced_at === null => 'Reliée, pas encore synchronisée.',
                            default => 'Reliée. Dernière synchronisation : '.$settings->talenda_synced_at->timezone(config('app.timezone'))->format('d/m/Y à H:i').'. Élèves, classes, matières, enseignants et parents se gèrent dans Talenda.',
                        })->color($settings->talenda_sync_error !== null ? 'danger' : 'gray'),
                    ]),
                Section::make('Connexion')
                    ->description('Dans Talenda : Paramètres → Applications connectées → Connecter une application → Scolia. Recopiez ici l\'adresse et la clé affichées.')
                    ->components([
                        TextInput::make('talenda_url')
                            ->label('Adresse de l\'API Talenda')
                            ->placeholder('https://…/api/integration/v1')
                            ->url()
                            ->required(),
                        TextInput::make('talenda_token')
                            ->label('Clé')
                            ->password()
                            ->placeholder($settings->talenda_token !== null ? 'Clé enregistrée — laisser vide pour la garder' : 'tlnd_…')
                            ->required($settings->talenda_token === null)
                            ->startsWith('tlnd_'),
                    ]),
            ]);
    }

    /**
     * @return array<Action>
     */
    protected function getHeaderActions(): array
    {
        return [
            Action::make('sync')
                ->label('Synchroniser maintenant')
                ->icon(Heroicon::OutlinedArrowPath)
                ->visible(fn (): bool => $this->settings()->isConnectedToTalenda())
                ->action(fn () => $this->synchronize()),
            Action::make('unlink')
                ->label('Délier de Talenda')
                ->icon(Heroicon::OutlinedLinkSlash)
                ->color('danger')
                ->visible(fn (): bool => $this->settings()->isConnectedToTalenda())
                ->requiresConfirmation()
                ->modalHeading('Délier l\'école de Talenda ?')
                ->modalDescription('Scolia redevient autonome : élèves, classes, matières, enseignants et parents sont conservés et se gèrent de nouveau ici. Les comptes déjà connectés à Scolia gardent leur mot de passe ; les autres reçoivent un mot de passe provisoire, dans un fichier à télécharger maintenant (il ne sera plus affiché).')
                ->modalSubmitActionLabel('Délier')
                ->action(function () {
                    $passwords = app(UnlinkFromTalenda::class)->handle(app(TenantContext::class)->get());

                    Notification::make()->success()
                        ->title('École déliée de Talenda')
                        ->body($passwords === [] ? 'Tous les comptes gardent leur mot de passe.' : count($passwords).' compte(s) ont reçu un mot de passe provisoire : voir le fichier téléchargé.')
                        ->persistent()
                        ->send();

                    if ($passwords === []) {
                        $this->redirect(static::getUrl());

                        return null;
                    }

                    return response()->streamDownload(function () use ($passwords): void {
                        $output = fopen('php://output', 'w');
                        fputcsv($output, ['Nom', 'Téléphone', 'E-mail', 'Mot de passe provisoire'], ';');

                        foreach ($passwords as $row) {
                            fputcsv($output, [$row['name'], $row['phone'], $row['email'], $row['password']], ';');
                        }

                        fclose($output);
                    }, 'mots-de-passe-provisoires.csv', ['Content-Type' => 'text/csv; charset=UTF-8']);
                }),
            Action::make('save')
                ->label('Enregistrer et synchroniser')
                ->icon(Heroicon::OutlinedCheck)
                ->action(function (): void {
                    $state = $this->form->getState();

                    $this->settings()->update(array_filter([
                        'talenda_url' => rtrim((string) $state['talenda_url'], '/'),
                        'talenda_token' => blank($state['talenda_token'] ?? null) ? null : trim((string) $state['talenda_token']),
                    ]));

                    $this->synchronize();
                }),
        ];
    }

    private function synchronize(): void
    {
        try {
            $counts = app(SyncFromTalenda::class)->handle(app(TenantContext::class)->get());

            Notification::make()->success()
                ->title('Synchronisation terminée')
                ->body("{$counts['students']} élèves, {$counts['guardians']} parents, {$counts['teachers']} enseignants, {$counts['classes']} classes.")
                ->send();
        } catch (TalendaUnavailable $exception) {
            Notification::make()->danger()->title('Synchronisation impossible')->body($exception->getMessage())->persistent()->send();
        }

        $this->redirect(static::getUrl());
    }

    private function settings(): TenantSetting
    {
        return TenantSetting::query()->firstOrFail();
    }
}
