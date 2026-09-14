# Backend

Règles pour un backend TypeScript orienté domaine. Forme longue dans
[90-annexe-domaine.md](90-annexe-domaine.md) et [91-annexe-graphql.md](91-annexe-graphql.md).

## Architecture

Un dossier par domaine, contenant ses types, ses primitives, ses commandes, ses requêtes, ses
règles métier éventuelles et son infrastructure. Lecture et écriture sont séparées : les
commandes changent l'état, les requêtes ne changent rien.

Le repository est privé au domaine : il n'est importé que depuis son propre dossier. Un domaine
qui a besoin d'un autre passe par la surface publique de cet autre, jamais par son stockage.

Le nom d'une fonction porte le concept métier, pas le motif technique. Le nom est la règle.

## Style

Fonctionnel. Pas de classe, pas d'interface au sens objet. Le polymorphisme se modélise par une
union discriminée sur un champ littéral, la réutilisation par composition de types. Côté schéma
d'API, une union, jamais une interface.

## Types

Aucun primitif nu dans les modèles de domaine : chaque champ porte un type brandé avec son
constructeur validant et son scalaire d'API. Les brands génériques (pourcentage, identifiant,
montant) sont partagés plutôt que redéfinis par domaine. Seules les dates restent des objets
natifs.

La validation se fait à la frontière, une fois, à la construction du type. Le reste du code
travaille sur des valeurs déjà valides.

## Erreurs

Une commande retourne son résultat ou une issue nommée, en valeur. La couche d'exposition fait
correspondre ces issues aux erreurs du protocole, de façon exhaustive, sans branche par défaut
qui masquerait un cas nouveau. On lève une exception uniquement pour un état impossible, jamais
pour un cas métier attendu.

## Stockage et coût

Tout accès au stockage est confiné au repository du domaine.

Aucun champ imbriqué ne déclenche une lecture par ligne parente. Les satellites se résolvent par
des chargeurs groupés, par requête. Les listes se paginent au stockage, pas en mémoire après
avoir tout chargé.

Le seul cache accepté est un cache par requête entrante : si une requête de domaine est appelée
plusieurs fois pendant le traitement d'un appel, elle ne lit qu'une fois. Pas de cache normalisé
côté client, sa classe de bugs de fraîcheur coûte plus cher que ce qu'il fait gagner.

## Observabilité

Jamais d'écriture directe sur la sortie standard. Un logger nommé par composant. Le rapport
d'erreurs vers un service tiers ne s'active que dans un bundle construit et configuré, jamais en
développement local.

## Tests

Trois familles, reconnaissables à leur suffixe : unitaire pour les fonctions pures, intégration
pour les commandes et requêtes contre un stockage simulé, fonctionnel pour le contrat d'API.

Les budgets de lecture s'affirment dans les tests d'intégration, en comptant les lectures de
documents et de requêtes séparément.

Piège du cache par requête en test : la mémoïsation est active à l'intérieur d'un test et
réinitialisée entre deux tests. Une requête mémoïsée appelée plusieurs fois ne compte qu'une
lecture, et resemer des données entre deux appels de la même requête dans un même test renvoie le
résultat périmé. Dans ce cas, deux tests distincts.

## Code généré

Un schéma exporté, un client typé, un asset compilé : ces fichiers appartiennent à leur
générateur. On ne les édite pas à la main, on les régénère, on les commite quand le dépôt en a
besoin, et on les exclut du linter. Voir [04-push-protocol.md](04-push-protocol.md).
