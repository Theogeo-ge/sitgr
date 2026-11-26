#' Inspecter les métadonnées d'une couche
#'
#' @param layer_name Nom exact de la couche (retourné par `sitg_search()`)
#' @return Les métadonnées brutes (invisible)
#' @export
sitg_info <- function(layer_name) {
  url <- paste0(SITG_BASE_URL, "/", layer_name, "/FeatureServer/0")

  req <- httr2::request(url) |>
    httr2::req_url_query(f = "json")

  data <- sitg_perform(req)

  # Compter les entités via .sitg_count() — plus fiable que data$count
  n <- tryCatch(
    .sitg_count(url),
    error = function(e) NA_integer_
  )

  cli::cli_h1(data$name %||% layer_name)
  cli::cli_bullets(c(
    "*" = paste("Géométrie :", data$geometryType %||% "inconnue"),
    "*" = paste("Entités   :", if (is.na(n)) "?" else n),
    "*" = paste("Champs    :", length(data$fields), "colonnes")
  ))

  if (!is.null(data$fields) && length(data$fields) > 0) {
    # Extraction sécurisée — certains champs n'ont pas de clé "name"
    champs <- vapply(data$fields, function(f) {
      f[["name"]] %||% "?"
    }, character(1))
    cli::cli_h2("Champs disponibles")
    cli::cli_bullets(stats::setNames(champs, rep("*", length(champs))))
  }

  invisible(data)
}
