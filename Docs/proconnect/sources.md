# Sources — extraits de textes (Kitry, Pro Santé Connect, PGSSI-S)

Recueil des passages utiles des sources citées dans [`sre2.md`](sre2.md). Les textes réglementaires (référentiel PGSSI-S v1.0, projet d'arrêté et référentiel v2) sont recopiés tels qu'extraits des PDF officiels (`pdftotext`, en-têtes et pieds de page retirés) ; les autres sources sont citées brièvement. Collecte : 2026-10-08 et 2026-10-09.

Légende : **lu** = texte ouvert et extrait ici ; **recoupé** = source secondaire ; **non lu** = référencé sans accès au texte.

---

## 1. Référentiel d'identification électronique PGSSI-S, personnes physiques, v1.0 (en vigueur) — *lu*

Source : [ANS, référentiel v1.0, statut « Validé », classification « Public »](https://cdn.hospimedia.fr/documents/220122/7801/Re%CC%81fe%CC%81rentiel_professionnels_de_sante%CC%81.pdf), rendu obligatoire par l'arrêté du 28 mars 2022.

### 1.1 Périmètre (§2.2)

```text
2.2      Services numériques et services numériques partagés

Dans la suite du document, le terme service numérique désigne tout traitement de données de santé entrant dans
le périmètre d’application défini au §1.2, par exemple :
-   Un service de consultation de résultats d’examens de biologie médicale ;
-   Un Dossier Patient Informatisé ;
-   Une application, même interne à une structure, traitant des données de santé à caractère personnel ;
-   Une plateforme de télésanté ;
```

### 1.2 Services « sensibles » (§4.1.2)

```text
4.1.2 Services numériques dits « sensibles »

L’objectif ciblé à terme et décliné par ce référentiel est d’atteindre, pour l’identification électronique des acteurs
personnes physiques intervenant en santé, un niveau de sécurité équivalent au niveau de garantie substantiel des
identités électroniques eIDAS. Dans cette optique, des critères de sélection des services considérés sensibles et un
calendrier de déploiement sont définis ci-dessous.
Les services « sensibles » sont les services numériques en santé au sens du L. 1470-1 du code de la santé publique,
qui traitent des données de santé à caractère personnel au sens du RGPD, et qui appartiennent au moins à l’une
des catégories suivantes :

-   Les services partagés, définis comme dépassant le cadre d’une personne morale et/ou mis en œuvre à l’échelle
    d’un territoire ou au niveau national (ex : dossier médical partagé, plateforme de e-parcours, dossier
    pharmaceutique, etc.) ;
-   Par transitivité, les services numériques qui intègrent des services partagés (ex : dossier patient informatisé,
    système de gestion de laboratoire, système d’information de radiologie, boites de messageries sécurisées de
    santé, etc.) ;
-   Les services proposant un accès web externe aux SI, pour les professionnels d’un établissement (ex : services
    accessibles en mobilité ou télétravail) ou leurs correspondants de ville ;
-   Les services non partagés mais qui intègrent des traitements de données ou des accès de grande échelle, définis
    comme les situations où :
    o Soit le nombre de patients dont les données sont nouvellement référencées dépasse 10 000 par an ;
    o Soit le nombre de professionnels distincts s’identifiant électroniquement dépasse 1 000 par an.
```

### 1.3 Accès à distance (§4.6.3.3)

```text
4.6.3.3 Authentification lors d’un accès à distance

Lorsqu’un professionnel accède à un service numérique depuis un poste connecté à Internet, en télétravail, en
mobilité ou même sur le Wifi « invité » de l’établissement, la connexion est considérée comme un accès à distance.
Ceci est valable même si le poste est distribué et géré par l’établissement et/ou si un VPN a été mis en place.
L’ouverture du VPN par un moyen d’identification électronique à deux facteurs dispense toutefois d’exiger une
```

### 1.4 Pro Santé Connect : identité transmise (§4.2.2)

```text
4.2.2 Identité électronique

Pro Santé Connect fournit au service de santé cible une identité électronique composée des données suivantes :
-   Identifiant national du professionnel de santé ;
-   Nom d'exercice ;
-   Prénom ;
-   Ensemble des données du répertoire sectoriel de référence pour le PS identifié (professions, activités, structures
    d’exercice…).
```

### 1.5 Pro Santé Connect : moyens d'identification (§4.2.3)

```text
4.2.3 Moyens d’identification électronique

Pro Santé Connect supporte à ce jour :
-   Un seul Fournisseur d’Identité : l’ANS ;
-   Deux moyens d’identification électronique :
    o Les carte CPx (CPS RPPS, CPS ADELI, CPF, CPE libérale, CPE structure, ...) ;
    o L’application mobile e-CPS.

D’autres moyens d’identification électroniques pourront compléter cette offre à l’avenir. En particulier, des moyens
d’identification électronique de niveau de garantie eIDAS substantiel ou élevé (tels que ceux présents sous
FranceConnect) sont susceptibles d’être ajoutés à Pro Santé Connect si un lien fiable est réalisé avec l’identité issue
d’un répertoire sectoriel de référence.
L’utilisation de la carte CPS pour s’authentifier au travers de Pro Santé Connect se fait de façon classique par saisie
du code PIN associé à la carte insérée dans un lecteur. Le bénéfice de Pro Santé Connect est toutefois ici de
proposer une interface unique au service numérique pour l’authentification de ses utilisateurs, sans avoir à
implémenter les spécificités de chaque moyen.
Pro Santé Connect est le seul portail permettant d’utiliser l’application e-CPS qui dématérialise la carte CPS en la
transposant sur téléphone mobile. Le professionnel doit avoir au préalable initialisé son e-CPS en suivant les
consignes d’enregistrement données par ailleurs par l’ANS.
Les deux moyens d’identification électroniques, carte CPS et e-CPS, produisent une identification électronique
totalement équivalente du point de vue du service de santé sur lequel la connexion est réalisée. Le professionnel est
libre d’utiliser le moyen qui lui convient le mieux si les circonstances lui autorisent le choix.
```

### 1.6 Homologation : portée (§4.4.1)

```text
4.4.1 Homologation

Dans le cadre de ce référentiel, un fournisseur de service numérique en santé peut homologuer, selon les modalités
exposées ci-dessous, tout moyen d’identification électronique qui respecte strictement les exigences décrites dans
ce chapitre, en particulier celles définies par règlement d’exécution européen pour le niveau de garantie substantiel.
```

```text
Les moyens d’identification électronique ainsi homologués peuvent par exemple être utilisés pour assurer
l’authentification au sein d’un établissement de santé. Toutefois, aucun autre fournisseur de service n’est tenu
d’accepter ces dispositifs pour l’identification électronique, chacun devant effectuer une nouvelle homologation en
prenant en compte son propre contexte et les risques inhérents à son activité s’il souhaite accepter ces dispositifs.
L’ANS publie sur son site internet un guide décrivant les principes à respecter dans le cadre de l’homologation. Les
modalités d'envoi des documents d’homologation seront précisées dans l'espace de publication de la PGSSI-S.
```

### 1.7 Moyens « de transition » : principe, niveau eIDAS faible (§4.6.1)

```text
4.6.1 Généralités

Avant de parvenir à la généralisation de l’identification électronique par un moyen d’identification électronique de
niveau de garantie eIDAS substantiel, la sécurité des accès aux services numériques traitant de données de santé
à caractère personnel doit être progressivement renforcée. Dans cet objectif, ce référentiel définit des moyens
d’identification électronique dits « de transition » qui apportent un niveau de sécurité considéré comme minimal étant
donné la nature des informations à protéger et l’état de l’art en la matière. Les exigences de sécurité associées à
ces moyens d’identification électronique sont exposées ci-dessous.
Il n’est pas demandé que ces moyens d’identification électronique aient obtenu une certification ou une attestation
de conformité à un quelconque niveau de garantie eIDAS. Le principe est cependant de viser une conformité au
niveau de garantie eIDAS faible (exigences définies dans [eIDAS-MIE]), complété par plusieurs exigences
complémentaires détaillées ci-après. Le fournisseur de service peut délivrer et gérer lui-même les moyens
d’identification électronique de son service ou s’appuyer sur des solutions mutualisées.
Le fournisseur d’un service numérique de santé est responsable des mesures de sécurité mises en œuvre pour la
protection des données de santé à caractère personnel. Ainsi, ce référentiel encourage l’adoption d’un moyen
d’identification électronique de niveau substantiel à brève échéance. Chaque fournisseur doit prendre en compte
dans sa décision, par exemple via une analyse de risque, les spécificités de son service, le type et la volumétrie des
données traitées.

4.6.2 Identité électronique
```

### 1.8 Exigences (synthèse du chapitre 7 : n°1, 3 à 15, 21, 22, 25 à 27, 30 à 32)

```text
[EXI 01] Les identifiants nationaux à utiliser pour l’identification des acteurs personnes physiques intervenant en
santé sont :
-   Soit l’identifiant RPPS, à utiliser en priorité s’il existe pour la personne à identifier ;
-   Soit l’identifiant ADELI, toléré de façon transitoire jusqu’à son remplacement définitif par l’identifiant RPPS pour
    les professions encore enregistrées dans ADELI.

[EXI 03] Les moyens d’identification électronique autorisés pour accéder aux services sensibles doivent être limités :
- Aux moyens d’identification électronique disponibles sous Pro Santé Connect ;
- À la carte CPx ;
- À des moyens d’identification électronique homologués pour cet usage ;
- À des moyens d’identification électronique certifiés de niveau de garantie eIDAS substantiel ou élevé, et associés
    à un identifiant conforme aux exigences du référentiel.
Les moyens d’identification électronique de transition, tels que définis dans le présent référentiel, sont néanmoins
autorisés jusqu’au 31 décembre 2025 au plus tard, sous réserve que les risques résiduels associés à leur utilisation
soient considérés comme acceptables par le responsable du service numérique.

[EXI 04] Les services sensibles devront a minima avoir implémenté l’identification électronique par Pro Santé
Connect au 1er janvier 2023 au plus tard.

7.3      Pro Santé Connect et e-CPS

[EXI 05] Les services sensibles ne doivent accepter, parmi les moyens d’identification électronique fournis par Pro
Santé Connect, que ceux de niveau substantiel ou supérieur dès lors que ce niveau est précisé.

7.4      Dispositifs de la famille CPx

[EXI 06] L’ensemble des cartes de la famille CPx (CPS, CPF, CPE/CDE et CPA/CDA) peuvent être utilisées pour
l’identification électronique de leur porteur lors de l’accès à un service numérique en santé. Pour le cas d’une carte
non nominative, il revient au fournisseur de service de définir s’il accepte ou non ce type d’identification.

[EXI 07] La puce sans contact d’une carte CPx ne peut être utilisée pour réaliser une identification électronique que
dans le cadre d’un moyen d’identification électronique homologué ou de transition.

7.5      Moyens d’identification électronique homologués

[EXI 08] L’homologation d’un moyen d’identification électronique des personnes physiques accédant à un service
numérique sensible est à la charge de l’entité responsable de ce service. Lorsqu’une structure délivre le MIE à ses
propres collaborateurs (elle joue alors le rôle de fournisseur d’identité), elle réalise cette homologation une fois pour
le compte de l’ensemble des services numériques sensibles dont elle est responsable.

[EXI 09] L’homologation d’un moyen d’identification électronique doit garantir que :
-   Le niveau de sécurité atteint avec l’utilisation de ce moyen est conforme aux objectifs de sécurité issus de
    l’analyse de risque des services numériques en santé pour lesquels il est utilisé ;
-   Le MIE est conforme aux exigences portant sur un moyen d’identification électronique de niveau de garantie
    substantiel ou élevé du règlement eIDAS (cf. [eIDAS-MIE]).

[EXI 10] L’homologation du moyen d’identification électronique doit être réalisée par le responsable d’un service
numérique sensible une fois tous les 4 ans et au maximum 2 ans après tout changement du référentiel européen
d’exigences pour les identités électroniques, en s’appuyant sur la démarche décrite par l’ANSSI (cf.
[HOMOLOGATION]). Cette homologation doit s’appuyer sur :
-   Un audit de conformité au référentiel européen d’exigences pour les identités électroniques de niveau substantiel
    et au exigences concernant un moyen d’identification électronique homologué dans le présent référentiel ;
-   Une analyse de risque du système d’information de gestion du moyen d’identification électronique ;
-   Une évaluation technique de la sécurité du dispositif d’authentification.
La décision d’homologation ainsi que les pièces listées ci-dessus sont à communiquer à l’ANS.

[EXI 11] L’identifiant de personne physique fourni par un moyen d’identification électronique homologué doit être :
-   L’identifiant issu d’un répertoire sectoriel de référence (RPPS pour la quasi-totalité des cas) lorsque la personne
    est éligible à l’enregistrement dans ce type de répertoire ;
-   A défaut, un identifiant privé à l’état de l’art (absence de collisions, autorité d’affectation définie, etc.).

[EXI 12] Les attributs d’identité fournis par un moyen d’identification électronique homologué doivent au minimum
comprendre :
-   Le nom d'exercice ;
-   Le prénom d’exercice.

[EXI 13] Le dispositif d’authentification délivré comme moyen d’identification électronique homologué doit posséder,
par conception, un niveau de sécurité compatible avec le niveau de confiance global accordé à l’identité électronique
transmise. Le référentiel européen d’exigences pour les identités électroniques de niveau de garantie eIDAS
substantiel indique en particulier :
-   Le moyen d'identification électronique utilise au moins deux facteurs d'authentification de différentes catégories ;
-   Le moyen d'identification électronique est conçu de sorte qu'on puisse présumer qu'il est utilisé uniquement sous
    le contrôle de la personne à laquelle il appartient ou en sa possession ;
-   La diffusion de données d'identification personnelle est précédée d’une vérification fiable du moyen
    d'identification électronique et de sa validité par une authentification dynamique ;
-   Le mécanisme d'authentification met en œuvre des contrôles de sécurité pour la vérification du moyen
    d'identification électronique, de sorte qu'il soit hautement improbable que des activités telles que les tentatives
    de décryptage, l'écoute, l'attaque par rejeu ou la manipulation d'une communication par un attaquant ayant un
    potentiel d'attaque modéré puissent nuire au mécanisme d'authentification.

[EXI 14] Un fournisseur de service peut autoriser une authentification par un seul des deux facteurs du moyen
d’identification électronique homologué aux conditions cumulatives suivantes :
-   Que les cas d’usages soient formellement identifiés par le fournisseur de service ;
-   Qu’une analyse de risque identifie les risques induits par cette autorisation et garantisse que ceux-ci sont
    acceptables dans le contexte des cas d’usage ;
-   Qu’une authentification nominale avec les deux facteurs d’authentification ait été réalisée précédemment dans
    le délai minimal jugé compatible avec les contraintes du cas d’usage ;
-   Que le facteur utilisé soit l’un des deux facteurs du moyen d’identification électronique utilisé précédemment.

7.6      Moyens d’identification                                     électronique                     certifiés              de        niveau             eIDAS
         substantiel ou élevé

[EXI 15] L’identification électronique pour accéder à un service numérique en santé est autorisée avec un moyen
d’identification électronique certifié conforme au règlement d’exécution n°2015/1502 pour le niveau de garantie
eIDAS substantiel ou élevé.

[EXI 21] Les processus de gestion d’un moyen d’identification électronique de transition doivent respecter les
exigences suivantes :
- Les informations obtenues par la vérification d’identité initiale ne peuvent être modifiées qu’après une nouvelle
    vérification au moins aussi fiable ;
- Un renouvellement régulier du moyen d’identification électronique doit être prévu afin de s’assurer de l’identité
    du détenteur du moyen et du maintien à l’état de l’art des garanties de sécurité (par exemple concernant la
    longueur d’un mot de passe ou d’une clé cryptographique) ;
- Le détenteur et le gestionnaire du moyen d’identification électronique doivent pouvoir à tout moment révoquer
    ce moyen, afin d’empêcher son éventuelle utilisation frauduleuse (par exemple après la compromission de ce
    moyen).

[EXI 22] L’authentification lors d’un accès à distance avec un moyen d’identification électronique de transition doit
impérativement reposer sur deux facteurs de types différents parmi les trois suivants :
- Connaissance : par exemple d’un mot de passe ;
- Possession : par exemple d’un appareil fixe ou mobile sur lequel s’effectue l’enregistrement ;
- Biométrie : par exemple une empreinte digitale stockée et vérifiée sur un matériel en possession du
    professionnel.

[EXI 25] Un mot de passe seul peut être utilisé comme moyen d’identification électronique de transition pour un accès
local à un service numérique en santé, à condition d’appliquer les exigences suivantes :
- Des mesures de restriction d’accès par au moins l’une des méthodes suivantes :
    ○ Une temporisation d'accès au compte après plusieurs échecs, dont la durée augmente exponentiellement dans
le temps ; il est recommandé que cette durée soit supérieure à 1 minute après 5 tentatives échouées, et permette
de réaliser au maximum 25 tentatives infructueuses par 24 heures ;
    ○ Un mécanisme permettant de se prémunir contre les soumissions automatisées et intensives de tentatives (p.
ex. : « captcha ») ;
    ○ Un blocage du compte après un nombre d'authentifications échouées consécutives au plus égal à 10 ;
-   Des critères de construction du mot de passe :
    ○ La complexité du mot de passe doit permettre d’assurer, au minimum, une entropie de 50 bits (cf. [ENTROPIE]),
par exemple :
       ○ le mot de passe comporte 8 caractères, avec 3 des 4 catégories de caractères (majuscules, minuscules,
chiffres et caractères spéciaux) ;
       ○ la phrases de passe, fondée sur des mots de la langue française, est composée d’au minimum 5 mots ;
       ○ le mot de passe est composé d'au minimum 15 chiffres ;
   ○ Le respect de ces contraintes est vérifié automatiquement à la définition et à chaque renouvellement du mot de
passe ;
-   Des mesures de sécurité adaptées au contexte et relatives aux modalités de gestion du mot de passe et au
    mécanisme d’authentification.

[EXI 26] Après une authentification avec un moyen d’identification électronique de transition, une déconnexion
automatique doit être mise en place pour forcer une nouvelle identification électronique après un certain délai
d’inactivité.
Ce délai est à définir par le responsable du service numérique en santé selon les risques et les contraintes propres
au service.

7.8      Feuille de route pour la gestion des identités et des accès

[EXI 27] Afin de garantir un niveau de fiabilité à l’état de l’art des identités, au 1/01/2024 au plus tard, les structures
responsables d’au moins un service sensible, doivent avoir mis en place un répertoire d’identité local dans les
conditions suivantes :
-   Le répertoire d’identité local doit concerner a minima l’ensemble des professionnels de santé de la structure ;
-   Les processus d’arrivée et de départ de personnel sont formalisés et appliqués dans la gestion des ressources
    humaines de la structure ;
-   Le répertoire d’identité local est synchronisé régulièrement avec le référentiel des ressources humaines ;
-   Lorsqu’une personne est enregistrée dans un répertoire sectoriel de référence, son identifiant national est
    associé à son identité dans le répertoire local et vérifié au moins tous les 2 ans.

[EXI 30] Les fournisseurs de services numériques en santé doivent produire un engagement de sécurisation de
l’identification électronique des personnes physiques à leurs services numériques sensibles, dès la date d’entrée en
vigueur du présent référentiel.

[EXI 31] L’engagement de sécurisation de l’identification électronique doit suivre les modèles proposés par l’ANS et
être signé par un responsable légal du fournisseur des services sensibles concernés, ou, à défaut, par un délégataire
dument habilité.

[EXI 32] L’engagement de sécurisation de l’identification électronique doit être renouvelé à chaque modification des
modalités d’identification électronique d’un service numérique en santé sensible, et a minima annuellement.

Annexe 1 : Abréviations

     Sigle / Acronyme                                                                        Signification
ADELI                                  Automatisation Des Listes

ANS                                    Agence du Numérique en Santé

ANSSI                                  Agence Nationale de Sécurité des Systèmes d’Information

CPE                                    Carte de Personnel d’Etablissement (carte de la famille CPS)

CPS                                    Carte de Professionnel de Santé

CSPN                                   Certification de Sécurité de Premier Niveau

DMP                                    Dossier Médical Partagé

FIDO                                   Fast Identity Online

FINESS                                 Fichier National des Etablissements Sanitaires et Sociaux

GHT                                    Groupement Hospitalier de Territoire

MOS                                    Modèle des objets de santé

MSS                                    Messagerie Sécurisée de Santé

OID                                    « Object Identifier » : identifiant d’objet

PGSSI-S                                Politique Générale de Sécurité des Systèmes d’Information de Santé

RH                                     Ressources Humaines

RPPS                                   Répertoire Partagé des Professionnels de Santé

SI                                     Système d’Information

SIRENE                                 Système Informatique pour le Répertoire des Entreprises et des Etablissements

SIREN                                  Système d’Identification du Répertoire des Entreprises

SIRET                                  Système Informatique pour le Répertoire des Entreprises sur le Territoire

SSO                                    Single Sign-On

TOTP                                   Time-based One Time Password ([RFC 6238])

UE                                     Union Européenne
```

---

## 2. Projet d'arrêté modifiant l'arrêté du 28 mars 2022 et référentiel v2 (non adopté) — *lu*

Source : [Commission européenne, TRIS, notification 2026/0498/FR, texte notifié](https://technical-regulation-information-system.ec.europa.eu/en/notification/28741/text/D/FR). Fiche de la notification ([lien](https://technical-regulation-information-system.ec.europa.eu/en/notification/28741)) : notifiée le **14 septembre 2026**, fin du statu quo le **15 décembre 2026** ; résumé : « Legacy electronic identification methods authorized until 31 December 2028 with two-factor authentication » (vise les usagers, cf. §2.2 ci-dessous).

### 2.1 Projet d'arrêté (visas et articles)

```text
RÉPUBLIQUE FRANÇAISE

    Ministère de la santé, des familles, de
 l’autonomie et des personnes handicapées

Arrêté du XXX modifiant l’arrêté du 28 mars 2022 portant approbation du référentiel
relatif à l'identification électronique des acteurs des secteurs sanitaire, médico-social et
social, personnes physiques et morales, et à l'identification électronique des usagers des
                                 services numériques en santé
                                              NOR :
         Vu le règlement (UE) 910/2014 du Parlement européen et du Conseil du 23 mars 2014
sur l'identification électronique et les services de confiance pour les transactions électroniques
au sein du marché intérieur et abrogeant la directive 1999/93/CE (règlement eIDAS) ;
Vu le règlement d'exécution (UE) 2015/1502 de la Commission du 8 septembre 2015 fixant
les spécifications techniques et procédures minimales relatives aux niveaux de garantie des
moyens d'identification électronique ;
        Vu la directive 2015/1535 du Parlement européen et du Conseil du 9 septembre 2015
prévoyant une procédure d'information dans le domaine des réglementations techniques et des
règles relatives aux services de la société de l'information, et notamment la notification n°
2021/426/F adressée à la Commission européenne le 6 juillet 2021 ;
         Vu le règlement (UE) 2016/679 du Parlement européen et du Conseil du 27 avril 2016
relatif à la protection des personnes physiques à l'égard du traitement des données à caractère
personnel et à la libre circulation de ces données, et abrogeant la directive 95/46/CE ;
       Vu le code de la santé publique, notamment ses articles L. 1470-2 et L. 1470-5 ;
       Vu la loi n° 78-17 du 6 janvier 1978 modifiée relative à l'informatique, aux fichiers et
aux libertés ;
       Vu l’arrêté du 28 mars 2022 portant approbation du référentiel relatif à l'identification
électronique des acteurs des secteurs sanitaire, médico-social et social, personnes physiques et
morales, et à l'identification électronique des usagers des services numériques en santé
        Vu l’arrêté du 9 janvier 2025 portant approbation de l'avenant modifiant la convention
constitutive du groupement d'intérêt public « Agence du numérique en santé », précisant les
missions de l'ANS, complétant les modalités de sa gouvernance et portant modification de son
siège social

                                             Arrête :
                                           Article 1er
L’annexe à l’arrêté du 28 mars 2022 susvisé est remplacée par l’annexe au présent arrêté.
                                           Article 2
Le présent arrêté entre en vigueur à compter de sa publication.
                                           Article 3
Le présent arrêté sera publié au Journal officiel de la République française.
Fait le XXX
Pour la ministre et par délégation :
```

### 2.2 Annexe « personnes physiques » v2b.0.k — historique

```text
Acteurs des secteurs sanitaire,
médico-social et social [personnes
physiques]
                                                       Version :
Historique du document

 Version   Date de publication                      Motif et nature de la modification
1.0        Avril 2022            Version initiale

2b.0.g     25/02/2026            Version après concertation

2b.0.h     16/04/2026            Version post COMOP ISS (suppression du paragraphe « incident
                                 mineur »)

2.b.0.i    29/06/2026            Version avec l’ajout du eSSO dans la liste des réserves

2.b.0.j    16/07/2026            Version qui prend en compte les remarques de la CNIL (nom de
                                 famille)

2.b.0.k    17/08/2026            Version qui prend en compte les retours de la CNAM (cf ajout du
                                 sexe dans la définition des données d’identité) et des retours de la
                                 CNIL (cf acceptation du risque résiduel concernant les réserves sur la
                                 conformité au RIE PP).
```

Pour comparaison, l'annexe « usagers » (patients) v2.0.h conserve les moyens de transition : « au plus tard jusqu’au 31/12/2028 ». Cette date ne concerne pas les professionnels.


### EXI RIE-PS 02 — Moyens autorisés

```text
EXI RIE-PS 02

Le Fournisseur de Service DOIT proposer des Moyens d’Identification électronique aux Utilisateurs
parmi :
    1- Pro Santé Connect, dans le cadre des Schémas d’Identification électronique proposés, avec :
           a. L’application mobile d’Identification sectorielle de Pro Santé Connect ;
           b. Les cartes d’Identification sectorielles fournies par l’ANS compatibles avec Pro Santé
              Connect ;
           c. Les autres Moyens d’Identification électronique compatibles de Pro Santé Connect ;

    2- Les Moyens d’Identification électroniques proposés par les Fournisseurs d’identité de Pro
       Santé Connect, préalablement habilités par l’ANS ;

    3- Les Moyens d’Identification électronique reposant sur un Schéma d’Identification électronique
       ayant fait l’objet d’une attestation de conformité aux exigences du présent référentiel par le
       Fournisseur d’identité, au plus tard le 31/12/2026 pour les services en production à cette
       date ;

    4- Les cartes de la famille CPx délivrées par l’ANS pour l’authentification directe du porteur (hors
       Pro Santé Connect), pour les Fournisseurs de Services historiques spécifiquement autorisés
       par l’ANS pour cet usage.
Remarques :
   1- L’application mobile d’Identification sectorielle de Pro Santé Connect est l’application « e-
      CPS » (le nom de l’application pourra évoluer).
      Les cartes d’Identification sectorielles fournies par l’ANS compatibles avec Pro Santé Connect
      pour l’accès aux Services numériques en santé sont les cartes professionnels de santé,
      reposant sur l’enregistrement dans le RPPS du porteur de la carte.
      La liste des autres MIE compatibles avec Pro Santé Connect, est mise à jour régulièrement
      sur le site de l’ANS. Il est à noter que l’usage local, hors Pro Santé Connect, de ces mêmes
      MIE nécessite une attestation de conformité, telle que prévue au point 3-.

   2- Les Fournisseurs d’identités de Pro Santé Connect doivent être habilités par l’ANS. Il peut
      s’agir par exemple :
           De Fournisseurs d’identité conformes au niveau de garantie substantiel ou élevé du
               règlement eIDAS (par exemple les portefeuilles d’identité numérique Européens :
               EUDI Wallet) ;
           De certains établissements habilités par l’ANS comme Fournisseurs d’identité de Pro
               Santé Connect, sur la base d’une vérification de conformité aux exigences dédiées du
               référentiel Pro Santé Connect. Ces établissements doivent s’appuyer sur une solution
               logicielle de gestion des identités et des accès (IAM) ayant elle-même fait l’objet d’une
               habilitation technique en regard du même référentiel.

   3- Les modalités d’attestation de conformité sont décrites dans la suite de ce document. Un
      guide est proposé par l’ANS pour accompagner les structures concernées dans leur
      démarche.
      Il peut s’agir par exemple des MIE compatibles ou non avec PSC mis à disposition des PS au
      sein d’un ES pour accéder au SI local de l’ES hors PSC.
      Au plus tard le 31/12/2026 : une attestation de conformité aux exigences du présent
      référentiel doit être établie par le Fournisseur d’identité délivrant les MIE, avec des réserves
      éventuelles sur certaines exigences, qui devront être levées au plus tard le 31/12/2028.

   4- L’authentification directe par carte CPS ou par carte de la famille CPx, hors Pro Santé
      Connect, concerne essentiellement les téléservices nationaux de l’Assurance maladie et
      quelques Services publics nationaux historiques. Ces Services ont vocation à basculer
      progressivement sur Pro Santé Connect.
      L’utilisation de la carte CPS ou d’une carte CPx hors Pro Santé Connect pour l’accès à d’autre
      Services numériques doit faire l’objet d’une attestation de conformité du Schéma
      d’Identification électronique utilisé au présent référentiel (par exemple en cas d’enrôlement sur
      un Répertoire d’identité local d’une structure de santé). Les cartes CPx (autres que CPS) ne
      reposant pas sur un enregistrement dans le Répertoire sectoriel de référence (RPPS) ne
      devraient pas être utilisées pour l’accès à des Services numériques en santé.
Pro Santé Connect

Pro Santé Connect est le Fédérateur de Fournisseurs d’identité mis à disposition par l’ANS permettant
l’Identification électronique des acteurs personnes physiques intervenant dans le système sanitaire,
social et médico-social.
```

### EXI RIE-PS 03 — Pro Santé Connect obligatoire

```text
EXI RIE-PS 03

Le Fournisseur de Service DOIT permettre l’utilisation de Pro Santé Connect.

Un Service numérique doit toujours permettre l’utilisation de Pro Santé Connect (par exemple les
logiciels métier des professionnels), même si d’autres Moyens d’Identification électronique peuvent
être utilisés, sous réserve de conformité aux autres exigences du présent référentiel (par exemple au
sein du système d’information d’un établissement disposant d’une solution locale de gestion des
identités et des accès offrant une fonctionnalité de « single sign on » avec ses propres Moyen
d’Identification électronique).

Lorsque le Service numérique utilise Pro Santé Connect comme solution nominale d’Identification
électronique, , selon la criticité et les engagements de disponibilité du Service, le Fournisseur de
Service doit prévoir une alternative en cas d’indisponibilité de Pro Santé Connect (exemple : coupure
internet).

Moyens d’Identification électronique autres que ProSantéConnect

Généralités

En complément de Pro Santé Connect, ou en alternative locale (par exemple au sein d’une structure
de santé qui voudrait disposer d’une solution autonome), un Fournisseur de Service peut s’appuyer
sur d’autres Fournisseurs d’identité, ou se constituer lui-même Fournisseur d’identité, afin de
s’adosser à un Répertoire d’identité local, ou de permettre l’utilisation d’autres Moyens
d’Identification électronique.

Le ou les Schémas d’Identification électronique mis en œuvre doivent alors être conformes aux
exigences du présent référentiel et faire l’objet d’une attestation de conformité.

Le Fournisseur d’identité peut éventuellement être habilité comme Fournisseur d’identité de Pro
Santé Connect, sous réserve de satisfaire à des exigences spécifiques, vérifiées lors de l’habilitation
par l’ANS en regard du Référentiel Pro Santé Connect (cf. [PSC]).

Données d’identité
```

### EXI RIE-PS 07 — Enrôlement

```text
EXI RIE-PS 07
Le Fournisseur d’identité DOIT implémenter un processus d’enrôlement des Utilisateurs répondant
aux exigences suivantes :
-        L’enrôlement de l’utilisateur doit se baser sur une vérification de l’identité du professionnel
concerné, par l’une des méthodes suivantes :
○ Par une Identification électronique via Pro Santé Connect ou un Moyen d’Identification
électronique certifié au niveau de garantie substantiel ou élevé du règlement eIDAS ;
○ Par une vérification d’identité en face-à-face physique (ou à distance par un Service en ligne certifié
équivalent au face-à-face physique) avec présentation d’un document d’identité à haut niveau de
confiance (ex : passeport ou carte d’identité) ;
-        Lorsqu’une adresse électronique ou un numéro de téléphone mobile sont enregistrés, pour le
mécanisme d’authentification ou pour la récupération des Moyens d’Identification électronique, une
vérification de ces coordonnées doit être réalisée par l’envoi d’un code ou d’un lien d’activation ;
-        L’enrôlement doit intégrer la vérification de l’existence de la personne dans le Répertoire
sectoriel de référence.

Processus de gestion du Moyen d’Identification électronique

Les processus de gestion du Moyen d’Identification électronique doivent couvrir le cycle de vie
complet de celui-ci et garantir que l’identité électronique établie à l’enrôlement est protégée dans le
temps :
```

### EXI RIE-PS 08 — Gestion des moyens

```text
EXI RIE-PS 08

Le Fournisseur d’identité DOIT implémenter des processus de gestion des Moyens d’Identification
électronique respectant les exigences suivantes :
-       La délivrance d’un Moyen d’Identification électronique doit permettre de garantir qu'il est
exclusivement remis en la possession de l’Utilisateur attendu ;
-       Un renouvellement régulier de l’enrôlement d’un Moyen d’Identification électronique doit
être prévu, a minima tous les 3 ans, et maintenir à l’état de l'art la vérification de l’identité et la
robustesse de l’authentification ;
-       L’Utilisateur et le Fournisseur d’identité doivent pouvoir à tout moment révoquer ce Moyen,
afin d’empêcher son éventuelle utilisation frauduleuse (par exemple après la compromission de ce
Moyen) ;
-       Les informations obtenues par la vérification d’identité initiale ne peuvent être modifiées
qu’après une nouvelle vérification au moins aussi fiable ;
-       Des notifications explicites sont envoyées à l’Utilisateur au moment de la délivrance, du
renouvellement et de toute modification du Moyen d’Identification électronique.
La délivrance du Moyen d’Identification électronique peut par exemple être réalisée par l’une des
   méthodes ci-dessous :
        - En main propre, avec une vérification d’une pièce d’identité en face à face ;
        - En ligne, avec un mécanisme garantissant que seul le professionnel enregistré peut
           activer le MIE (par exemple avec l’application mobile de Pro Santé Connect, un autre
           Moyen d’Identification électronique de niveau eIDAS substantiel ou élevé).

L’identité du demandeur d’une révocation doit être vérifiée afin d’éviter des demandes abusives,
pour tenter un renouvellement frauduleux ou pour nuire à un professionnel. Elle peut par exemple
devoir être réalisée auprès d’un opérateur d’enregistrement, d’un opérateur de sécurité physique ou
bien en ligne après vérification d’informations confidentielles du porteur.

Moyens d’Identification électronique

La sécurité du dispositif et du mécanisme d’authentification garantit qu’une Identification
électronique effectuée sur un Service numérique est bien réalisée par l’Utilisateur légitime de ce
Moyen d’Identification électronique.
```

### EXI RIE-PS 09 — Exigences du moyen (deux facteurs)

```text
EXI RIE-PS 09
Le Fournisseur d’identité DOIT respecter les exigences suivantes :
-        Le Moyen d'Identification électronique utilise au moins deux facteurs d'authentification de
différentes catégories ;
-        Le Moyen d'Identification électronique est conçu de sorte qu'on puisse présumer qu'il est
utilisé uniquement sous le contrôle de la personne à laquelle il appartient ou en sa possession ;
-        Le mécanisme d'authentification met en œuvre des mesures de sécurité protégeant
l’authenticité et la confidentialité des données échangées.

Les deux facteurs d’authentification doivent appartenir à l’une des catégories suivantes :
       -   Connaissance : par exemple d’un mot de passe ou un code PIN ;
       -   Possession : par exemple d’un badge, d’une carte, d’une clé USB ou d’un terminal fixe ou
           mobile ;
       -   Biométrie : par exemple une empreinte digitale stockée et vérifiée sur un matériel en
           possession du professionnel.

La sécurité du mécanisme d’authentification doit empêcher un fraudeur opportuniste ou non outillé,
ou bien une attaque classique par phishing par exemple, de parvenir à usurper une identité. Ainsi, de
façon générale, il est fortement recommandé :
       -   Que l’authentification repose sur un Moyen d’Identification électronique matériel (carte à
           puce, clé FIDO, application TOTP sur téléphone, etc.) ou sur des éléments biométriques ;
       -   Que l’authentification soit dynamique, c’est-à-dire qu’elle implique des échanges de
           données différentes à chaque authentification (empêchant le rejeu), par exemple reposant
           sur des mécanismes cryptographiques, des OTP (One Time Password ou code à usage
           unique), etc. ;
       -   Que des notifications de connexion soient communiquées à l’utilisateur (envoyées par
           email ou rendues disponibles sur son compte par exemple).
Certains cas d’usage peuvent présenter des contraintes spécifiques (session nomade : changement
fréquent de poste de travail) pour lesquelles l’authentification systématique à deux facteurs est
difficilement réalisable ou acceptable en pratique.
```

### EXI RIE-PS 10 — Authentification à un seul facteur

```text
EXI RIE-PS 10
Le Fournisseur de Service qui autorise une authentification par un seul des deux facteurs DOIT :
-       Identifier formellement les cas d’usages concernés ;
-       Identifier les risques induits par cette autorisation et garantir que ces risques sont
acceptables dans le contexte des cas d’usage ;
-       Exiger qu’une authentification nominale avec les deux facteurs d’authentification ait été
réalisée précédemment et dans un délai maximal jugé compatible avec les contraintes du cas
d’usage ;
-       Imposer que le facteur d’authentification employé soit l’un des deux facteurs du Moyen
d’Identification électronique utilisé précédemment.

Par exemple, un utilisateur ouvre initialement une session utilisant un badge sans contact et en
saisissant un mot de passe. Tant que la session est ouverte et qu’une durée maximale
d’authentification par un seul facteur n’a pas été dépassée, il peut s’authentifier sur différents
Services en utilisant seulement son badge sans contact. A l’expiration de la durée autorisée, il doit de
nouveau saisir le mot de passe.

D’une manière générale, la durée maximale d’authentification par un seul facteur ne devrait pas
dépasser 4 heures.

Exigences transverses

Gestion des accès et des habilitations

La mise en place d’une fonctionnalité de Single Sign On (SSO) permet d’améliorer l’expérience
utilisateur et d’augmenter le niveau de sécurité de l’Identification électronique. Son déploiement est
imposé seulement aux organisations de taille importante.
```

### EXI RIE-PS 11 et 12 — SSO

```text
Gestion des accès et des habilitations

La mise en place d’une fonctionnalité de Single Sign On (SSO) permet d’améliorer l’expérience
utilisateur et d’augmenter le niveau de sécurité de l’Identification électronique. Son déploiement est
imposé seulement aux organisations de taille importante.

                                             EXI RIE-PS 11

Un Fournisseur d’identité DOIT mettre en œuvre une fonctionnalité de SSO (Single Sign-On) lorsqu’il
fournit des Moyens d’Identification électronique sur plus d’un Service numérique en santé à plus
5.000 professionnels.

Pour favoriser l’interopérabilité des systèmes mis en œuvre, la compatibilité d’une fonctionnalité SSO
avec le protocole OpenID Connect est indispensable.
                                              EXI RIE-PS 12

Un Fournisseur d’identité DOIT rendre compatible la fonctionnalité de SSO avec le protocole OpenID
Connect lorsqu’elle est mise en œuvre.

Le déploiement d’une solution d’IAM (Identity Access Management) peut être envisagé afin
d’automatiser la gestion des identités et des accès des professionnels, en particulier au sein du
système d’information d’une organisation de taille importante. Ces solutions intègrent généralement
des fonctionnalités de SSO.
```

### EXI RIE-PS 13 — Sessions

```text
EXI RIE-PS 13
Le Fournisseur d’identité DOIT définir, en prenant en compte le contexte de ses Utilisateurs et des
Services raccordés, les mécanismes et la périodicité des demandes de réauthentification des
Utilisateurs.

D’une manière générale, la durée de session d’un Fournisseur d’identité ne devrait pas excéder 4
heures et la durée maximale d’inactivité avant déconnexion ne devrait pas excéder 30 minutes. Selon
le contexte des Utilisateurs et des Services raccordés, Le Fournisseur d’identité doit également définir
une politique de gestion des sessions en cas de changement de Moyen d’Identification électronique,
d’adresse IP ou de navigateur.

Le Fournisseur de Service gère la session applicative de l’utilisateur sur son Service, indépendante de
celle du Fournisseur d’identité. Il doit protéger les ressources applicatives, tout en synchronisant, tant
que possible, la durée de vie de sa session applicative avec celle du Fournisseur d’identité.

Afin d’éviter qu’une session applicative reste ouverte alors que l’utilisateur est déconnecté du
Fournisseur d’identité, la durée de vie d’une session applicative ne doit pas dépasser celle de la
session du Fournisseur d’identité. Lorsque le Fournisseur de Service estime que la durée de vie de la
session du Fournisseur d’identité induit un risque important sur son Service, il peut prévoir une durée
de vie et une demande de réauthentification de l’utilisateur dans un délai plus restrictif.
```

### Continuité d'activité et EXI RIE-PS 16 — Moyens de secours

```text
Continuité d’activité

Des incidents majeurs, comme une coupure réseau persistante ou une défaillance matérielle ou
logicielle, peuvent rendre indisponibles l’ensemble des Moyens d’Identification électronique
nominaux d’un Service.

Selon la criticité et les engagements de disponibilité du Service, le Fournisseur de Service doit prévoir
des Moyens d’Identification électronique de secours afin d’assurer que les utilisateurs dont les
fonctions le nécessitent peuvent continuer à accéder au Service.

En cas d’incident majeur rendant impossible l’utilisation des Moyens d’Identification électronique
nominaux sur un Service, il peut être nécessaire d’utiliser des Moyens d’Identification électronique de
secours, non conformes à l’ensemble des exigences du présent référentiel. Leur utilisation ne peut
être envisagée que pour une durée transitoire, sous le contrôle du Fournisseur de Service.

Dans la mesure du possible, un même dispositif d’authentification pourrait être utilisé dans
différentes conditions. Par exemple, un badge ou une clé de sécurité compatible, prévu pour être
utilisé avec Pro Santé Connect, peut alternativement être utilisé pour une authentification sur un
Service local avec ses 2 facteurs d’authentification, même en cas d’indisponibilité de Pro Santé
Connect. L’Identification sur certains Services distants sera impossible mais l’Identification locale
restera ainsi conforme au référentiel.
Les cas d’oubli, perte, vol, dysfonctionnement de MIE ne rentrent pas dans le périmètre des incidents
majeurs.

Les cas cités ci-dessus, doivent être gérés dans un processus dédié dans le cadre d’un Schéma
d’Identification Electronique.

                                             EXI RIE-PS 16
Lorsque le Fournisseur de Service prévoit un Moyen d’identification électronique de secours pour
garantir ses engagements de disponibilité du service, il DOIT limiter et contrôler strictement son
activation et son utilisation.

Le Fournisseur de Service peut, par exemple :
       -   Préconiser l’activation des MIE de secours par un administrateur du Service et/ou une
           bascule automatique vers le MIE nominal dès qu’il est disponible ;
       -   Préconiser une durée maximale d’autorisation des MIE de secours inférieure ou égale à
           24h ;
       -   Limiter les accès concernés au strict nécessaire ;
       -   Imposer une Identification électronique avec au moins un facteur d’authentification ;
       -   Conserver des traces de l’activation des MIE de secours et de l’ensemble des accès
           effectués avec ce mode.
```

### EXI RIE-PS 17 — Attestation de conformité au 31/12/2026 et réserves interdites

```text
EXI RIE-PS 17

Le Fournisseur d’identité DOIT produire une attestation de conformité des Schémas d’Identification
électronique sur lesquels reposent les Moyens d’Identification électronique qu’il fournit, au plus tard
le 31/12/2026, excepté dans les cas suivants :

- Le Schéma d’Identification électronique est basé sur Pro Santé Connect ;
- Le Schéma d’Identification électronique est opéré par un Fournisseur d’identité de Pro Santé
Connect habilité par l’ANS.
En cas de réserve sur le respect d’une ou plusieurs exigences du référentiel, l’attestation de
conformité doit lister, à minima, pour chaque Schéma d’Identification électronique concerné : le
numéro de l’exigence, la description des réserves ainsi que le plan d’action et le délai prévu pour les
lever, accompagnés par l’acceptation formelle des risques induits.

Les réserves ne peuvent induire des faiblesses avec un impact significatif sur la sécurité du Schéma
d’Identification électronique. Par exemple, les réserves pouvant entrainer un impact significatif sont :
       -    La mise en œuvre comme unique facteur d’authentification d’un mot de passe faible, c’est-
            à-dire avec un niveau d’entropie inférieur à 50 bits (exemple : lorsqu’un mot de passe de 6
            caractères est accepté) ;
       -    La mise en œuvre comme unique facteur d’authentification d’un mot de passe sans mise
            en œuvre de mesures de restriction d’accès après plusieurs échecs d’authentification
            (exemple : temporisation d’accès, mécanismes de type captcha, blocage du compte,
            etc.) ;
       -    La mise en œuvre d’un mot de passe comme facteur unique d’authentification sur un
            Service exposé sur internet ;
       -    La mise en place d’un eSSO (mécanisme d’injection), s'il est démontré que le logiciel
            concerné ne permet pas la délégation d’authentification via le protocole OIDC.
       -    L’absence de déconnexion automatique de l’utilisateur au bout d’un délai d’inactivité sur le
            Service ;
       -    L’impossibilité de révoquer et/ou renouveler un Moyen d’Identification électronique ;
       -    La possibilité pour l’utilisateur d’activer un Moyen d’Identification électronique de secours
            de sa propre initiative et sans la validation d’un administrateur ;

Levée des réserves

Afin de laisser le temps nécessaire aux Fournisseurs de Service ou Fournisseur d’identité pour
satisfaire l’ensemble des exigences de cette nouvelle version du référentiel, des réserves seront
tolérées jusqu’au 31 décembre 2028.
```

### EXI RIE-PS 18 — Levée des réserves au 31/12/2028

```text
EXI RIE-PS 18
Le Fournisseur d’identité DOIT lever, au plus tard au 31/12/2028, l’ensemble des réserves de
l’attestation de conformité des Schémas d’Identification électronique mis en œuvre en regard des
exigences du présent référentiel.

Renouvellement de l’attestation

L’attestation de conformité doit être revue périodiquement afin de s’assurer qu’elle est toujours à jour
et que les évolutions du Service, de son contexte ou de la menace cyber, ne remettent pas en cause la
sécurité du ou des Schémas d’Identification électronique.
```

### EXI RIE-PS 19 — Renouvellement de l'attestation

```text
EXI RIE-PS 19
Le Fournisseur d’identité DOIT renouveler l’attestation de conformité du Schéma d’Identification
électronique :
 - Au moins une fois tous les 3 ans ;
 - Au moins tous les ans en cas de présence de réserves dans la dernière attestation réalisée.
```

### Attestation de conformité (procédure)

```text
L’attestation de conformité

L’établissement et la signature de l’attestation de conformité est une démarche visant à évaluer
formellement le niveau de conformité des Schémas d’Identification électronique mis en œuvre par un
Fournisseur d’identité, par rapport aux exigences du présent référentiel. En cas de non-conformité,
des réserves sont acceptables temporairement mais doivent être documentées et faire l’objet d’un
plan d’action.

Les risques induits par ces éventuelles réserves vis-à-vis des exigences de ce référentiel sont acceptés
par le Fournisseur d’identité qui en assume la responsabilité. Celui-ci pourra notamment mettre en
œuvre toutes les mesures qu’il juge nécessaires afin de mitiger ces risques le temps de mettre en
œuvre le plan d’action visant à lever l’ensemble des réserves qu’il aura identifiées.

La démarche de préparation de l’attestation de conformité consiste notamment à :
       -    Préparer un support documentaire, à minima sous format d’une présentation synthétique
            et intelligible des Schémas d’Identification électronique mis en œuvre et des Services et
            utilisateurs concernés ;
        - Tenir une commission de conformité au référentiel, avec le responsable légal de la
            personne morale constituant le Fournisseur d’identité (par exemple le directeur de
            l’établissement) ou son représentant, avec les acteurs pertinents : responsable de la
            sécurité des systèmes d’information (RSSI), délégué à la protection de données (DPO),
            direction des Services numériques ou des systèmes d’information, direction des
            ressources humaines, direction médicale, éditeur des Services numériques, représentants
            des patients, etc ;
        - Faire signer par le responsable légal ou son représentant l’attestation de conformité, avec
            la mention “la conformité au référentiel d’Identification électronique est attestée pour
            [nombre] mois, [avec les (éventuelles) réserves suivantes : [réserves]]”.
    La durée sera à l’appréciation du responsable qui pourra utilement prononcer une conformité pour
    une période courte si certaines réserves nécessitent de refaire un point à brève échéance. Un
    rappel calendaire sera utilement programmé peu avant l’expiration pour organiser une nouvelle
    commission. Dans tous les cas, la durée de l’attestation de conformité ne peut excéder 3 ans,
    délai au bout duquel la procédure devra être obligatoirement être renouvelée ;
        - Ce document est conservé et tenu à disposition des Fournisseurs de Services raccordés,
            ainsi que de tout organisme auditeur (CNIL, ANSSI, ANS etc.).

Nécessité de production de l’attestation de conformité

Le référentiel d’Identification électronique impose la réalisation de l’attestation de conformité pour
```

### Levée des réserves

```text
Levée des réserves

Afin de laisser le temps nécessaire aux Fournisseurs de Service ou Fournisseur d’identité pour
satisfaire l’ensemble des exigences de cette nouvelle version du référentiel, des réserves seront
tolérées jusqu’au 31 décembre 2028.
                                             EXI RIE-PS 18
```

---

## 3. Code du travail et Code de la santé publique — *recoupé*

Passages cités dans `sre2.md` (textes Légifrance non recopiés ici en entier) :

- **R4624-45-3 C. trav.** : le DMST est « placé sous la responsabilité du service ». — [Légifrance](https://www.legifrance.gouv.fr/codes/section_lc/LEGITEXT000006072050/LEGISCTA000046562772/)
- **L4624-8 / R4624-45-5 C. trav.** : accès des professionnels « chargés d'assurer, sous l'autorité du médecin du travail, le suivi » ; consultation « dans le respect des règles d'identification électronique […] définies par les référentiels mentionnés aux articles L1470-1 à L1470-5 ». — [L4624-8](https://www.legifrance.gouv.fr/codes/article_lc/LEGIARTI000043908383)
- **R4624-45-9 C. trav.** : conservation 40 ans après la dernière visite.
- **L1110-4 CSP** : partage entre professionnels « qui participent tous à sa prise en charge », informations « strictement nécessaires » ; IV : 1 an d'emprisonnement et 15 000 € d'amende. — [Légifrance](https://www.legifrance.gouv.fr/codes/article_lc/LEGIARTI000043895798)
- **D1110-3-3 CSP** : consentement au partage « pour la durée de la prise en charge ».
- **L1470-1 à L1470-5 CSP** (ordonnance n°2021-581 du 12 mai 2021) : base des référentiels d'identification électronique. — [JORF](https://www.legifrance.gouv.fr/jorf/id/JORFTEXT000043496464)

## 4. CNIL, guide pratique des services de santé au travail (2023) — *lu*

Source : [cnil_guide_spst_0.pdf](https://www.cnil.fr/sites/cnil/files/2023-12/cnil_guide_spst_0.pdf)

- Fiche 2, p. 15 : le service est responsable du traitement « que le SPST soit autonome ou interentreprises » ; il revient « à sa direction » de garantir « la possibilité de restreindre les accès conformément aux compétences et missions exercées par chacun des professionnels ».
- Fiche 2, p. 18 : en service autonome, l'employeur « assume juridiquement les conséquences d'une non-conformité ».
- Fiche 8, p. 41 : recommandation HAS « que le médecin du travail soit seul responsable de la gestion des habilitations et des accès au DMST ».
- Fiche 8, p. 42 : « supprimer les permissions d'accès obsolètes » ; « réaliser une revue annuelle des habilitations ».
- Fiche 11, p. 55 : « La règle du secret médical impose à la direction du SPST de formaliser une procédure pour définir la gestion des habilitations et des accès, sous l'autorité du médecin du travail ».
- Fiche 11, p. 56 : « que la gestion des accès soit assurée par le médecin du travail, qui endosse le rôle d'"administrateur du logiciel" ».
- Fiche 11, p. 57 : direction et personnel administratif « ne sont pas autorisés à prendre connaissance du contenu du DMST ».

Voir aussi [CNIL, Sécurité : gérer les habilitations](https://www.cnil.fr/fr/securite-gerer-les-habilitations).

## 5. Présanse, note juridique sur le DMST (janvier 2024) — *lu*

Source : [NoteJur-Le-DMST.pdf](https://www.presanse.fr/wp-content/uploads/2024/02/NoteJur-Le-DMST.pdf)

- Les données « n'appartiennent ni au médecin du travail, ni au Service ».
- « Un praticien n'emporte pas les dossiers des salariés qu'il a suivis ».

## 6. ANSM, mode opératoire d'obtention des cartes CPx (janvier 2025) — *lu*

Source : [MODE_OPeRATOIRE_OBTENTION_DE_LA_CARTE_CPX](https://e-fit.ansm.sante.fr/rnhv/help/MODE_OPeRATOIRE_OBTENTION_DE_LA_CARTE_CPX_(CPS,CPA,CPE).pdf)

- Liste des cartes : CPS (professionnel de santé), **CPA (personnel autorisé)**, CPE (personnel d'établissement), CPF (personnel en formation), CDE (directeur d'établissement).
- « La connexion avec une carte CPx nécessite un lecteur de carte et est protégée par un code confidentiel propre à son porteur. »
- Cartes « renouvelées automatiquement tous les 3 ans ».
- « L’accès à l’application e-FIT nécessite une authentification par carte CPx ou par **e-CPx** » : indice qu'une version dématérialisée existe au-delà de la seule e-CPS (point « e-CPA/e-CPE » de `sre2.md`, à confirmer auprès de l'ANS).
- Section « Commande cartes CPE/CPA pour les non professionnels de santé (secrétaire, etc.) ».

## 7. Sources secondaires — *recoupé*

- [InterCAMSP, mise à jour de l'obligation Pro Santé Connect (11/12/2025)](https://intercamsp.fr/mise-a-jour-de-lobligation-prosante-connect/) : au 31/12/2026, avoir « réalisé un état des lieux » ; au 31/12/2028, « authentification forte pour 100 % des utilisateurs ».
- [SP Informatique, authentification forte et RIE v2](https://sp-informatique.servicespartages.fr/we-would-love-to-share-a-similar-experience/) : attestation de conformité au 31/12/2026 « assortie le cas échéant de réserves » ; MFA pas « une cible finale au sens du RIE v2 ».
- [Santé numérique Normandie](https://www.sante-numerique-normandie.fr/identification-electronique/identification-electronique-des-acteurs-de-sante/identification-electronique-des-acteurs-de-sante,7907,17507.html) : « Une nouvelle version est prévue en 2026, avec un délai d'application à fin 2028. »
- [ANS, concertation RIE v2](https://esante.gouv.fr/actualites/participez-concertation-referentiel-identification-electronique-rie-v2-pgssis) — *non lu* (site protégé contre la lecture automatique) ; d'après les résumés de recherche : concertation jusqu'au 25/12/2025, publication visée au 2e trimestre 2026.
- [ANS, guide pratique d'homologation des MIE](https://esante.gouv.fr/sites/default/files/media_entity/documents/PGSSI-S_Guide_Pratique-Homologation%20MIE-V1.pdf) — *non lu*.
- Pages ANS citées dans `sre2.md`, *non lues* (site protégé contre la lecture automatique) : [cadre réglementaire de l'identification électronique](https://esante.gouv.fr/faq/exigences-ie-cadre-reglementaire-de-l-identification-electronique), [publication du référentiel (communiqué)](https://esante.gouv.fr/espace-presse/un-grand-pas-pour-la-securite-et-les-usages-du-numerique-en-sante-publication-du-referentiel-sur-lidentification-electronique), [FAQ homologation par un fournisseur de service](https://esante.gouv.fr/faq/quelles-sont-les-modalites-dhomologation-de-moyens-didentification-electronique-par-un-fournisseur-de-service-numerique), [FAQ méthodologie d'homologation](https://esante.gouv.fr/faq/quelle-methodologie-employer-pour-homologuer-un-moyen-didentification-electronique), [corpus documentaire PGSSI-S](https://esante.gouv.fr/produits-services/pgssi-s/corpus-documentaire).
- Sans extrait conservé : chiffres de Kitry (« plus de 5 000 utilisateurs », « 4,5 millions de dossiers », site [kitry.eu](https://kitry.eu/fr)) ; partage CPE/CPA (établissements / autres structures), tiré de sources secondaires ([Union dentaire](https://www.union-dentaire.com/actualite/quelles-cartes-pour-les-personnels-de-votre-cabinet-4786/)) ; e-CPS sur tablette ([ARS Grand Est](https://www.grand-est.ars.sante.fr/e-cps-pro-sante-connect)).
- Autres liens cités dans `sre2.md` : [ANS Pro Santé Connect](https://esante.gouv.fr/produits-services/pro-sante-connect), [ARS Grand Est](https://www.grand-est.ars.sante.fr/e-cps-pro-sante-connect), [Haas Avocats](https://info.haas-avocats.com/droit-digital/referentiel-sur-lidentification-electronique-ce-qui-change-pour-la-e-sante), [Escaramozzino](https://escaramozzino.legal/2022/04/20/referentiel-didentification-electronique-des-utilisateurs-des-services-numeriques-en-sante-en-vigueur-le-1er-juin-2022/), [Paymed](https://www.paymed.pro/referentiel-identification-electronique-esante/), [Union dentaire](https://www.union-dentaire.com/actualite/quelles-cartes-pour-les-personnels-de-votre-cabinet-4786/), [ANS formulaire 301](https://esante.gouv.fr/sites/default/files/media_entity/documents/F301.pdf), [Kitry](https://kitry.eu/fr).
