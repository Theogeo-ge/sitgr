SITG_BASE_URL <- "https://vector.sitg.ge.ch/arcgis/rest/services/Hosted"

SITG_SERVERS <- list(
  vector   = "https://vector.sitg.ge.ch/arcgis/rest/services/Hosted",
  raster   = "https://raster.sitg.ge.ch/arcgis/rest/services/Hosted",
  thematic = "https://thematic.sitg.ge.ch/arcgis/rest/services/Hosted"
)

# Helper 
.resolve_layer_url <- function(layer, server = "vector", layer_id = 0) {
  if (grepl("^https?://", layer)) {
    return(layer)
  }
  base <- SITG_SERVERS[[server]] %||% SITG_SERVERS[["vector"]]
  paste0(base, "/", layer, "/FeatureServer/", layer_id)
}

# Helper 
sitg_perform <- function(req) {
  resp <- httr2::req_perform(req)
  httr2::resp_body_json(resp, simplifyVector = TRUE)
}

# helper 

sitg_request <- function(url) {
  httr2::request(url) |> httr2::req_url_query(f = "json")
}


# Helper 
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