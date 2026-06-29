
sitg_download <- function(layer,
                          server      = "vector",
                          layer_id    = 0,
                          where       = "1=1",
                          fields      = "*",
                          crs         = 2056,
                          bbox        = NULL,
                          max_records = Inf,
                          max_active  = 10,
                          output_file = NULL,
                          quiet       = FALSE) {

  url <- .resolve_layer_url(layer, server, layer_id)

  out_fields <- if (identical(fields, "*")) "*" else paste(fields, collapse = ",")

  geometry_filter <- NULL
  if (!is.null(bbox)) {
    bb <- sf::st_bbox(sf::st_transform(bbox, 2056))
    geometry_filter <- paste0(
      bb["xmin"], ",", bb["ymin"], ",", bb["xmax"], ",", bb["ymax"]
    )
  }

  n_total <- .sitg_count(url, where, geometry_filter)
  if (!quiet) cli::cli_inform("Couche : {.val {basename(dirname(url))}}")
  if (!quiet) cli::cli_inform("  {n_total} entité{?s} correspondant au filtre.")

  n_fetch   <- if (is.finite(max_records)) min(n_total, max_records) else n_total
  page_size <- 2000
  n_pages   <- ceiling(n_fetch / page_size)
  offsets   <- seq(0, n_fetch - 1, by = page_size)

  if (!quiet && n_pages > 1) {
    cli::cli_inform("  Téléchargement en {n_pages} page{?s} (parallèle)...")
  }

  base_params <- list(where = where, outFields = out_fields, f = "geojson")
  if (!is.null(crs))             base_params$outSR        <- crs
  if (!is.null(geometry_filter)) base_params$geometry     <- geometry_filter
  if (!is.null(geometry_filter)) base_params$geometryType <- "esriGeometryEnvelope"
  if (!is.null(geometry_filter)) base_params$inSR         <- 2056

  query_url <- paste0(url, "/query")

  reqs <- lapply(offsets, function(off) {
    n_this <- min(page_size, n_fetch - off)
    httr2::request(query_url) |>
      httr2::req_url_query(!!!base_params,
                           resultOffset      = off,
                           resultRecordCount = n_this) |>
      httr2::req_timeout(60)
  })

  resps <- httr2::req_perform_parallel(
    reqs,
    on_error   = "continue",
    max_active = max_active
  )

  # Convertir chaque réponse GeoJSON -> sf
  all_pages <- lapply(seq_along(resps), function(i) {
    r <- resps[[i]]
    if (inherits(r, "error")) {
      cli::cli_warn("Page {i}/{n_pages} échouée : {conditionMessage(r)}")
      return(NULL)
    }
    tryCatch(
      sf::read_sf(httr2::resp_body_string(r)),
      error = function(e) {
        cli::cli_warn("Lecture GeoJSON page {i} impossible : {e$message}")
        NULL
      }
    )
  })

  all_pages <- Filter(Negate(is.null), all_pages)

  if (length(all_pages) == 0L) {
    cli::cli_abort("Toutes les pages ont échoué.")
  }

  # Assembler toutes les pages en un seul sf (rapide)
  if (!quiet) cli::cli_inform("  Assemblage des pages...")
  result <- do.call(rbind, lapply(all_pages, function(x) x[, names(all_pages[[1]])]))

  # Écriture disque en une seule opération
  if (!is.null(output_file)) {
    if (!quiet) cli::cli_inform("  Écriture vers {.file {output_file}}...")
    sf::st_write(result, output_file, quiet = TRUE, delete_dsn = TRUE)
    if (!quiet) {
      cli::cli_inform(c("v" = "{nrow(result)} entité{?s} écrite{?s} dans {.file {output_file}}"))
    }
    return(invisible(output_file))
  }

  if (!quiet) {
    cli::cli_inform(
      c("v" = "{nrow(result)} entité{?s} téléchargée{?s} — CRS : EPSG:{sf::st_crs(result)$epsg %||% '?'}")
    )
  }

  result
}

