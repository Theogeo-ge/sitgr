# sitgr

Package R pour explorer et télécharger des couches géospatiales depuis le
[SITG](https://ge.ch/sitg) (Système d'Information du Territoire à Genève)
via son API ArcGIS REST.

## Installation

```r
install.packages("pak")
pak::pak("Theogeo-ge/sitgr")
```

## Fonctions

| Fonction | Description |
|---|---|
| `sitg_catalog()` | Liste toutes les couches disponibles |
| `sitg_search("mot_clé")` | Cherche une couche par nom |
| `sitg_info("NOM_COUCHE")` | Affiche les métadonnées d'une couche |
| `sitg_download("NOM_COUCHE")` | Télécharge la couche comme objet `sf` |

## Dépendances

`httr2`, `sf`, `cli`

## Auteur

Theogeo-ge