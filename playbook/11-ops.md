# Exploitation

## Migrations

Forward-only, séquentielles, sans rollback. Leur état est suivi en base.

Elles ne s'exécutent jamais depuis un poste local, ni par un serveur de développement, ni par un
script direct. Le pipeline de déploiement fait la séquence correcte : déployer le nouveau code,
puis déclencher la migration. Une migration lancée en local désynchronise les données et le
backend déployé.

Conséquence pratique : entre le push et la fin du déploiement, un serveur local exécute du code
neuf contre des données non migrées. Les erreurs de valeurs inattendues pendant cette fenêtre
sont normales, et on ne régénère pas d'artefact visuel avant la fin du déploiement.

On migre pour renommer un champ, changer sa structure, changer un jeu de valeurs, supprimer des
données périmées. On ne migre pas pour ajouter un champ optionnel, une collection, ou changer une
requête.

## Index

Les index suivent les requêtes. Quand une requête change, on ajoute les index devenus nécessaires
et on retire ceux devenus morts. Un index oublié après un renommage ne se voit qu'en production,
sous forme de requête refusée.

N'ajouter que le nécessaire : un tri fait en mémoire après lecture n'exige aucun index. Le
fichier d'index est la source de vérité lue par l'infrastructure, pas une commande manuelle.

## Triage d'une erreur remontée par le monitoring

1. Charger le jeton depuis l'environnement local, sans jamais l'afficher ni le committer.
2. Lire l'issue et son dernier événement par l'API du service.
3. Remonter la pile jusqu'au code de domaine, corriger la cause, pas le symptôme.
4. Si le bug est fonctionnel et sérieux, écrire le test qui échoue avant le correctif et passe
   après.
5. Vérifier en local, committer.
6. Marquer l'issue résolue seulement après le push **et** un pipeline vert.

L'envoi des sources et des cartes de correspondance au service de monitoring est acquis, il ne se
redemande pas à chaque release.

## Dépendances

Les montées mineures et correctives cohérentes se corrigent et se fusionnent automatiquement, y
compris quand elles cassent la CI par effet mécanique, par exemple un linter qui durcit une
règle. Les montées majeures ne se fusionnent jamais seules : elles se signalent pour arbitrage.

Garde-fou indispensable quand le gestionnaire de paquets local est plus permissif que celui de la
chaîne de déploiement : une montée majeure incompatible passe les tests et casse au déploiement.
Un job qui rejoue l'installation stricte sur l'artefact de build attrape le conflit avant la
production, et les bornes de version correspondantes sont posées dans la configuration du robot
de mise à jour.

## Secrets

Un secret vit dans l'environnement local ignoré par git, et dans le gestionnaire de secrets de la
CI. Chaque emplacement où un jeton doit être répliqué est listé dans le contexte projet, avec un
fichier d'exemple à côté de chaque fichier ignoré. Une rotation qui oublie un emplacement se
découvre par une panne, pas par une alerte.
