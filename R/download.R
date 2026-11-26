#' Télécharger une couche vecteur du SITG
#'
#' @param layer_name Nom exact de la couche (retourné par `sitg_search()`)
#' @param where      Filtre SQL ArcGIS (défaut : toutes les entités)
#' @param page_size  Nombre d'entités par requête (défaut : 1000)
#' @param max_active Nombre de connexions HTTP parallèles (défaut : 10)
#' @param output_file Chemin vers un fichier .gpkg pour les grandes couches.
#'   Si fourni, les pages sont écrites sur disque au fur et à mesure
#'   (évite le freeze mémoire sur les couches > 20 000 entités).
#'   La fonction retourne alors le chemin (invisible) au lieu d'un sf.
#' @param quiet      Masquer les messages de progression
#' @return Un objet sf en EPSG:2056, ou le chemin output_file (invisible)
#' @export
sitg_download <- function(layer_name,
                           where       = "1=1",
                           page_size   = 2000,
                           max_active  = 10,
                           output_file = NULL,
                           quiet       = FALSE) {

  url <- paste0(SITG_BASE_URL, "/", layer_name, "/FeatureServer/0")

  # 1. Compter le total d'entités avant de paginer
  n_total <- .sitg_count(url, where)

  if (n_total == 0L) {
    cli::cli_warn("Aucune entité trouvée pour {.val {layer_name}} avec where = {.val {where}}")
    return(invisible(NULL))
  }

  n_pages <- ceiling(n_total / page_size)

  if (!quiet) {
    cli::cli_inform(c(
      "i" = "{n_total} entit\u00e9{?s} \u2014 {n_pages} page{?s} de {page_size}"
    ))
  }

  # 2. Construire toutes les requêtes d'un coup
  offsets <- seq(0, n_total - 1, by = page_size)

  reqs <- lapply(offsets, function(off) {
    httr2::request(paste0(url, "/query")) |>
      httr2::req_url_query(
        where             = where,
        outFields         = "*",
        resultOffset      = off,
        resultRecordCount = page_size,
        f                 = "geojson"
      ) |>
      httr2::req_timeout(60)
  })

  # 3. Exécuter toutes les requêtes en parallèle
  if (!quiet) cli::cli_inform("  Envoi de {length(reqs)} requ\u00eate{?s} en parall\u00e8le...")

  resps <- httr2::req_perform_parallel(
    reqs,
    on_error   = "continue",  # continue si une page échoue
    max_active = max_active   # connexions simultanées max
  )

  # 4. Convertir chaque réponse en sf (skip les erreurs)
  pages <- lapply(seq_along(resps), function(i) {
    r <- resps[[i]]
    if (inherits(r, "error")) {
      cli::cli_warn("Page {i}/{n_pages} \u00e9chou\u00e9e : {conditionMessage(r)}")
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

  pages <- Filter(Negate(is.null), pages)

  if (length(pages) == 0L) {
    cli::cli_abort("Toutes les pages ont \u00e9chou\u00e9.")
  }

  # 5a. Grande couche : écrire sur disque page par page (évite le freeze RAM)
  if (!is.null(output_file)) {
    if (!quiet) cli::cli_inform("  \u00c9criture vers {.file {output_file}}...")

    for (i in seq_along(pages)) {
      sf::st_write(
        pages[[i]],
        output_file,
        append = (i > 1),
        quiet  = TRUE
      )
    }

    n_ecrites <- sum(vapply(pages, nrow, integer(1)))
    if (!quiet) {
      cli::cli_inform(c("v" = "{n_ecrites} entit\u00e9{?s} \u00e9crite{?s} dans {.file {output_file}}"))
    }
    return(invisible(output_file))
  }

  # 5b. Petite couche : assembler en mémoire
  result <- do.call(rbind, pages)

  if (!quiet) {
    cli::cli_inform(c(
      "v" = "{nrow(result)} entit\u00e9{?s} t\u00e9l\u00e9charg\u00e9e{?s} \u2014 CRS : EPSG:{sf::st_crs(result)$epsg %||% '?'}"
    ))
  }

  result
}
