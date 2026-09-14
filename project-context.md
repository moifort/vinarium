# Contexte projet Vinarium

Les faits propres à ce dépôt. La méthode de travail est dans [playbook/](playbook/README.md) ;
ici, uniquement ce qui n'a de sens que pour Vinarium.

Règle : ce qui est une **règle** va dans le playbook, ce qui est un **fait** reste ici.

## Environnements

| Environnement | Identifiant | Notes |
|---|---|---|
| Production | `vinarium-prod` | Confirmé par `infra/terraform.tfvars`, `infra/backend.tf`, `ios/Vinarium/GoogleService-Info.plist` |
| Héritage | `cave-a-vin` | Ancien nom de projet, encore présent dans `.firebaserc` à la racine. Piège classique sur toute commande `gcloud` ou `firebase` |

Pour tout script firebase-admin : `GOOGLE_CLOUD_PROJECT=vinarium-prod`. L'identifiant par défaut
a besoin d'un projet de quota : `gcloud auth application-default set-quota-project vinarium-prod`.

Compte utilisateur unique en production : `KyTjMU39NBhfakGxExfqLmC5OYU2`.

## Comptes et consoles

- Consoles GCP, Firebase et Analytics : compte `thibaut@polyforms.co`. Forcer la sélection avec
  `?authuser=thibaut@polyforms.co` dans l'URL.
- Dépôt GitHub : `moifort/vinarium`, fusion en squash uniquement.

## Analytique et supervision

- Propriété GA4 `548838755` (projet `vinarium-prod`), dans le compte Analytics `343114634`
  « Default Account for Firebase ». L'autre compte Analytics visible sur le gmail personnel
  agrège des sites sans rapport : ne rien y brancher.
- Exploration « Funnel d'activation » : `first_open` puis `onboarding_completed`, `bottle_added`,
  `cellar_stocked`, `purchase_completed`.
- Rapport hebdomadaire par courriel le vendredi. Il finissait en indésirable, un filtre a été
  posé.
- Envoi des sources et des cartes de correspondance au service de rapport d'erreurs : acquis et
  validé, ne pas redemander l'autorisation.
- Routine de relecture des montées de dépendances : `trig_01WTQJCmwsBLe8ZTbEPAw5pH`, un jour sur
  deux à 07:00 UTC.

## Appareils de test

- iPhone physique « TiPhone junior », UDID `00008130-000A2068029A001C`, signature de
  développement automatique, équipe `46C337T7YN`. Installation par `scripts/install-device.sh`,
  jamais sans accord.
- Simulateur de référence : iPhone 17, iOS 26.2.

## Accès serveur et données héritées

- Serveur maison CasaOS : `ssh casaos@192.168.1.199`, clé SSH configurée.
- Données de l'ancienne application mono-utilisateur sous `/DATA/AppData/cave-a-vin/db/`. Pas de
  `rsync` sur la machine : passer par `tar` au travers de SSH.
- Migration vers Firestore faite le 2026-07-02 (54 bouteilles). Copie locale de l'export dans
  `.data/casa-db/`, ignorée par git.
- L'adresse `192.168.0.165` vue dans `.env` est un autre service, pas cet accès.

## Certificats, clés et secrets GitHub

| Secret | Rôle |
|---|---|
| `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_P8` | Clé App Store Connect `vinarium-ci` (`M7447599QX`, rôle Admin), téléversement et soumission |
| `IOS_DIST_CERT_P12`, `IOS_DIST_CERT_PASSWORD`, `IOS_PROVISION_PROFILE` | Signature manuelle de l'archive, expiration du certificat le **2027-07-15** |
| `IOS_GOOGLE_SERVICE_INFO_PLIST` | Fichier de configuration Firebase, ignoré par git |
| `APPLE_*` | Clé Sign in with Apple utilisée par Terraform. À ne pas confondre avec les `ASC_*` |

Poser un secret sans l'exposer : `base64 -i <fichier> | tr -d '\n' | gh secret set NOM`.

## Emplacements des jetons

`NITRO_API_TOKEN` est répliqué dans `.env`, `ios/Vinarium/Shared/Secrets.swift` et
`ios/VinariumUITests/Support/TestSecrets.swift`. Les deux fichiers Swift sont ignorés par git et
ont un `.example` à côté. `SENTRY_AUTH_TOKEN` vit dans `.env`, jamais affiché ni committé.

## Décisions propres au projet

- **Liens universels d'invitation** : ils passent par `vinarium-prod.web.app`, pas par
  `vinarium.app`. Ce domaine est enregistré chez Namecheap sur un compte auquel Thibaut n'a pas
  accès, et son DNS pointe encore sur une IP de parking. Le host est centralisé dans
  `InvitationLink.host`. Tout changement d'entitlement exige une nouvelle version App Store.
- **Sept langues** : français source, plus anglais, allemand, espagnol, italien, portugais,
  japonais. Catalogue `ios/Vinarium/Resources/Localizable.xcstrings`, liste partagée côté serveur
  dans `server/domain/shared/language.ts`. Prix toujours stockés en euros, convertis à
  l'affichage.
- **Symboles d'onglets personnalisés** générés par `scripts/generate-tab-symbols.swift`. Ne jamais
  éditer les SVG committés. Contraintes du format : groupes `Ultralight-M`, `Regular-M`,
  `Black-M`, toutes les lignes guides requises dès qu'un groupe porte une transformation, et le
  moteur de rendu ignore les styles de trait et la règle de remplissage : les traits doivent être
  pré-étendus et les trous enroulés en sens inverse.
- **Schéma GraphQL édité à la main** : `bun run generate:graphql` reformate tout le fichier et
  noie les vrais changements. On édite les changements sémantiques à la main et on vérifie
  l'équivalence en comparant les schémas triés lexicographiquement. Le binaire de génération du
  client iOS vient du checkout SwiftPM, il n'est pas dans le `PATH`. Les scalaires personnalisés
  édités à la main doivent être committés, sinon l'archive de la CI casse.
- **Exclusions du linter** : `shared/` (SDL généré), `server/system/changelog-content.ts`
  (gitignoré, régénéré au déploiement), `ios/Vinarium/Assets.xcassets/**`,
  `Localizable.xcstrings`.
- **Bornes de dépendances** imposées par la chaîne de déploiement en npm strict : `graphql < 17`,
  `firebase-admin < 14`. Garde-fou dans le job `deploy-deps` de `test-unit.yml`.

## Travaux en attente

- Écran Admin : le flag `admin: true` se pose à la main sur `user-profiles/<uid>` en console
  Firestore.
- Variable GitHub `ASC_VENDOR_NUMBER` à créer pour les revenus App Store, et vérifier que la clé
  App Store Connect porte le rôle « Sales and Reports ». Sans elle, le revenu reste indisponible
  sans rien casser.
- Table d'export BigQuery de facturation : activée le 2026-07-24, variable `GCP_BILLING_TABLE`
  posée. Le coût d'infrastructure reste nul tant que l'export n'écrit pas.
