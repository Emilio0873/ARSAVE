# -*- coding: utf-8 -*-
"""Développements ajoutés pour porter le mémoire au-delà de 60 pages."""


def _h(doc, add_h, title):
    add_h(doc, title, 2)


def _ps(doc, add_p, paragraphs):
    for text in paragraphs:
        add_p(doc, text)


def extra_chapitre_1(doc, add_h, add_p, add_table):
    _h(doc, add_h, "1.7 Sauvegarde distante, versions et corbeille")
    _ps(doc, add_p, [
        "Une sauvegarde n'est pas une simple copie unique. Elle doit survivre à la perte du poste, à l'écrasement accidentel d'un fichier et à une suppression que l'utilisateur regrette. La littérature de génie logiciel traite ce besoin comme une exigence de disponibilité et de récupérabilité : le service doit rendre le contenu, et pas seulement le stocker (Sommerville, 2016 ; Pressman et Maxim, 2019). Dans un coffre personnel, trois mécanismes reviennent de façon stable. Le premier est le dépôt distant, qui sépare la donnée de l'appareil. Le deuxième est le versionnement, qui conserve un état antérieur lorsqu'un même nom logique est renvoyé. Le troisième est la corbeille, qui distingue une mise à l'écart réversible d'une suppression définitive.",
        "ARSAVE reprend ces trois mécanismes, mais il les place après le chiffrement. Le nom logique, le type MIME et la taille sont des métadonnées : elles servent à retrouver le fichier et à l'afficher. Le contenu, lui, n'est jamais écrit en clair sur le serveur. Cette séparation est le point de départ de la revue. Elle évite de confondre la fonction de sauvegarde, qui est visible pour l'utilisateur, et la fonction de confidentialité, qui est invisible mais décisive en cas de lecture de la base ou du disque (Anderson, 2020 ; Saltzer et Schroeder, 1975).",
        "Le versionnement retenu est simple : une nouvelle sauvegarde du même fichier peut créer une nouvelle version, numérotée, rattachée au même identifiant logique. La version courante est celle que la restauration prend par défaut. Les versions précédentes restent atteignables. Ce choix correspond à un coffre personnel, non à un système de sauvegarde incrémentale de blocs. L'unité d'échange est le fichier entier, déjà chiffré. Le coût est une copie complète à chaque envoi ; le gain est un modèle de classes lisible et un contrôle d'intégrité par empreinte sur chaque blob.",
        "La corbeille est un état, pas un second espace de stockage. Un fichier actif passe à l'état mis de côté, puis peut revenir à l'état actif, ou être purgé. La purge efface le blob et la ligne logique. Cette lecture prépare le diagramme de classes du chapitre 3, où le statut du fichier est un attribut, et le journal d'opérations une classe distincte. Le journal ne remplace pas la corbeille : il dit ce qui a été tenté, y compris les échecs, alors que le statut dit où se trouve le fichier.",
    ])
    _h(doc, add_h, "1.8 Modèle de menace retenu")
    _ps(doc, add_p, [
        "Un système de coffre se juge par ce qu'il protège et par ce qu'il laisse hors de son périmètre. Anderson (2020) rappelle qu'une conception de sécurité commence par les adversaires et les biens, non par une liste d'algorithmes. Pour ARSAVE, le bien principal est le contenu des fichiers. Les biens secondaires sont le mot de passe, la clé maître qui en est dérivée, et le jeton de session qui ouvre l'API. L'adversaire considéré au premier rang est celui qui lit la base MySQL, le disque des blobs, ou une copie de sauvegarde du serveur. L'adversaire considéré au second rang est celui qui observe le réseau entre le navigateur et l'API.",
        "Face au premier adversaire, le chiffrement du contenu avant l'envoi est la mesure centrale. S'il obtient les tables users, files, file_versions et les fichiers chiffrés, il voit des noms logiques, des tailles, des dates, des empreintes et des clés enveloppées. Il ne voit pas le clair, tant que la clé maître n'est pas sur le serveur. Cette hypothèse est exactement celle du chiffrement contrôlé par le client : le serveur est un dépositaire, pas un lecteur (OWASP Foundation, s. d.-a ; Ferguson, Schneier et Kohno, 2010). Face au second adversaire, TLS protège le jeton et le blob pendant le transit (Rescorla, 2018). TLS ne protège pas le disque au repos. Les deux mesures se complètent ; aucune ne remplace l'autre.",
        "D'autres adversaires sont reconnus et bornés. Un attaquant qui vole le mot de passe peut dériver la clé maître comme le ferait l'utilisateur légitime : le coffre ne distingue pas le voleur du titulaire une fois le secret connu. Un attaquant qui contrôle le navigateur après le déverrouillage voit le clair au moment où l'utilisateur le demande. Un administrateur du service peut supprimer un compte ou lire les métadonnées, mais il ne reçoit pas la clé de fichier. Ces limites sont assumées. Les écrire dans la revue évite de promettre, au chapitre 4, une protection que les algorithmes ne donnent pas (Katz et Lindell, 2020).",
        "Le modèle écarte aussi une menace que le MVP ne traite pas : le partage d'un fichier entre deux comptes, qui exigerait un second enveloppement de clé. Il écarte la résistance active d'un serveur malveillant qui modifierait le client web servi au navigateur. Cette dernière menace est réelle dans tout site, et elle est rappelée pour ne pas laisser croire que le chiffrement côté client dispense de servir une application intègre. Dans le périmètre du mémoire, le client est celui du projet, exécuté en local, et le serveur est celui de l'API décrite au chapitre 4.",
    ])
    _h(doc, add_h, "1.9 Chiffrement authentifié et AES-GCM")
    _ps(doc, add_p, [
        "AES est un algorithme de chiffrement par blocs, normalisé par le NIST (2001) et issu de Rijndael (Daemen et Rijmen, 2002). Un bloc seul ne chiffre pas un fichier de taille quelconque. Il faut un mode d'opération. Le mode GCM, décrit par Dworkin (2007), fournit le chiffrement et un sceau d'authenticité. Le destinataire qui ne possède pas la clé ne peut pas produire un sceau accepté, et une modification du ciphertext est détectée au déchiffrement. C'est la raison du choix : une sauvegarde qui se contenterait d'un mode sans authentification pourrait être altérée sans que la restauration s'en aperçoive tout de suite.",
        "GCM exige un nonce unique pour une clé donnée. Réutiliser un nonce avec la même clé compromet la confidentialité et l'authenticité (Dworkin, 2007 ; Ferguson, Schneier et Kohno, 2010). ARSAVE tire donc un nonce aléatoire pour chaque chiffrement de fichier, et un second nonce pour l'enveloppement de la clé de fichier. Ces deux valeurs voyagent avec le blob, en base64 (Josefsson, 2006). Elles ne sont pas secrètes. Le secret est la clé. Confondre nonce et clé est une erreur de lecture fréquente ; la revue la lève ici pour que les diagrammes de séquence du chapitre 3 montrent les nonces comme des données transmises, non comme des secrets retenus.",
        "La clé qui chiffre le fichier n'est pas la clé maître. Une clé de 256 bits est tirée pour le fichier, le clair est chiffré avec elle, puis cette clé est elle-même chiffrée sous la clé maître. Stallings (2020) et Menezes, van Oorschot et Vanstone (1996) présentent cet enveloppement comme le moyen de changer de clé de contenu sans changer le secret à long terme, et de limiter l'usage d'une même clé. Ici, l'effet cherché est plus simple : compromettre un blob ne livre pas les autres, et la clé maître n'est pas écrite à côté du fichier. Le serveur stocke la clé enveloppée, qu'il ne peut pas ouvrir.",
        "L'intégrité est vérifiée deux fois, à deux niveaux. GCM refuse un ciphertext modifié au moment du déchiffrement. L'empreinte SHA-256 du blob, calculée sur le ciphertext et non sur le clair, permet au client de détecter un remplacement du fichier avant même d'ouvrir le sceau, et permet au serveur de refuser un envoi dont l'empreinte annoncée ne correspond pas (NIST, 2015 ; Eastlake et Hansen, 2011). SHA-256 n'est pas un chiffrement. Il ne cache rien. Il détecte un changement. Le placer sur le clair aurait obligé le serveur à voir le clair, ce que le modèle de menace interdit.",
    ])
    _h(doc, add_h, "1.10 Mot de passe, sel et PBKDF2")
    _ps(doc, add_p, [
        "Le mot de passe joue deux rôles qu'il ne faut pas fusionner. Le premier est l'authentification auprès du serveur : le serveur conserve une empreinte de mot de passe et accepte ou refuse la connexion. Le deuxième est la dérivation de la clé maître sur le client : le même mot de passe, combiné à un sel, alimente PBKDF2 et produit 256 bits. Le serveur a besoin du premier résultat pour ouvrir une session. Il n'a pas besoin du second, et il ne le reçoit pas. Cette double vie du mot de passe est le cœur du système. Elle explique pourquoi un changement de mot de passe qui régénère le sel rend les anciennes clés enveloppées inutilisables : la clé maître change, et les enveloppes anciennes ne s'ouvrent plus.",
        "PBKDF2 est spécifié par PKCS #5 (Moriarty, Kaliski et Rusch, 2017) et recommandé pour la dérivation à partir d'un mot de passe par le NIST (Turan, Barker, Burr et Chen, 2010). Le sel empêche qu'une même chaîne de caractères produise la même clé chez deux utilisateurs, et empêche l'usage direct de tables précalculées. Le nombre d'itérations rend chaque essai coûteux. ARSAVE fixe ce coût à 120 000 itérations de HMAC-SHA256 (Krawczyk, Bellare et Canetti, 1997). La valeur est un paramètre de construction, cité ici pour que le chapitre 4 ne paraisse pas inventer un nombre. Elle doit rester identique entre l'inscription, qui crée le sel, et chaque connexion, qui redérive la clé.",
        "Les travaux sur les mots de passe montrent que les utilisateurs en choisissent de faibles et les réutilisent (Florêncio et Herley, 2007 ; Bonneau, Herley, van Oorschot et Stajano, 2012). Une fonction de dérivation coûteuse ralentit l'essai en ligne et hors ligne, elle ne transforme pas un mot de passe trivial en secret fort. Les guides d'authentification demandent une longueur minimale, un stockage d'empreinte adapté et une session révocable (OWASP Foundation, s. d.-b ; Grassi, Garcia et Fenton, 2017). ARSAVE s'inscrit dans cette ligne pour la partie serveur : empreinte de mot de passe, jeton aléatoire dont seule l'empreinte SHA-256 est conservée, expiration de session. La partie client ajoute la dérivation locale, que ces guides d'authentification web ne décrivent pas toujours, parce qu'ils visent l'accès au compte et non le chiffrement du contenu.",
        "Le sel de dérivation est stocké en clair dans le compte. Ce n'est pas une fuite. Un sel secret n'apporterait rien à PBKDF2 tel qu'il est défini : il doit être relu pour recalculer la clé (Turan et al., 2010). Le secret reste le mot de passe. En revanche, le sel ne doit pas être réutilisé d'un utilisateur à l'autre, et il ne doit pas changer sans une procédure qui réenveloppe les clés de fichiers. La revue fixe donc une exigence que la construction ne satisfait que pour le chemin nominal : le sel est stable tant que le mot de passe ne change pas. La réinitialisation est documentée comme une limite, non comme un scénario nominal du chapitre 3.",
    ])
    _h(doc, add_h, "1.11 Sessions et jetons porteur")
    _ps(doc, add_p, [
        "Après l'authentification, le client ne renvoie pas le mot de passe à chaque requête. Il présente un jeton porteur dans l'en-tête Authorization. L'API ne stocke pas ce jeton. Elle stocke son empreinte SHA-256, la date d'expiration et l'utilisateur. Présenter le jeton prouve la possession du secret de session ; la base, si elle est lue, ne permet pas de rejouer le jeton (OWASP Foundation, s. d.-c ; NIST, 2015). La déconnexion efface la session côté serveur. Une session expirée est refusée même si le client l'a encore en mémoire.",
        "Sur le web, le jeton et le sel doivent rester disponibles le temps de la visite, parce que la clé maître est redérivée à la connexion et que les sauvegardes suivantes en ont besoin. Le navigateur n'offre pas le même coffre matériel qu'un téléphone. Le client web conserve donc la session dans le stockage local du navigateur pour la durée d'usage, et l'efface à la déconnexion. Cette précision relève encore de la revue : elle explique pourquoi le chapitre 4 distinguera le poste natif et le navigateur sans changer le contrat de l'API. Le serveur, lui, ne voit qu'un jeton et un sel de dérivation.",
        "L'appareil est enregistré à part. Un identifiant d'appareil et un nom d'affichage accompagnent la connexion, afin que le journal et les versions sachent depuis quel poste le dépôt a eu lieu. L'identifiant n'authentifie pas à lui seul. Il complète la session. Deux connexions du même compte peuvent ainsi être distinguées dans l'historique sans partager la clé maître entre les postes : chaque poste redérive la clé à partir du mot de passe et du sel reçu à la connexion.",
    ])
    _h(doc, add_h, "1.12 API REST, JSON et formulaires multipart")
    _ps(doc, add_p, [
        "Fielding (2000) définit REST comme un style d'architecture sur HTTP, où les ressources sont identifiées par des URL et manipulées par les méthodes du protocole. ARSAVE suit cet usage de façon pragmatique. Les comptes, fichiers, versions, opérations et utilisateurs administrés sont des ressources. Les méthodes GET lisent, POST crée ou déclenche une action, PUT met à jour, DELETE retire. Les corps structurés sont en JSON (Bray, 2017). Les erreurs sont des codes HTTP accompagnés d'un message que le client peut afficher (Fielding et Reschke, 2014).",
        "Le dépôt d'un fichier chiffré n'est pas un document JSON. Le blob est binaire. Le formulaire multipart permet d'envoyer le binaire et les champs texte dans la même requête (Masinter, 2015). Les champs portent le nom logique, le type, l'empreinte, les nonces et la clé enveloppée. Cette forme est un choix d'interface, non un choix cryptographique. Elle a une conséquence directe sur le client web : le navigateur ne fournit pas un chemin de disque exploitable comme un système de fichiers local. Le client doit donc lire les octets, les chiffrer en mémoire, puis les poster. La revue le note ici parce que cette contrainte explique des échecs d'envoi si l'on traite le web comme un disque.",
        "L'API n'est pas le modèle du domaine. Elle en est une vue. Le diagramme de classes du chapitre 3 décrit Utilisateur, Session, Appareil, Fichier, Version et Opération. Les routes du chapitre 4 et de l'annexe D réalisent les opérations de ces classes. Garder cette distinction est une discipline UP : le cas d'utilisation dit ce que l'acteur obtient, la classe dit ce qui est retenu, la route dit comment le message HTTP est formé (Larman, 2004 ; Jacobson, Booch et Rumbaugh, 1999).",
    ])
    _h(doc, add_h, "1.13 Qualité attendue du coffre")
    _ps(doc, add_p, [
        "ISO/IEC 25010 distingue plusieurs caractéristiques de qualité. Pour ARSAVE, quatre sont retenues comme grille, sans transformer le mémoire en audit de norme. L'aptitude fonctionnelle demande que l'utilisateur puisse déposer, retrouver, restaurer et écarter un fichier, et que l'administrateur puisse gérer les comptes sans lire le contenu. La sécurité demande la confidentialité du clair, l'intégrité du blob et le contrôle d'accès par session. L'utilisabilité demande un client web lisible : tableau de bord, coffre, historique, messages d'erreur. La maintenabilité demande une séparation client, API et base, afin qu'un changement d'écran ne réécrive pas le chiffrement.",
        "ISO/IEC 27001 porte sur le management de la sécurité, non sur un algorithme. Elle est citée pour rappeler que la protection des fichiers ne se réduit pas à AES : il faut aussi décider qui administre les comptes, comment une session s'arrête, et quelles traces restent après une suppression (ISO/IEC, 2022). ARSAVE n'implémente pas un système de management. Il en retient l'idée de séparation des devoirs : l'administrateur du service n'est pas le lecteur des fichiers. Cette idée devient, au chapitre 3, la frontière entre l'acteur Utilisateur et l'acteur Administrateur.",
        "Les principes de Saltzer et Schroeder (1975) recoupent ces choix. Le privilège minimal apparaît dans le rôle : un utilisateur simple n'appelle pas les routes d'administration. L'économie de mécanisme apparaît dans un seul chemin de chiffrement, appliqué à tout fichier, plutôt que dans des exceptions par type. La médiation complète apparaît dans le contrôle de session et d'appartenance avant chaque lecture de blob. Le défaut sûr apparaît dans les branches d'échec : si la lecture locale ou l'enregistrement échoue, aucune version réussie n'est créée. Ces principes seront relus sur les diagrammes, non répétés comme une seconde méthode de conception.",
    ])
    _h(doc, add_h, "1.14 Unified Process comme fil du mémoire")
    _ps(doc, add_p, [
        "Le Unified Process organise le travail en quatre phases. L'inception identifie le problème, les acteurs et les cas les plus risqués. L'élaboration stabilise l'architecture et les scénarios qui portent le risque, ici le chiffrement avant envoi et la session. La construction réalise les cas jusqu'à un produit utilisable. La transition prépare le déploiement et traite ce qui reste hors du produit livré (Jacobson, Booch et Rumbaugh, 1999 ; Kruchten, 2004). Le mémoire suit cet ordre sans le nommer à chaque page : le chapitre 1 et le chapitre 2 éclairent l'inception, le chapitre 3 est l'élaboration, le chapitre 4 est la construction. La transition est présente seulement par les limites assumées.",
        "UML est la notation, pas une méthode concurrente. Les cas d'utilisation portent les objectifs des acteurs (Cockburn, 2001). Les diagrammes de séquence montrent les messages d'un scénario nominal. Le diagramme d'activité montre les décisions, y compris les échecs que la séquence ne dessine pas. Le diagramme de classes fixe le vocabulaire du domaine (OMG, 2017 ; Rumbaugh, Jacobson et Booch, 2004 ; Fowler, 2003 ; Booch, Rumbaugh et Jacobson, 2005). Aucun de ces dessins ne remplace le texte du scénario. Cockburn insiste sur le fait qu'un cas s'écrit en étapes, avec préconditions et extensions. Le chapitre 3 donnera les dessins ; les fiches développées complètent ces dessins afin que chaque flèche ait une phrase.",
        "Larman (2004) relie les cas aux objets par une conception par responsabilités. Pour ARSAVE, la responsabilité de chiffrer est sur le client. La responsabilité d'autoriser est sur l'API. La responsabilité de conserver est sur la base et le disque des blobs. Cette répartition est déjà une décision d'architecture. Elle sera dessinée comme une figure de déploiement logique au chapitre 4, et elle explique l'inclusion « chiffrer le fichier » sur le cas « sauvegarder » : le chiffrement n'est pas un cas que l'utilisateur déclenche seul, il est inclus dans le dépôt.",
        "Le mémoire ne change pas de méthode entre les chapitres. Les produits du marché, au chapitre 2, sont lus avec les mêmes questions que les cas : qui dépose, qui peut lire, qui administre, que devient un fichier supprimé. Cette stabilité évite d'analyser Drive avec une grille, puis de concevoir ARSAVE avec une autre. La conclusion du chapitre peut donc transmettre quatre exigences, et seulement quatre : sauvegarde versionnée avec corbeille, chiffrement avant envoi, clé maître absente du serveur, conduite par les cas d'utilisation.",
    ])
    add_table(
        doc,
        ["Phase UP", "Question", "Où le mémoire y répond"],
        [
            ["Inception", "Quel problème et quels acteurs ?", "Chapitres 1 et 2, puis acteurs du chapitre 3"],
            ["Élaboration", "Quels scénarios portent le risque ?", "Chapitre 3 : cas, séquences, activité, classes"],
            ["Construction", "Comment les cas sont-ils réalisés ?", "Chapitre 4 : client, API, MySQL"],
            ["Transition", "Que reste-t-il hors du produit ?", "Limites : mot de passe, partage, admin étendu"],
        ],
    )
    add_p(doc, "Tableau 2. Phases du Unified Process et chapitres du mémoire", italic=True, center=True, first_line=False)
    from memoire_plus import plus_1
    plus_1(doc, add_h, add_p, add_table)


def extra_chapitre_2(doc, add_h, add_p, add_table):
    _h(doc, add_h, "2.7 Lecture par scénario d'usage")
    _ps(doc, add_p, [
        "Comparer des produits fiche par fiche ne suffit pas. Le Unified Process demande de revenir aux objectifs de l'acteur (Cockburn, 2001). Quatre scénarios d'usage servent donc de grille commune. Le premier est le dépôt d'un fichier depuis un navigateur. Le deuxième est la reprise de ce fichier sur le même poste ou un autre, après une nouvelle connexion. Le troisième est l'effacement réversible, puis la suppression définitive. Le quatrième est la gestion des comptes par une personne qui administre le service sans être le propriétaire de chaque fichier. Chaque produit est relu avec ces quatre questions, et seulement avec elles.",
        "Sur le dépôt, Drive, Dropbox et OneDrive sont immédiats : l'utilisateur dépose le clair, le service le stocke et le rend disponible (Google, s. d. ; Dropbox, s. d. ; Microsoft, s. d.). La reprise est également immédiate, y compris depuis un autre appareil relié au même compte. La corbeille existe. L'administration d'entreprise existe dans les offres de groupe. Le point de rupture, pour le besoin d'ARSAVE, n'est pas la fonction de coffre. C'est le lecteur possible : l'opérateur du service est dans le périmètre de confiance du contenu. Une sauvegarde de leur base n'est pas un ensemble de blobs indéchiffrables par eux.",
        "MEGA se sépare de ce trio sur le chiffrement annoncé côté client (Mega Ltd, s. d.). Le dépôt et la reprise restent des fonctions de coffre, et la promesse publique est que le service ne détient pas la clé de contenu de la même façon. L'administration locale d'un petit serveur que l'on installe soi-même n'est pas le centre du produit : MEGA est d'abord un service opéré. Pour un mémoire qui doit montrer une API, une base et un client web dans un déploiement local, MEGA est une référence de principe cryptographique, pas un socle à modifier.",
        "Nextcloud couvre les quatre scénarios dans un déploiement que l'on héberge : dépôt, reprise, corbeille, comptes et groupes (Nextcloud GmbH, s. d.). C'est le plus proche d'ARSAVE sur l'administration. Le chiffrement de bout en bout y est documenté comme une fonction distincte du stockage ordinaire. Le mode par défaut du fichier sur le serveur n'est donc pas celui qu'ARSAVE impose à chaque envoi. L'écart n'est pas l'absence de coffre. L'écart est l'obligation de chiffrer avant la requête, sans chemin qui accepterait un clair.",
    ])
    _h(doc, add_h, "2.8 Ce que les documents publics permettent d'affirmer")
    _ps(doc, add_p, [
        "Une analyse de systèmes existants, dans un mémoire, ne dispose que des documents publics et du comportement observable. Elle ne dispose pas du code interne de Drive, de Dropbox, d'OneDrive ou de MEGA. Les affirmations du chapitre restent donc au niveau de ces documents : sécurité décrite par l'éditeur, présence d'une corbeille, présence d'une administration, présence ou non d'un chiffrement dont la clé n'est pas celle du serveur (Google, s. d. ; Dropbox, s. d. ; Microsoft, s. d. ; Mega Ltd, s. d. ; Nextcloud GmbH, s. d.). Lorsqu'un détail de format n'est pas publié, le mémoire ne l'invente pas.",
        "Cette retenue change la nature de la comparaison. Le tableau 1 ne note pas des produits. Il aligne des réponses oui ou non sur des critères tirés du chapitre 1. Un « non » sur la ligne « clé maître absente du serveur » signifie que le document public place le contenu dans le périmètre de l'opérateur, ou qu'il ne promet pas le contraire. Un « oui » pour MEGA signifie que la documentation de sécurité revendique un contrôle de la clé par l'utilisateur. Un « selon le mode » pour Nextcloud signifie que la documentation distingue le chiffrement serveur et le chiffrement de bout en bout.",
        "ARSAVE est dans la dernière colonne non pas comme un produit supérieur en fonctions, mais comme le système que le mémoire propose pour combler l'écart. Il n'a pas l'écosystème, le partage, ni l'édition collaborative des services étudiés. Ces absences sont des hors périmètre, pas des oublis d'analyse. Les citer évite qu'un lecteur croie que le chapitre 3 va reconstruire Drive. Le chapitre 3 ne reprend que l'écart : coffre web, chiffrement systématique avant envoi, administration des comptes sans lecture du clair.",
    ])
    _h(doc, add_h, "2.9 Critères retenus et critères écartés")
    add_table(
        doc,
        ["Critère", "Pourquoi il est retenu", "Lien avec un cas futur"],
        [
            ["Dépôt depuis le web", "L'acteur travaille dans le navigateur", "Sauvegarder un fichier"],
            ["Reprise du clair", "La sauvegarde n'a de sens que si l'on récupère", "Restaurer un fichier"],
            ["Versions", "Un même nom peut être renvoyé", "Sauvegarder, consulter les versions"],
            ["Corbeille", "L'effacement immédiat est trop brutal", "Mettre en corbeille, purger"],
            ["Chiffrement avant envoi", "Le serveur ne doit pas lire le contenu", "Inclusion Chiffrer"],
            ["Clé absente du serveur", "Même exigence, vérifiée sur le stockage", "Classe VersionFichier"],
            ["Journal", "L'utilisateur doit voir ce qui a réussi ou échoué", "Consulter l'historique"],
            ["Admin des comptes", "Un rôle distinct gère les utilisateurs", "Gérer les comptes"],
        ],
    )
    add_p(doc, "Tableau 3. Critères de comparaison reliés aux cas d'utilisation", italic=True, center=True, first_line=False)
    _ps(doc, add_p, [
        "D'autres critères, utiles pour un choix d'entreprise, sont écartés parce qu'ils ne distinguent pas le besoin du mémoire. Le prix, le volume offert, l'édition en ligne et le partage de liens ne changent pas la décision de chiffrer avant l'envoi. Les citer aurait allongé le tableau sans éclairer la conception. La synchronisation continue d'un dossier local est également écartée : ARSAVE dépose un fichier choisi par l'utilisateur, il ne surveille pas un répertoire. Ce choix simplifie le cas d'utilisation et correspond au client web, où le navigateur ouvre un sélecteur plutôt qu'un disque entier.",
        "Le critère d'administration est gardé parce que le mémoire demande une partie web pour gérer les comptes. Les offres grand public gèrent un compte individuel. Les offres d'entreprise gèrent des organisations, souvent avec un pouvoir d'administration étendu sur les fichiers. ARSAVE se place entre les deux : il y a un rôle admin, mais ce rôle ne reçoit pas le déchiffrement. Cette ligne du tableau 1 est donc la plus facile à mal lire. « Admin des comptes : oui » ne signifie pas « admin lecteur des fichiers ». La colonne ARSAVE le précise par la ligne suivante : lecture du fichier par le serveur, impossible.",
    ])
    _h(doc, add_h, "2.10 Écart formulé pour la conception")
    _ps(doc, add_p, [
        "L'écart peut maintenant s'écrire comme un énoncé de problème, au sens de l'inception (Kruchten, 2004). Les services généralistes couvrent le dépôt, la reprise et la corbeille, avec un opérateur capable de lire le contenu. MEGA couvre un chiffrement côté client dans un service opéré. Nextcloud couvre l'hébergement et les comptes, avec un chiffrement de bout en bout optionnel. Il manque un système local, décrit de bout en bout, où chaque dépôt web est chiffré avant la requête, où la clé maître ne quitte pas le poste, et où un administrateur gère les comptes sans devenir lecteur.",
        "Cet énoncé fixe le périmètre négatif autant que le périmètre positif. Ne sont pas repris : la collaboration temps réel, le partage de lien public, la synchronisation de dossier, la conformité à un schéma d'entreprise, l'édition de documents. Sont repris : l'inscription, la connexion, le dépôt, la restauration, l'historique, la corbeille, le tableau de bord et l'administration des rôles. Le chapitre 3 transforme cette liste en acteurs et en cas. Il ne rouvre pas la comparaison. Lorsqu'une fonction des produits étudiés réapparaît, c'est seulement comme nom de cas, par exemple la corbeille, et non comme une copie de leur interface.",
        "La conséquence pour les diagrammes est directe. Le cas « Sauvegarder un fichier » inclut « Chiffrer le fichier », parce que l'écart à combler est précisément l'absence de chemin en clair. Si le chiffrement était optionnel, l'inclusion serait fausse et un second cas « déposer en clair » apparaîtrait. Ce second cas est refusé. De même, « Gérer les comptes » n'inclut pas « Restaurer un fichier » : l'administrateur n'est pas un utilisateur qui lirait les coffres des autres. Cette interdiction, lue sur les produits existants comme une différence de pouvoir, devient au chapitre 3 une limite d'acteur.",
    ])
    from memoire_plus import plus_2
    plus_2(doc, add_h, add_p, add_table)


def extra_chapitre_3(doc, add_h, add_p, add_table):
    _h(doc, add_h, "3.8 Fiches développées des cas d'utilisation")
    _ps(doc, add_p, [
        "Les ellipses de la figure 1 nomment les buts. Elles ne remplacent pas le scénario écrit. Chaque fiche qui suit donne l'acteur, le but, le niveau, les préconditions, le déclencheur, le scénario nominal et les extensions. Le niveau est celui de l'objectif utilisateur, au sens de Cockburn (2001) : une fiche correspond à ce qu'une personne vient faire, pas à une requête HTTP isolée. Les extensions renvoient au diagramme d'activité lorsqu'elles concernent la sauvegarde, et à l'annexe B pour les deux alternatives déjà résumées.",
    ])
    _h(doc, add_h, "3.8.1 S'inscrire")
    _ps(doc, add_p, [
        "Acteur : utilisateur non authentifié. But : obtenir un compte. Précondition : l'adresse n'est pas déjà enregistrée. Déclencheur : l'utilisateur valide le formulaire d'inscription avec un nom, une adresse et un mot de passe. Nominal : le client envoie ces trois champs ; l'API vérifie l'unicité de l'adresse, calcule l'empreinte du mot de passe, tire un sel de dérivation, crée la ligne utilisateur avec le rôle simple, et confirme. Le sel n'est pas choisi par l'utilisateur. Il est produit par le serveur afin que deux comptes ne partagent pas le même sel, puis il sera renvoyé à la connexion pour la dérivation locale. Postcondition : un compte existe, aucun fichier n'existe encore, aucune clé maître n'a été stockée.",
        "Extensions. Si l'adresse existe, l'API refuse et le client affiche l'erreur : aucun second compte n'est créé. Si le mot de passe est trop court par rapport à la règle du formulaire, le client n'envoie pas la requête. Si le réseau échoue, le compte n'est pas supposé créé ; l'utilisateur peut réessayer. L'inscription ne connecte pas automatiquement dans tous les chemins du mémoire : le cas « S'authentifier » reste distinct, afin que le diagramme de séquence de la figure 2 ait un début clair, le formulaire de connexion.",
    ])
    _h(doc, add_h, "3.8.2 S'authentifier")
    _ps(doc, add_p, [
        "Acteur : utilisateur. But : ouvrir une session et disposer de la clé maître sur le poste. Précondition : un compte existe. Déclencheur : validation du formulaire de connexion, avec l'identifiant d'appareil. Nominal, aligné sur la figure 2 : le client envoie l'adresse, le mot de passe et l'appareil ; l'API vérifie l'empreinte ; en cas de succès elle enregistre ou met à jour l'appareil, crée une session, retourne le jeton, la date d'expiration, le profil et le sel ; le client dérive la clé maître par PBKDF2 et la garde en mémoire. Postcondition : les routes suivantes acceptent le jeton ; la clé maître n'a pas voyagé.",
        "Extensions. Identifiants refusés : pas de session, pas de dérivation, message affiché (annexe B). Session ensuite expirée : la requête métier reçoit un refus, le client ramène à la connexion. Déconnexion : le client oublie jeton et clé, l'API invalide la session. Ce cas est le scénario 1 du mémoire. Il est nominal. Les extensions ne sont pas dessinées sur la figure 2, conformément au choix de ne montrer que le chemin réussi sur les séquences, et de réserver les décisions au diagramme d'activité ou au texte.",
    ])
    _h(doc, add_h, "3.8.3 Sauvegarder un fichier")
    _ps(doc, add_p, [
        "Acteur : utilisateur authentifié. But : déposer un fichier de n'importe quel type dans le coffre. Précondition : session valide et clé maître présente. Déclencheur : choix d'un fichier dans le sélecteur, puis confirmation. Nominal, aligné sur la figure 3 et sur le chemin « oui » de la figure 4 : le client lit les octets ; il tire une clé de fichier et deux nonces ; il chiffre le clair en AES-256-GCM ; il enveloppe la clé de fichier ; il calcule l'empreinte du ciphertext ; il envoie le blob et les champs ; l'API vérifie le jeton, l'appartenance et la cohérence de l'empreinte ; elle écrit le blob, la version et l'opération réussie ; le coffre affiche le nouveau fichier. Postcondition : une version existe, le clair n'est ni en base ni sur le disque du serveur.",
        "Le cas inclut « Chiffrer le fichier ». L'inclusion, sur la figure 1, signifie que sauvegarder sans chiffrer n'est pas un scénario permis. L'utilisateur ne voit pas une étape séparée intitulée chiffrer : l'inclusion est une obligation du système, pas un second bouton. C'est conforme à UML, où include factorise un comportement obligatoire (OMG, 2017 ; Fowler, 2003).",
        "Extensions, alignées sur la figure 4. Fichier illisible : message, pas de blob. Session absente ou expirée : message, pas de version. Empreinte incohérente ou champ manquant : l'API refuse. Limite de taille dépassée : refus avant écriture utile. Dans tous ces cas, le journal peut noter un échec, mais il ne doit pas présenter une sauvegarde réussie. Une nouvelle version du même fichier logique réutilise l'identifiant et incrémente le numéro de version. Le nom logique reste celui choisi ; le type MIME sert à l'icône et, pour une image de taille limitée, à la miniature déchiffrée localement.",
    ])
    _h(doc, add_h, "3.8.4 Restaurer un fichier")
    _ps(doc, add_p, [
        "Acteur : utilisateur authentifié, propriétaire du fichier. But : retrouver les octets en clair. Précondition : au moins une version existe et la clé maître est disponible. Déclencheur : action de restauration sur un fichier du coffre ou, selon l'écran, sur une version. Nominal : le client demande le blob ; l'API vérifie le jeton et l'appartenance, puis renvoie le ciphertext et les en-têtes de nonce, de clé enveloppée et d'empreinte ; le client recalcule l'empreinte ; si elle correspond, il ouvre l'enveloppe avec la clé maître, déchiffre, et propose le clair en téléchargement dans le navigateur. Postcondition : le serveur n'a toujours pas le clair ; le poste, lui, l'a produit pour l'utilisateur.",
        "Extensions. Empreinte différente : le client refuse de déchiffrer et affiche l'erreur. Clé maître absente, par exemple après un rechargement qui a perdu la mémoire de session : il faut se reconnecter. Fichier d'un autre compte : l'API refuse, même si l'identifiant est deviné. La miniature d'image suit le même déchiffrement, mais elle reste à l'écran au lieu d'être proposée comme téléchargement, et seulement si l'utilisateur a laissé l'option d'aperçu activée et si l'image reste dans la limite de taille. La miniature n'est pas un second cas d'utilisation : c'est une variante d'affichage du cas restaurer, bornée aux images.",
    ])
    _h(doc, add_h, "3.8.5 Consulter le coffre, l'historique et le tableau de bord")
    _ps(doc, add_p, [
        "Trois cas de consultation partagent la même précondition de session et diffèrent par la ressource lue. Consulter le coffre liste les fichiers actifs, avec recherche et filtre par genre (image, vidéo, audio, document, archive, autre). Consulter la corbeille liste les fichiers écartés. Consulter l'historique liste les opérations récentes, réussies ou non. Consulter le tableau de bord agrège des indicateurs : nombre de fichiers, volume, éléments en corbeille, activité, répartition par genre et dépôts des derniers jours. Aucun de ces cas ne demande le clair des fichiers, sauf la miniature qui relève de la restauration locale déjà décrite.",
        "Le tableau de bord n'est pas une source de vérité distincte. Il relit les fichiers et les opérations. Un indicateur faux serait un défaut d'affichage, pas un second stock. Cette remarque guide la classe Operation et la classe Fichier : le diagramme de la figure 5 suffit, il n'ajoute pas une classe Statistique. Les graphiques sont une présentation. Ils seront réalisés au chapitre 4 sans nouveau concept de domaine.",
    ])
    _h(doc, add_h, "3.8.6 Gérer la corbeille")
    _ps(doc, add_p, [
        "Acteur : propriétaire. But : écarter un fichier sans le perdre, le remettre, ou le détruire. Précondition : le fichier appartient à l'utilisateur. Nominal de mise en corbeille : le statut passe à écarté, la date d'écart est posée, une opération est journalisée, le fichier disparaît du coffre actif et apparaît dans la corbeille. Nominal de remise : le statut redevient actif. Nominal de purge : les versions et les blobs sont effacés, le fichier disparaît des deux listes. Extensions : fichier déjà purgé, ou identifiant d'un autre compte, refus. La purge est irréversible. Le texte du cas le dit afin que l'interface demande une confirmation, ce que le chapitre 4 reprendra.",
    ])
    _h(doc, add_h, "3.8.7 Régler le compte et quitter")
    _ps(doc, add_p, [
        "L'utilisateur authentifié peut changer son nom d'affichage. Il peut choisir le thème sombre ou le thème clair, choix local à l'affichage, sans effet sur le chiffrement. Il peut autoriser ou non les miniatures : les refuser évite de déchiffrer une image seulement pour l'afficher en petit. Il peut ouvrir la corbeille depuis les paramètres. Il peut se déconnecter. Ces cas sont secondaires par rapport au dépôt, mais ils font partie du client web demandé. Ils n'ajoutent pas de classe métier : le thème et le choix d'aperçu vivent sur le poste, le nom vit sur Utilisateur.",
        "La réinitialisation du mot de passe existe comme route, et elle est décrite ici comme extension hors scénario nominal. Elle régénère le sel. Les enveloppes anciennes deviennent inutilisables. Le cas n'est donc pas promis comme une récupération du coffre. Le dire dans la fiche évite qu'un lecteur du diagramme de classes croie que password_resets suffit à conserver l'accès au clair. La table sert à prouver qu'un jeton de réinitialisation a été demandé ; elle ne réenveloppe pas les clés.",
    ])
    _h(doc, add_h, "3.8.8 Gérer les comptes")
    _ps(doc, add_p, [
        "Acteur : administrateur, c'est-à-dire un utilisateur dont le rôle est admin. But : voir les comptes, changer un rôle, supprimer un compte. Précondition : session d'un administrateur. L'acteur utilisateur simple ne voit pas l'entrée. Nominal de consultation : l'API retourne la liste des comptes et des indicateurs globaux, sans blob et sans clé. Nominal de changement de rôle : un compte simple devient admin, ou l'inverse, sauf si l'opération retire le dernier administrateur ou se dégrade soi-même de façon interdite. Nominal de suppression : les blobs du compte sont effacés, puis les lignes du compte sont retirées par les clés étrangères en cascade. Postcondition : les fichiers de ce compte ne sont plus au coffre ; les autres comptes sont intacts.",
        "Extensions. Suppression de soi-même : refus. Suppression du dernier administrateur : refus. Appel des routes admin avec un jeton d'utilisateur simple : refus. Aucune extension ne livre une clé de déchiffrement, parce que l'administrateur ne l'a jamais reçue. Le cas n'inclut donc pas « Restaurer un fichier » d'un autre propriétaire. Cette absence d'inclusion est aussi importante que l'inclusion du chiffrement sur la sauvegarde.",
    ])
    _h(doc, add_h, "3.9 Lecture des diagrammes de séquence")
    _ps(doc, add_p, [
        "La figure 2 aligne quatre participants : l'utilisateur, le client, l'API et la base. Le premier message est la saisie. Le client ne dessine pas la clé maître avant la réponse, parce qu'il n'a pas encore le sel. L'API interroge le compte, vérifie l'empreinte, écrit l'appareil et la session, puis répond. Le dernier message local, dériver la clé, est un appel du client vers lui-même. Sur le dessin, il est montré comme une boucle sur le client, non comme une flèche vers l'API. Cette forme évite de laisser croire que PBKDF2 s'exécute côté serveur.",
        "La figure 3 reprend les mêmes participants et ajoute le disque des blobs comme lieu d'écriture, selon le niveau de détail retenu sur le dessin. L'ordre impose le chiffrement avant l'envoi multipart. Si une flèche « poster » apparaissait avant « chiffrer », le scénario contredirait le chapitre 1. L'API répond seulement après l'écriture de la version. Le client rafraîchit alors la liste. Les messages d'erreur ne sont pas sur cette figure. Ils sont dans la fiche 3.8.3 et sur la figure 4. Lire les deux séquences comme si elles étaient les seuls chemins possibles serait une faute : UML permet de fixer le nominal à part (Rumbaugh, Jacobson et Booch, 2004).",
        "Les retours portent les données utiles et rien de plus. Au login, le retour porte le jeton et le sel, pas la clé maître. Au dépôt, le retour porte l'identifiant de fichier et le succès, pas le clair. Au téléchargement, qui n'est pas la figure 3 mais le cas restaurer, le retour porte le ciphertext et les champs cryptographiques. Cette discipline de message prépare les contrats d'API : un champ absent du scénario ne doit pas apparaître « pour voir » dans le JSON.",
    ])
    _h(doc, add_h, "3.10 Lecture du diagramme d'activité")
    _ps(doc, add_p, [
        "La figure 4 est verticale. Elle commence lorsque l'utilisateur choisit un fichier. La première décision demande si les octets sont lisibles. La branche non affiche un message et s'arrête. La branche oui enchaîne le chiffrement, l'empreinte et l'envoi. La seconde décision demande si l'enregistrement est accepté. La branche non affiche l'erreur de l'API. La branche oui journalise le succès et montre le fichier dans le coffre. Il n'y a pas de troisième décision cachée. Les deux losanges suffisent à couvrir les extensions du cas sauvegarder.",
        "Le diagramme n'est pas un organigramme d'écran. Les actions « chiffrer » et « envoyer » sont des responsabilités, pas des boutons. L'utilisateur n'a qu'un geste : choisir le fichier. Le système déroule le reste. Cette lecture correspond à l'inclusion du cas chiffrer. Elle correspond aussi au principe de défaut sûr : sortir par une branche non laisse le coffre comme avant (Saltzer et Schroeder, 1975).",
    ])
    _h(doc, add_h, "3.11 Lecture du diagramme de classes")
    _ps(doc, add_p, [
        "La figure 5 donne le vocabulaire que MySQL reprendra. Utilisateur possède l'adresse, le nom, le rôle, l'empreinte de mot de passe et le sel. Il est relié à plusieurs sessions, plusieurs appareils, plusieurs fichiers et plusieurs opérations. Les cardinalités sont 1 à plusieurs du côté des objets dépendants, et chaque dépendant appartient à un utilisateur. La suppression d'un utilisateur emporte ses dépendants : c'est la cascade que le cas « supprimer un compte » exige.",
        "Fichier porte le nom logique, le type, le statut et la date d'écart éventuelle. Il possède plusieurs versions. Une version porte le numéro, la taille, le chemin du blob, l'empreinte, le nonce, la clé enveloppée et le nonce d'enveloppe. La version ne porte pas la clé maître, ni le clair. Opération porte le type, le statut, un message et la date, avec un lien facultatif vers un fichier : une opération de connexion peut ne pas viser un fichier, une opération de dépôt le vise. Session porte l'empreinte du jeton et l'expiration, et peut pointer vers un appareil. Appareil porte l'identifiant stable et le nom affiché.",
        "Les responsabilités se lisent sur les associations, pas seulement sur les attributs. Le client, qui n'est pas une classe persistante du domaine, crée le ciphertext avant qu'une Version existe. La classe Version reçoit le résultat. Cette nuance évite de placer une opération chiffrer() sur une classe serveur. Le diagramme de domaine ne dessine pas CryptoService : ce service est une classe de construction, introduite au chapitre 4, qui réalise l'inclusion « chiffrer » sans devenir une table.",
    ])
    add_table(
        doc,
        ["Classe", "Responsabilité", "Ne contient pas"],
        [
            ["Utilisateur", "Identité, rôle, sel, empreinte du mot de passe", "Clé maître, clair des fichiers"],
            ["Session", "Prouver une connexion encore valide", "Mot de passe, jeton en clair"],
            ["Appareil", "Nommer le poste d'origine", "Clé de chiffrement"],
            ["Fichier", "Nom, type, statut dans le coffre ou la corbeille", "Octets du contenu"],
            ["VersionFichier", "Blob, nonce, clé enveloppée, empreinte", "Clé maître, clair"],
            ["Operation", "Tracer le type et le succès ou l'échec", "Le contenu du fichier"],
        ],
    )
    add_p(doc, "Tableau 4. Responsabilités des classes du domaine", italic=True, center=True, first_line=False)
    _h(doc, add_h, "3.12 Traçabilité entre les artefacts UP")
    _ps(doc, add_p, [
        "Un modèle UML est utile s'il se suit d'un dessin à l'autre. Le tableau 5 relie chaque cas structurant au scénario, à la classe principale et à la route qui sera réalisée. Cette matrice est l'outil de passage vers la construction. Si une route du chapitre 4 n'apparaît pas ici, elle doit être une route technique d'un cas déjà nommé, par exemple le téléchargement d'une version, et non un but nouveau. Si un cas apparaît ici sans route, la construction est incomplète.",
    ])
    add_table(
        doc,
        ["Cas", "Scénario ou figure", "Classe principale", "Route principale"],
        [
            ["S'inscrire", "Fiche 3.8.1", "Utilisateur", "POST /auth/register"],
            ["S'authentifier", "Figure 2", "Session, Appareil", "POST /auth/login"],
            ["Sauvegarder", "Figures 3 et 4", "Fichier, VersionFichier", "POST /files"],
            ["Restaurer", "Fiche 3.8.4", "VersionFichier", "GET /files/{id}/download"],
            ["Historique", "Fiche 3.8.5", "Operation", "GET /operations"],
            ["Corbeille", "Fiche 3.8.6", "Fichier", "POST /files/{id}/trash"],
            ["Gérer les comptes", "Fiche 3.8.8", "Utilisateur (rôle)", "GET /admin/users"],
        ],
    )
    add_p(doc, "Tableau 5. Traçabilité cas, classes et routes", italic=True, center=True, first_line=False)
    _ps(doc, add_p, [
        "La matrice sert aussi à relire les chapitres précédents. Chaque ligne répond à un critère du tableau 3. Le dépôt web est la ligne Sauvegarder. La reprise est Restaurer. La clé absente du serveur se vérifie dans la colonne « ne contient pas » du tableau 4, pour VersionFichier. L'admin est la dernière ligne, et son acteur n'est pas le propriétaire des fichiers listés. Ainsi, l'écart du chapitre 2 n'est pas perdu au moment de dessiner : il est devenu des cases.",
    ])
    from memoire_plus import plus_3
    plus_3(doc, add_h, add_p, add_table)


def extra_chapitre_4(doc, add_h, add_p, add_table):
    _h(doc, add_h, "4.6 Organisation de la construction")
    _ps(doc, add_p, [
        "La construction suit la répartition des responsabilités fixée en élaboration. Trois composants l'incarnent. Le client Flutter, lancé pour le web dans Chrome, porte les écrans, le chiffrement et l'appel HTTP. L'API PHP porte le contrôle de session, les règles de rôle et l'écriture des métadonnées. MySQL porte les tables du diagramme de classes, et le disque porte les blobs. La figure d'architecture du mémoire place ces trois blocs et rappelle que la clé maître s'arrête dans le client. Cette figure n'est pas un quatrième formalisme : c'est une vue de déploiement des mêmes classes.",
        "Le dépôt local de démonstration utilise l'interpréteur PHP de l'environnement XAMPP et le serveur de base MySQL, base nommée arsave. Le client est lancé avec l'adresse de l'API en paramètre, afin de ne pas graver une URL dans plusieurs fichiers. Ces choix de construction n'apparaissent pas dans les cas d'utilisation. Ils permettent de vérifier les scénarios. Les changer pour un hébergement ultérieur ne doit pas changer les fiches du chapitre 3, tant que les routes et le format cryptographique restent les mêmes. C'est le critère d'une architecture stable au sens de l'élaboration (Kruchten, 2004).",
    ])
    _h(doc, add_h, "4.7 Réalisation de l'authentification")
    _ps(doc, add_p, [
        "L'inscription écrit users.email, users.name, users.password_hash, users.role et users.kdf_salt. Le rôle par défaut est l'utilisateur simple. Le sel fait 32 octets. L'empreinte du mot de passe sert uniquement à la vérification de connexion. La connexion retrouve le compte par l'adresse, vérifie l'empreinte, upsert l'appareil sur le couple utilisateur et identifiant d'appareil, crée une session avec l'empreinte du jeton et une expiration, puis renvoie le jeton en clair une seule fois, avec le sel encodé en base64. Le client web range le jeton et le sel dans le stockage du navigateur, dérive la clé et la garde pour les écrans suivants.",
        "Le client web ne peut pas utiliser les API de fichiers du système comme une application de bureau. Cette contrainte, annoncée au chapitre 1, est traitée dans la construction par une couche qui distingue le navigateur et le poste natif pour le stockage de session seulement. Le contrat login reste identique. Un échec d'identifiants n'écrit pas de session et le client montre un message, ce qui réalise l'extension de la fiche 3.8.2. La déconnexion appelle la route prévue et efface les secrets locaux.",
        "Les routes de profil permettent de relire le compte et de changer le nom. Elles exigent le jeton. Elles ne renvoient pas les fichiers d'un autre utilisateur. Le mot de passe oublié crée une ligne password_resets avec l'empreinte d'un jeton à durée limitée. La route de réinitialisation consomme ce jeton, change l'empreinte du mot de passe et régénère le sel. La construction assume alors la limite déjà écrite : les wrapped_key_b64 anciens ne s'ouvrent plus. Aucun écran ne prétend le contraire.",
    ])
    _h(doc, add_h, "4.8 Réalisation du coffre")
    _ps(doc, add_p, [
        "Le service de sauvegarde côté client reçoit les octets et le nom. Il produit le blob, les nonces, la clé enveloppée et l'empreinte, puis le client HTTP envoie un multipart. Les champs suivent l'annexe D et la description d'API du projet : blob, logical_name, mime, checksum_sha256, nonce_b64, wrapped_key_b64, wrap_nonce_b64, et, si l'on ajoute une version, file_id. L'API refuse un jeton absent, un fichier qui n'appartient pas au compte, ou une empreinte qui ne correspond pas aux octets reçus. Elle écrit le blob sous un chemin de stockage, insère file_versions, met à jour files.current_version_id et journalise l'opération.",
        "La liste des fichiers accepte un filtre de statut, actif ou corbeille. La mise en corbeille, la remise et la purge sont trois routes distinctes, afin que le scénario de la fiche 3.8.6 se lise dans l'URL et non dans un paramètre ambigu. La purge efface les blobs du disque avant de retirer les lignes, pour ne pas laisser un fichier chiffré orphelin lorsqu'un compte est supprimé par l'administrateur. Le téléchargement renvoie les octets chiffrés et les en-têtes X-Arsave-Nonce, X-Arsave-Wrapped-Key, X-Arsave-Wrap-Nonce et X-Arsave-Checksum. Le client compare l'empreinte, ouvre l'enveloppe et déchiffre. S'il est dans le navigateur, il déclenche le téléchargement du clair par le mécanisme du navigateur, sans écrire un chemin de disque serveur.",
        "Les miniatures réutilisent ce déchiffrement pour les images dont la taille reste sous la limite retenue dans le client, et seulement si le réglage d'aperçu est actif. Une vidéo ou une archive n'est pas déchiffrée pour fabriquer une image : elle est montrée par son genre, afin que l'utilisateur distingue un film, un son, un document, une archive ou un autre fichier. Ce comportement réalise la demande de reconnaissance visuelle sans élargir le cas d'utilisation à un transcodeur serveur, qui aurait besoin du clair.",
    ])
    _h(doc, add_h, "4.9 Réalisation des écrans web")
    _ps(doc, add_p, [
        "Le client web ouvre sur la connexion ou l'inscription, puis sur une coque à quatre destinations : tableau de bord, coffre, activité, réglages. Le tableau de bord montre des cartes d'indicateurs, un diagramme de répartition par genre et un histogramme des dépôts sur sept jours, plus les dernières opérations avec un renvoi vers l'historique complet. Les cartes sont dimensionnées selon leur contenu, afin qu'un indicateur ne soit pas coupé par une hauteur fixe trop faible. Les erreurs de chargement restent visibles sur l'écran, plutôt que de laisser un tableau vide sans explication.",
        "Le coffre présente une grille, une recherche et des filtres de genre. L'ouverture d'un élément mène au détail, où la miniature ou l'icône de genre est plus grande, et où la restauration est proposée. La corbeille reprend la liste des écartés et les actions de remise ou de purge. L'historique reprend le journal avec des libellés en français pour le dépôt, le téléchargement, la corbeille, la remise et la purge, et avec un statut visuel pour le succès ou l'échec. Les réglages portent le thème sombre ou clair, l'interrupteur des miniatures, le nom du compte, l'accès à la corbeille, l'accès à l'administration si le rôle est admin, et la déconnexion.",
        "Le thème sombre, bleu de nuit, est le thème par défaut. Le thème clair est l'alternative. Il n'y a pas de troisième thème. Le choix est local : il ne produit pas de requête qui modifierait un fichier. Cette remarque relie l'écran au chapitre 3 : le thème n'est pas une classe du domaine. En revanche, le nom du compte passe par la route de profil, parce qu'il est un attribut d'Utilisateur. Distinguer les deux évite d'envoyer le mot de passe ou la clé à chaque changement d'apparence.",
    ])
    _h(doc, add_h, "4.10 Journal, erreurs et administration")
    _ps(doc, add_p, [
        "Chaque action importante écrit une opération : type, statut, message, date, utilisateur, et fichier si l'action en concerne un. Le tableau de bord et l'écran d'activité lisent la même ressource. Un message d'échec côté client, par exemple un réseau coupé avant la réponse, est aussi affiché localement même si le serveur n'a pas pu journaliser. L'utilisateur voit donc deux niveaux, qu'il ne faut pas confondre : le message immédiat de l'écran, et la ligne d'historique lorsque le serveur a bien reçu la tentative.",
        "L'écran d'administration n'est monté que pour le rôle admin. Il affiche les indicateurs globaux et la liste des comptes, permet de basculer le rôle et de supprimer un compte après confirmation. L'API répète les interdits : pas soi-même, pas le dernier administrateur, pas d'accès sans le rôle. La suppression appelle d'abord l'effacement des blobs, puis la suppression des lignes. L'écran ne propose pas de télécharger le coffre d'un autre. Cette absence est la réalisation de la frontière d'acteur, pas un oubli d'interface.",
        "La construction actuelle de l'administration ne crée pas un compte depuis cet écran et ne réinitialise pas un mot de passe à la place de l'utilisateur. L'inscription reste le formulaire public. Ces manques sont ceux déjà nommés comme travaux de transition. Les nommer dans le même chapitre que les routes existantes permet de voir ce qui est fini et ce qui ne l'est pas, sans rouvrir le diagramme de classes : les classes suffisent, les cas d'administration étendue ne sont pas encore des scénarios nominaux.",
    ])
    _h(doc, add_h, "4.11 Correspondance finale avec les scénarios")
    add_table(
        doc,
        ["Exigence du chapitre 1", "Preuve dans la construction"],
        [
            ["Sauvegarde versionnée et corbeille", "Tables files et file_versions, routes trash, restore, purge"],
            ["Chiffrement avant l'envoi", "AES-256-GCM dans le client, blob seul à l'API"],
            ["Clé maître absente du serveur", "Seul kdf_salt est stocké ; la clé reste en mémoire cliente"],
            ["Intégrité du blob", "checksum_sha256 sur le ciphertext, refus si écart"],
            ["Session révocable", "token_hash, expiration, route de déconnexion"],
            ["Admin sans lecture du clair", "Routes /admin sans téléchargement du coffre d'autrui"],
            ["Messages d'échec", "Affichage client et statut failed dans operations"],
            ["Client web", "Mêmes cas, sélecteur de tout type de fichier, thèmes sombre et clair"],
        ],
    )
    add_p(doc, "Tableau 6. Exigences de la revue et preuves de construction", italic=True, center=True, first_line=False)
    _ps(doc, add_p, [
        "Le tableau 6 ferme la traçabilité ouverte au tableau 5. Il ne sert pas à déclarer un produit sans défaut. Il sert à montrer que les quatre exigences transmises par la revue ont un lieu précis dans le code et dans le schéma. Lorsqu'une case ne peut pas être cochée, elle a été écrite comme limite : la réinitialisation du mot de passe ne conserve pas l'accès aux blobs anciens. Cette honnêteté fait partie de la construction au sens de UP. Une itération suivante pourrait ajouter le réenveloppement des clés avant de changer le sel. Elle n'a pas à changer AES, ni les acteurs, ni l'inclusion du chiffrement.",
        "Les essais manuels qui accompagnent cette construction sont décrits à l'annexe F et complétés à l'annexe G. Ils suivent les scénarios nominaux et deux extensions : identifiants faux, fichier ou session refusés. Un essai réussi montre le fichier dans le coffre, une ligne d'historique et un téléchargement du clair. Un essai d'administration montre qu'un utilisateur simple ne voit pas l'écran, et qu'un administrateur ne reçoit pas de contenu déchiffré. Ces essais ne remplacent pas une campagne de tests outillée. Ils vérifient que les diagrammes du chapitre 3 décrivent le système qui s'exécute.",
    ])
    from memoire_plus import plus_4
    plus_4(doc, add_h, add_p, add_table)


def extra_annexes(doc, add_h, add_p, add_table):
    _h(doc, add_h, "Annexe G. Plan d'essais des scénarios")
    _ps(doc, add_p, [
        "Le plan d'essais relie chaque cas du chapitre 3 à un résultat observable sur le client web. Il ne décrit pas un outil particulier. Il décrit les données, l'action et le résultat attendu. Les essais marqués « nominal » suivent les figures 2 et 3 et le chemin oui de la figure 4. Les essais marqués « extension » suivent l'annexe B ou les branches non. Un résultat qui afficherait le clair dans un écran d'administration serait un échec du plan, même si l'action technique réussissait.",
    ])
    add_table(
        doc,
        ["Id", "Cas", "Action", "Résultat attendu"],
        [
            ["E01", "S'inscrire", "Nouvelle adresse et mot de passe", "Compte créé, connexion ensuite possible"],
            ["E02", "S'inscrire", "Adresse déjà prise", "Message d'erreur, pas de second compte"],
            ["E03", "S'authentifier", "Identifiants justes", "Tableau de bord, jeton de session"],
            ["E04", "S'authentifier", "Mot de passe faux", "Message, pas de coffre"],
            ["E05", "Sauvegarder", "Petit fichier texte", "Fichier visible, historique en succès"],
            ["E06", "Sauvegarder", "Image", "Genre image, miniature si aperçu actif"],
            ["E07", "Sauvegarder", "Vidéo ou archive", "Genre affiché, pas de déchiffrement serveur"],
            ["E08", "Sauvegarder", "Sans session", "Refus, pas de version réussie"],
            ["E09", "Restaurer", "Fichier dont on est propriétaire", "Téléchargement du clair"],
            ["E10", "Restaurer", "Empreinte modifiée", "Refus de déchiffrer"],
            ["E11", "Corbeille", "Mettre de côté puis remettre", "Disparaît du coffre puis revient"],
            ["E12", "Corbeille", "Purger", "Disparaît, restauration impossible"],
            ["E13", "Historique", "Après un dépôt", "Ligne datée avec statut"],
            ["E14", "Tableau de bord", "Après plusieurs dépôts", "Indicateurs et graphiques cohérents"],
            ["E15", "Réglages", "Thème clair puis sombre", "Affichage changé, fichiers inchangés"],
            ["E16", "Réglages", "Couper les miniatures", "Plus d'aperçu image, coffre toujours là"],
            ["E17", "Admin", "Compte simple", "Pas d'entrée d'administration"],
            ["E18", "Admin", "Lister les comptes", "Noms et rôles, pas de clair"],
            ["E19", "Admin", "Promouvoir puis rétrograder", "Rôle modifié si ce n'est pas le dernier admin"],
            ["E20", "Admin", "Supprimer un compte de test", "Blobs et lignes retirés"],
            ["E21", "Admin", "Se supprimer soi-même", "Refus"],
            ["E22", "Déconnexion", "Quitter puis rappeler une route", "Session refusée"],
        ],
    )
    add_p(doc, "Tableau G1. Essais des cas nominaux et des extensions", italic=True, center=True, first_line=False)
    _ps(doc, add_p, [
        "L'ordre conseillé est E01, E03, E05, E09, E13, E11, E12, puis E17 avec le second compte, puis E18 à E21 avec le compte administrateur de démonstration. E04 et E08 peuvent être tentés à tout moment. E10 demande de modifier un blob ou une empreinte de façon contrôlée, sur une copie locale, et de vérifier que le client s'arrête. Cet essai ne doit pas être fait sur le seul exemplaire d'un fichier que l'on souhaite conserver. E02 se tente deux fois de suite avec la même adresse.",
        "Le compte admin@arsave.local sert aux essais E18 à E21. Son mot de passe est celui de la graine locale et doit être changé hors d'un poste de développement. Les essais ne valent que si l'API et MySQL sont démarrés et si le client pointe vers cette API. Un échec de connexion au serveur doit produire un message, non un tableau de bord vide sans explication : c'est le critère d'affichage des erreurs retenu au chapitre 4.",
    ])
    _h(doc, add_h, "Annexe H. Colonnes cryptographiques et de cycle de vie")
    _ps(doc, add_p, [
        "Cette annexe détaille les colonnes qui portent soit un secret, soit un paramètre de chiffrement, soit un état du coffre. Elle complète le tableau C1, qui ne donnait que le rôle de chaque table. Aucune colonne ne s'appelle master_key. Si une évolution du schéma ajoutait une telle colonne, elle contredirait le tableau 4 et devrait être refusée en revue de construction.",
    ])
    add_table(
        doc,
        ["Colonne", "Table", "Contenu", "Secret ?"],
        [
            ["password_hash", "users", "Empreinte du mot de passe de connexion", "Dérivé, pas réversible"],
            ["kdf_salt", "users", "Sel PBKDF2 renvoyé au client", "Non, il doit être relu"],
            ["token_hash", "sessions", "SHA-256 du jeton porteur", "Pas le jeton lui-même"],
            ["nonce_b64", "file_versions", "Nonce AES-GCM du fichier", "Non"],
            ["wrap_nonce_b64", "file_versions", "Nonce d'enveloppement de clé", "Non"],
            ["wrapped_key_b64", "file_versions", "Clé de fichier sous la clé maître", "Oui, sans la clé maître"],
            ["checksum_sha256", "file_versions", "Empreinte du ciphertext", "Non"],
            ["storage_path", "file_versions", "Chemin du blob chiffré", "Non"],
            ["status", "files", "active, trashed ou deleted", "Non"],
            ["type / status", "operations", "Action et résultat", "Non"],
        ],
    )
    add_p(doc, "Tableau H1. Colonnes sensibles ou de cycle de vie", italic=True, center=True, first_line=False)
    _ps(doc, add_p, [
        "Les clés étrangères relient ces colonnes au propriétaire. files.user_id, operations.user_id, sessions.user_id et devices.user_id empêchent qu'une liste mélangée les comptes. file_versions.file_id rattache le matériau cryptographique au fichier logique, pas directement à l'utilisateur : l'appartenance se vérifie en rejoignant le fichier. C'est pour cela que l'API ne fait pas confiance à un identifiant de version envoyé seul. Elle vérifie la chaîne jusqu'au compte du jeton. Cette règle d'implémentation réalise l'extension « fichier d'un autre compte » des fiches restaurer, corbeille et purge.",
        "Le statut deleted est prévu par le schéma en plus de trashed. La purge peut retirer la ligne plutôt que de la laisser en deleted, selon le chemin de suppression. Dans les deux lectures, le blob ne doit plus être téléchargeable. L'essai E12 contrôle l'effet visible : le fichier n'est plus restaurable. L'essai ne demande pas à l'utilisateur d'ouvrir le disque du serveur. L'effacement du blob est une responsabilité de l'API, déjà écrite dans le cas de purge et dans la suppression de compte.",
    ])
    _h(doc, add_h, "Annexe I. Forme des messages")
    _ps(doc, add_p, [
        "Les messages suivent le scénario, en JSON pour l'authentification et en multipart pour le dépôt (Bray, 2017 ; Masinter, 2015). L'inscription envoie email, password et name. La connexion envoie email, password, device_uid et device_name. La réponse de connexion envoie token, expires_at, user et kdf_salt_b64. Elle n'envoie pas de clé. Le dépôt envoie le blob et les champs cryptographiques déjà listés. La réponse de téléchargement est le binaire, avec les en-têtes de nonce, de clé enveloppée et d'empreinte. Un client qui chercherait la clé maître dans ces messages ne doit pas la trouver : son absence est un critère d'essai autant qu'un critère de conception.",
        "Les erreurs sont un code HTTP et un corps qui porte un message affichable. Le client ne montre pas une pile technique brute s'il peut la traduire. Il montre toutefois qu'une erreur a eu lieu. Cette règle relie l'annexe aux écrans du chapitre 4 : inscription refusée, connexion refusée, envoi refusé, aperçu impossible, action admin interdite. Le message exact peut évoluer ; le fait qu'il existe, et qu'il ne confirme pas une opération ratée, fait partie du scénario.",
    ])
    _h(doc, add_h, "Annexe J. Glossaire complémentaire")
    add_table(
        doc,
        ["Terme", "Sens dans ce mémoire"],
        [
            ["Inclusion", "Comportement obligatoire d'un cas, ici chiffrer lors d'une sauvegarde"],
            ["Extension", "Chemin d'échec ou variante écrite hors du diagramme nominal"],
            ["Acteur", "Rôle externe : utilisateur ou administrateur"],
            ["Nominal", "Chemin où chaque étape réussit"],
            ["Blob", "Ciphertext écrit sur disque"],
            ["Enveloppe", "Clé de fichier chiffrée par la clé maître"],
            ["Jeton porteur", "Secret de session présenté dans Authorization"],
            ["Sel", "Valeur non secrète qui personnalise PBKDF2"],
            ["Métadonnée", "Nom, type, taille, date : données que le serveur peut lire"],
            ["MVP", "Périmètre construit dans cette itération, limites comprises"],
        ],
    )
    add_p(doc, "Tableau J1. Glossaire complémentaire", italic=True, center=True, first_line=False)
    from memoire_plus import plus_annexes
    plus_annexes(doc, add_h, add_p, add_table)
