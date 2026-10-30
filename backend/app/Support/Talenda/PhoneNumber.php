<?php

namespace App\Support\Talenda;

/**
 * Compare des numéros congolais écrits différemment : « 06 333 33 33 »,
 * « 063333333 » et « +242 06 333 33 33 » désignent le même téléphone.
 */
final class PhoneNumber
{
    public static function normalize(?string $phone): ?string
    {
        $digits = preg_replace('/\D+/', '', (string) $phone) ?? '';

        if (str_starts_with($digits, '00')) {
            $digits = substr($digits, 2);
        }

        if (strlen($digits) === 12 && str_starts_with($digits, '242')) {
            $digits = substr($digits, 3);
        }

        return $digits === '' ? null : $digits;
    }

    /**
     * Écritures courantes d'un même numéro, pour le retrouver tel qu'il a
     * été saisi (« +242063333333 », « 06 333 33 33 »…).
     *
     * @return list<string>
     */
    public static function variants(string $phone): array
    {
        $local = self::normalize($phone);

        if ($local === null || strlen($local) !== 9) {
            return [];
        }

        return [
            $local,
            '+242'.$local,
            '242'.$local,
            '00242'.$local,
            substr($local, 0, 2).' '.substr($local, 2, 3).' '.substr($local, 5, 2).' '.substr($local, 7, 2),
            '+242 '.substr($local, 0, 2).' '.substr($local, 2, 3).' '.substr($local, 5, 2).' '.substr($local, 7, 2),
        ];
    }
}
