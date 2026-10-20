# Règles de minification (R8) propres au projet, en complément des règles
# par défaut de Flutter/Android (getDefaultProguardFile). Objectif : réduire
# la taille de l'APK sans rien casser à l'exécution — ces "keep" évitent que
# R8 supprime ou renomme du code utilisé seulement par réflexion (Firebase,
# notifications locales), invisible à son analyse statique.

# Firebase Cloud Messaging (notifications push).
-keep class com.google.firebase.messaging.** { *; }
-keep class com.google.firebase.** { *; }

# flutter_local_notifications sérialise/désérialise certains modèles par
# réflexion (gson) au réveil de l'appareil.
-keep class com.dexterous.** { *; }
-keep class * extends java.util.TimeZone { *; }

# Play Core (utilisé en interne par le Flutter embedding pour les
# fonctionnalités de Play Store — absent de notre flux d'installation par
# sideload, mais référencé dans le code généré ; à garder pour éviter un
# avertissement R8 bloquant).
-dontwarn com.google.android.play.core.**
