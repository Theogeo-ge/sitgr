
  # sitg_info() — inspecter les métadonnées d'une couche SITG


sitg_info <- function(layer, server = "vector", layer_id = 0) {
  url <- .resolve_layer_url(layer, server, layer_id)
  
  cli::cli_inform("Chargement des métadonnées : {.url {url}}")
  
  req  <- sitg_request(url)
  meta <- sitg_perform(req)
  n <- tryCatch(
    .sitg_count(url),
    error = function(e) NA_integer_
  )
  
  # affichage propre
  cli::cli_h1("Couche : {meta$name %||% basename(url)}")
  
  if (!is.null(meta$description) && nchar(meta$description) > 0) {
    cli::cli_inform("{meta$description}")
  }
  
  cli::cli_h2("Informations générales")
  cli::cli_bullets(c(
    "*" = "Type géométrie : {.val {meta$geometryType %||% 'N/A'}}",
    "*" = "Entités        : {.val {if (is.na(n)) '?' else n}}",
    "*" = "CRS (WKID)     : {.val {meta$extent$spatialReference$wkid %||% 'N/A'}}",
    "*" = "Max enreg.     : {.val {meta$maxRecordCount %||% 'N/A'}}"
  ))
  
  # extent
  if (!is.null(meta$extent)) {
    ext <- meta$extent
    cli::cli_h2("Étendue spatiale")
    cli::cli_bullets(c(
      "*" = "XMin : {round(ext$xmin, 0)}  XMax : {round(ext$xmax, 0)}",
      "*" = "YMin : {round(ext$ymin, 0)}  YMax : {round(ext$ymax, 0)}"
    ))
  }
  
  # champs
  if (!is.null(meta$fields) && length(meta$fields) > 0) {
    fields <- meta$fields
    if (is.data.frame(fields)) {
      cli::cli_h2("Champs ({nrow(fields)})")
      for (i in seq_len(nrow(fields))) {
        cli::cli_bullets(c("*" = "{fields$name[i]} ({fields$type[i]})"))
      }
    }
  }
  
  invisible(meta)
}
