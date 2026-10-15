<?php

/**
 * Catalogue des permissions et rôles de tenant (voir
 * docs/PRODUCT_ARCHITECTURE.md §15). Centralisé ici pour que
 * App\Services\Tenancy\TenantProvisioner et les tests restent en phase.
 *
 * Ne concerne que les rôles "tenant" (spatie teams, team = tenant_id).
 * Le Super Admin plateforme (table platform_admins, guard `platform`)
 * n'est pas un rôle de ce catalogue.
 */
return [
    'permissions' => [
        'tenant.settings.manage',
        'role.manage',
        'student.view',
        'student.manage',
        'teacher.manage',
        'schoolclass.manage',
        'homework.view',
        'homework.create',
        'homework.update',
        'homework.delete',
        'behavior.view',
        'behavior.create',
        'attendance.view',
        'attendance.create',
        'attendance.justify',
        'attendance.review',
        'message.view',
        'message.send',
        'announcement.view',
        'announcement.publish',
        'timetable.view',
        'timetable.manage',
        'grade.view',
        'grade.manage',
        'document.view',
        'document.manage',
        'subscription.view',
    ],

    'roles' => [
        // school_admin reçoit toutes les permissions ci-dessus (giveAllPermissions).
        'school_admin' => '*',

        'direction' => [
            'student.view', 'student.manage', 'teacher.manage', 'schoolclass.manage',
            'homework.view', 'homework.create', 'homework.update', 'homework.delete',
            'behavior.view', 'behavior.create',
            'attendance.view', 'attendance.create', 'attendance.review',
            'message.view', 'message.send',
            'announcement.view', 'announcement.publish',
            'timetable.view', 'timetable.manage',
            'grade.view', 'grade.manage',
            'document.view', 'document.manage',
            'subscription.view',
        ],

        'teacher' => [
            'student.view',
            'homework.view', 'homework.create', 'homework.update',
            'behavior.view', 'behavior.create',
            'attendance.view', 'attendance.create',
            'message.view', 'message.send',
            'announcement.view',
            'timetable.view',
            'grade.view', 'grade.manage',
        ],

        'parent' => [
            'student.view',
            'homework.view',
            'behavior.view',
            'attendance.view', 'attendance.justify',
            'message.view', 'message.send',
            'announcement.view',
            'timetable.view',
            'grade.view',
            'document.view',
        ],

        'surveillant' => [
            'attendance.view', 'attendance.create',
            'behavior.view', 'behavior.create',
        ],

        'comptable' => [
            'subscription.view',
        ],

        'eleve' => [
            'homework.view',
            'timetable.view',
        ],
    ],
];
