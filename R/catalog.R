
sitg_catalog <- function() {
  req <- httr2::request(SITG_BASE_URL) |>
    httr2::req_url_query(f = "json")

  data <- sitg_perform(req)

  services <- data$services
  
  services$name <- gsub("^Hosted/", "", services$name)

  services[, c("name", "type")]
}


sitg_search <- function(keyword) {
  cat <- sitg_catalog()
  cat[grepl(keyword, cat$name, ignore.case = TRUE), ]
}
