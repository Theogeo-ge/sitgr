SITG_BASE_URL <- "https://vector.sitg.ge.ch/arcgis/rest/services"

# Helper interne : exécute une requête httr2 et parse le JSON
sitg_perform <- function(req) {
  resp <- httr2::req_perform(req)
  httr2::resp_body_json(resp, simplifyVector = TRUE)
}

# Helper interne : compter les entités sans télécharger les géométries
.sitg_count <- function(url, where = "1=1", geometry_filter = NULL) {
  params <- list(
    where           = where,
    returnCountOnly = "true",
    f               = "json"
  )
  if (!is.null(geometry_filter)) {
    params$geometry     <- geometry_filter
    params$geometryType <- "esriGeometryEnvelope"
    params$inSR         <- 2056
  }

  req  <- httr2::request(paste0(url, "/query")) |>
    httr2::req_url_query(!!!params)

  data <- sitg_perform(req)
  data$count %||% 0L
}

`%||%` <- function(x, y) if (is.null(x)) y else x
