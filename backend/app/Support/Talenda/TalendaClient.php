<?php

namespace App\Support\Talenda;

use App\Models\TenantSetting;
use Illuminate\Http\Client\ConnectionException;
use Illuminate\Http\Client\PendingRequest;
use Illuminate\Support\Facades\Http;

/**
 * Appels à l'API d'intégration de Talenda pour une école reliée
 * (docs/JONCTION_TALENDA.md). L'adresse et la clé sont celles données par
 * Talenda (Paramètres → Applications connectées).
 */
class TalendaClient
{
    public function __construct(private readonly TenantSetting $settings) {}

    /**
     * Photographie de l'année ouverte : école, année, matières, classes,
     * personnel, enseignements, élèves et responsables.
     *
     * @return array<string, mixed>
     *
     * @throws TalendaUnavailable
     */
    public function snapshot(): array
    {
        try {
            $response = $this->request()->timeout(60)->get('snapshot');
        } catch (ConnectionException) {
            throw new TalendaUnavailable('Talenda ne répond pas.');
        }

        if ($response->status() === 401) {
            throw new TalendaUnavailable('Clé Talenda refusée : elle a peut-être été révoquée.');
        }

        if (! $response->successful() || ! is_array($response->json('school_year', []))) {
            throw new TalendaUnavailable("Talenda a répondu par une erreur ({$response->status()}).");
        }

        return $response->json();
    }

    /**
     * Vérifie un identifiant (téléphone ou e-mail) et un mot de passe
     * auprès de Talenda. Renvoie le compte Talenda, ou null si les
     * identifiants sont incorrects.
     *
     * @return array{account_uuid: string, name: string, phone: ?string, email: ?string}|null
     *
     * @throws TalendaUnavailable
     */
    public function checkCredentials(string $login, string $password): ?array
    {
        try {
            $response = $this->request()->timeout(10)->post('credentials/check', [
                'login' => $login,
                'password' => $password,
            ]);
        } catch (ConnectionException) {
            throw new TalendaUnavailable('Talenda ne répond pas.');
        }

        if ($response->status() === 422) {
            return null;
        }

        if (! $response->successful() || ! is_string($response->json('account_uuid'))) {
            throw new TalendaUnavailable("Talenda a répondu par une erreur ({$response->status()}).");
        }

        return $response->json();
    }

    private function request(): PendingRequest
    {
        return Http::baseUrl(rtrim((string) $this->settings->talenda_url, '/').'/')
            ->withToken((string) $this->settings->talenda_token)
            ->acceptJson();
    }
}
