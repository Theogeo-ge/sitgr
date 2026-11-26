#' sitgr : Explorer et télécharger des données du SITG depuis R
#'
#' @description
#' Interface R pour les services web ArcGIS REST du Système d'Information
#' du Territoire Genevois (SITG, \url{https://sitg.ge.ch}).
#'
#' @section Fonctions principales:
#' \describe{
#'   \item{\code{\link{sitg_catalog}}}{Lister toutes les couches disponibles}
#'   \item{\code{\link{sitg_search}}}{Chercher une couche par mot-clé}
#'   \item{\code{\link{sitg_info}}}{Inspecter les métadonnées d'une couche}
#'   \item{\code{\link{sitg_download}}}{Télécharger une couche → objet sf}
#' }
#'
#' @section Workflow typique:
#' \preformatted{
#' library(sitgr)
#'
#' # 1. Trouver le nom exact de la couche
#' sitg_search("commune")
#'
#' # 2. Vérifier ses champs
#' sitg_info("AGGLO_COMMUNES")
#'
#' # 3. Télécharger (petite couche)
#' communes <- sitg_download("AGGLO_COMMUNES")
#'
#' # 4. Télécharger (grande couche > 20k entités → sur disque)
#' sitg_download("NATURE_ARBRES", output_file = "arbres.gpkg")
#' arbres <- sf::read_sf("arbres.gpkg")
#' }
#'
#' @keywords internal
"_PACKAGE"

#' @importFrom httr2 request req_url_query req_perform req_timeout
#'   resp_body_json resp_body_string req_perform_parallel
#' @importFrom sf read_sf st_crs st_write
#' @importFrom cli cli_inform cli_warn cli_abort cli_h1 cli_h2 cli_bullets
#' @importFrom stats setNames
NULL
