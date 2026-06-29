#' sitgr : Explorer et télécharger des données du SITG depuis R

#' # 1. Trouver le nom exact de la couche
#' sitg_search("commune")
#'
#' # 2. Vérifier ses champs
#' sitg_info("AGGLO_COMMUNES")
#'
#' # 3. Télécharger (petite couche)
#' communes <- sitg_download("CAD_COMMUNES")
#'
#' # 4. Télécharger (grande couche > 20k entités direct sur disque)
#' sitg_download("SIPV_MN_CARTO_5", output_file = "mn.gpkg")
#' mn5 <- sf::read_sf("mn.gpkg")
#' }
#'

