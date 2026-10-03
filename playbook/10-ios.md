# Application iOS

Forme longue dans [92-annexe-ios.md](92-annexe-ios.md).

## Structure

Un dossier par feature. À sa racine, la vue coordinatrice : elle possède le modèle de vue, la
navigation, les feuilles modales et la conversion du domaine vers les types d'affichage. En
dessous, les pages, qui sont pures et prévisualisables, puis les organismes, molécules et atomes.

Les vues feuilles prennent des valeurs primitives, pas des objets de domaine. Les organismes sont
la frontière où la conversion se fait. Les previews servent de catalogue : chaque composant a la
sienne.

Concurrence stricte : les modèles de vue sont sur l'acteur principal, les types de modèle sont
transmissibles.

## Chargements

Tout appel réseau affiche un retour visuel, sans exception. Les listes montrent un indicateur
dans leur corps, pas en plein écran. Les boutons qui déclenchent une mutation affichent une
progression et se désactivent pendant l'appel. Les sections d'un tableau de bord chargent
visiblement.

Comme il n'y a pas de cache client, chaque action est un aller-retour : l'absence d'indicateur se
voit immédiatement.

L'ouverture de l'app ne montre pas d'indicateur : elle montre une étiquette de vin, Vinarium
habillé en domaine, l'icône en guise de gravure et l'année en cours pour millésime. L'étiquette
reste fixe, comme sur une bouteille : tout le mouvement est celui du vin. L'écran de lancement système affiche le fond nu de l'icône, la première image de l'app
pose l'étiquette sur le même fond, puis la surface d'un vin rouge vue de très près apparaît en
fondu derrière elle et ondule lentement tant que la requête de lancement court. Quand le premier écran est posé derrière,
le rideau s'efface dessus en fondu. Il tient au moins le temps de voir le vin bouger,
pour qu'une réponse rapide ne le coupe pas, et jamais plus que la réponse. Cette animation est
réservée à l'ouverture ; partout ailleurs, l'indicateur système.

Une exception, et une seule : l'écran qu'on rouvre. Un écran qui change lentement et que
l'utilisateur reconnaît, une liste ou un tableau de bord, garde sur disque ce qu'il montrait, dans
le dossier des caches. Au lancement, le modèle de vue le relit de façon synchrone, avant tout
appel réseau, et l'écran est lisible dès la première image. Le rafraîchissement qui suit ne
reprend jamais l'écran et n'affiche aucun indicateur : le contenu reste lisible, et à l'arrivée de
la réponse les lignes se déplacent, apparaissent ou disparaissent en place, animées. Une mutation
faite depuis cet écran le recharge de la même façon, sans le vider. Chaque vue, tri, filtre ou
cave garde sa propre première page : en changer affiche aussitôt ce qu'elle montrait la dernière
fois, sans indicateur, et le loader n'apparaît que sur une liste vide. Jamais plus d'une première
page par fichier, et tout est effacé à la déconnexion.
Ne s'applique pas à une donnée qui ne vaut rien périmée : un solde, un quota, un code.

Un chargement qui échoue ne dit rien : ni message d'erreur ni bouton « Réessayer ». Ce qui était
affiché reste en place ; un écran qui n'avait rien reste vide. Réessayer, c'est tirer pour
rafraîchir : tout écran qui charge est tirable, vide compris, ce qui demande une vue défilante
même quand il n'y a rien à montrer.

## Zones de tap

Une ligne qui ouvre ou déclenche quelque chose répond au tap sur toute sa largeur, pas seulement
sur son texte. L'utilisateur vise la ligne, pas les mots : un tap dans le blanc qui ne fait rien
passe pour une application figée, et le tap suivant, sur le titre, pour une réponse en retard.

Un bouton au style `plain` ne répond que là où quelque chose est dessiné : le vide laissé par un
`Spacer`, ou entre le libellé et la valeur d'un `LabeledContent`, est mort. On donne une forme au
label, `.contentShape(.rect)`, étiré sur la largeur si son contenu ne l'est pas. La forme se pose
dans la vue de ligne elle-même, pour que chaque appelant en hérite. Une ligne à fond plein, une
carte, est déjà cliquable partout. Jamais de `onTapGesture` à la place du bouton : il perd le
trait d'accessibilité et l'état pressé.

## Client d'API

Opérations typées, générées depuis le schéma du serveur. Les opérations vivent dans leur feature,
les types générés dans un dossier dédié qu'on ne modifie jamais à la main.

Lecture sans cache et mutations sans publication dans un magasin local, conformément à
[09-backend.md](09-backend.md).

## Build

Ne jamais purger le cache de build pour débloquer une compilation cassée. La résolution des
dépendances qui suit est fragile, et son cache est partagé entre sessions : deux résolutions
simultanées se corrompent. On diagnostique la vraie cause, souvent une ligne parasite dans le
fichier de projet, et on la reverte.

## Assets générés

Les icônes et symboles produits par un script ne s'éditent jamais à la main : on modifie le
script et on régénère. Ils sont exclus du linter.

## Capture de validation

Toute demande qui crée, modifie ou supprime de l'interface se termine par une capture
d'écran envoyée à Thibaut, qui valide sur l'image : pas de « c'est fait » sans elle. Une capture
par état touché, la feuille ouverte comprise. La capture est envoyée en fichier dans la
conversation, à chaque modification d'interface, même petite : l'avoir regardée soi-même ne
compte pas, et « captures ci-dessus » sans fichier envoyé non plus.

Sans session sur le simulateur, l'écran passe par la galerie de debug :
`xcrun simctl launch <udid> com.polyforms.vinarium.app -debugGallery -debugScreen <nom>` ouvre
une entrée directement, sans tap. Chaque écran modifié qui n'y est pas encore y gagne son entrée.
Utiliser un simulateur dédié plutôt que celui d'une autre session.

## Appareil physique

À la fin d'une tâche qui touche l'application, proposer l'installation sur l'appareil de test
`{{DEVICE_NAME}}`. Ne jamais la lancer sans accord. Relayer la sortie brute des outils de build
et d'installation : pas d'annonce de succès sans elle.
