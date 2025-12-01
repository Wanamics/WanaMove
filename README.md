# Extension WanaMove

Si vous disposez de plusieurs environnements Business Central et que vous devez 'déménager' une société d'un environnement à l'autre, cette extension vous permet de transférer l'essentiel.

Le présent document n'est qu'une ébauche et il faudra vous référer au sources pour plus de détails.

![WanaMove](images/wanamove.png)

**Sommaire**

- [Extraction des données](#extraction-des-données)
  - [Ecritures comptables (?Report=87992)](#ecritures-comptables-report87992)
  - [Ecritures immobilisation (?report=87993)](#ecritures-immobilisation-report87993)
  - [Ecritures relance](#ecritures-relance)
- [Page Ecritures comptables](#page-ecritures-comptables)
- [Script SQL](#script-sql)


## Extraction des données

Ces traitements ne sont pas proposés au menu et doivent être lancés en suffixe de l'URL Business Central.

### Ecritures comptables (?Report=87992)

Exporte les écritures en format texte (séparateur tabulation).
* Une balance d'ouverture sur le journal d'à nouveau (paramètre)
* le détail pour les journaux sélectionnés (définis par la souscription à l'event OnInitializeSourceCodeWithDetails),
* La centralisation par mois et par compte pour les autres.

**Paramètres** (pour la balance d'ouverture): 
  *  Code journal
  *  Date d'ouverture
  *  N° document

### Ecritures immobilisation (?report=87993)  

**Paramètres**

Idem

### Ecritures relance

Exporte les **Ecritures relance** relatives à des **Ecritures client** non soldées (**Ouvert** est coché).

Seules

## Page Ecritures comptables

**Colonnes ajoutées**

* Code journal
* N° séquence
**Actions ajoutées**

* Import WanaMove : Importe les écritures exportées plus haut.

## Script SQL

Si vous utilisez encore une installation *On Premise* (contrairement à une installation *SaaS* administrée par Microsoft), vous pouvez utiliser un script SQL pour transférer des données d'une table à une autre.

Le traitement ci-après permet de générer ce script à partir de Business Central.
Il n'est pas accessible via les menus, mais en ajoutant à l'URL Business Central le suffixe ?Report=87900
