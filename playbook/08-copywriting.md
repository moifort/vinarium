# Copy utilisateur

S'applique à tout ce que la personne qui utilise le produit voit : notes de version, textes de
l'application, fiche du magasin.

## Ton

Impersonnel. On décrit ce qui a été mis en place, sans s'adresser au lecteur : ni vouvoiement, ni
tutoiement. « La taille de la cave peut maintenant être modifiée depuis les Réglages » plutôt que
« Vous pouvez maintenant changer la taille de votre cave ».

Dire où se trouve la fonctionnalité, avec les mots exacts de l'interface, pas une paraphrase.

Donner un exemple partout où il économise une explication.

Phrases complètes, coulantes, ponctuation normale. Aller à l'essentiel.

## Interdits

- **Jamais de tiret cadratin ni de tiret demi-cadratin.** Ils se lisent comme une signature de
  machine. Reformuler, ou utiliser un point, une virgule, deux-points.
- Pas de mots de remplissage : « à tout moment », « simplement », « également », « bien ».
- Pas de phrases hachées, pas de jargon technique.

## Localisation

La langue source est `{{SOURCE_LANGUAGE}}`, les langues servies sont `{{SERVED_LANGUAGES}}`. Le
ton ci-dessus vaut dans chacune, avec le registre naturel de la langue.

Une seule liste de langues supportées dans tout le système, partagée entre le client et le
serveur. Deux listes finissent toujours par diverger.

Les montants se stockent dans une devise canonique et se convertissent à l'affichage. La sortie
d'un service tiers dépend de la langue demandée : son cache est indexé par langue, sinon les
réponses se contaminent d'une langue à l'autre.

Piège récurrent des catalogues de traduction : une propriété de composant typée en chaîne brute
qui porte de la copie statique n'est jamais extraite et reste figée dans la langue source. Une
propriété qui ne reçoit que des littéraux doit être typée comme une clé localisable, le
compilateur refuse ensuite une chaîne calculée.

## README et fiche produit

Mêmes principes, appliqués à la documentation d'entrée : expliquer ce que fait le projet, pas
comment il est construit. Nommer chaque fichier explicitement. Dire pourquoi avant comment.
Numéroter les étapes pour qu'on puisse suivre de haut en bas. L'architecture profonde n'a rien à
faire dans un README.
