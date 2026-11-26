#' Lister toutes les couches disponibles sur le SITG
#'
#' @return Un data.frame avec les colonnes `name` et `type`
#' @export
sitg_catalog <- function() {
  req <- httr2::request(SITG_BASE_URL) |>
    httr2::req_url_query(f = "json")

  data <- sitg_perform(req)

  services <- data$services
  # Supprimer le préfixe "Hosted/" du nom (bug serveur : double préfixe)
  services$name <- gsub("^Hosted/", "", services$name)
  services <- services[services$type == "FeatureServer", ]

  services[, c("name", "type")]
}

#' Chercher une couche par mot-clé
#'
#' @param keyword Terme de recherche (insensible à la casse)
#' @return Un data.frame filtré
#' @export
sitg_search <- function(keyword) {
  cat <- sitg_catalog()
  cat[grepl(keyword, cat$name, ignore.case = TRUE), ]
}
