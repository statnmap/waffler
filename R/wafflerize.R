#' Create multipolygons waffle from regular point grid
#'
#' @param x dataframe with x/y coordinates, preferably from regular point grid
#' @param fact multiplicative factor to magnify the coordinates so that it is not too small for mapping
#' @param res_x x resolution of the regular grid
#' @param res_y y resolution of the regular grid
#'
#' @importFrom dplyr mutate
#' @importFrom purrr map2
#' @importFrom sf st_polygon st_sf st_transform
#'
#' @return polygon
#' @export
#'
wafflerize <- function(x, fact = 100,
                       res_x, res_y) {

  # browser()
  # res_x <- res_y <- 1

  if (!all(c("x", "y") %in% names(x))) {
    stop("data must contain `x` and `y` columns")
  }

  if (missing(res_x) | missing(res_y)) {
    res <- get_resolutions(x)
    res_x <- res$res_x
    res_y <- res$res_y
  }

  # With x
  res <- x %>%
    # Increase distances
    mutate(x_map = x * fact,
           y_map = y * fact) %>%
    mutate(geometry = map2(x_map, y_map, ~st_polygon(list(
      matrix(c(.x - 0.5 * res_x * fact,
               .x + 0.5 * res_x * fact,
               .x + 0.5 * res_x * fact,
               .x - 0.5 * res_x * fact,
               .x - 0.5 * res_x * fact,

               .y - 0.5 * res_y * fact,
               .y - 0.5 * res_y * fact,
               .y + 0.5 * res_y * fact,
               .y + 0.5 * res_y * fact,
               .y - 0.5 * res_y * fact),
             ncol = 2, byrow = FALSE
      )
    )))
    ) %>%
    st_sf(crs = 3857) %>%
    st_transform(4326)

  return(res)

}

#' Get resolutions of regular point grid
#'
#' @inheritParams wafflerize
#'
#' @importFrom dplyr arrange mutate lag
#'
#' @export
get_resolutions <- function(x) {
  all_res <- x %>%
    arrange(x) %>%
    mutate(x_diff = x - lag(x)) %>%
    arrange(y) %>%
    mutate(y_diff = y - lag(y))

  res_x <- unique(abs(all_res$x_diff)) %>%
    .[.>0] %>%
    min(., na.rm = TRUE)
  res_y <- unique(abs(all_res$y_diff)) %>%
    .[.>0] %>%
    min(., na.rm = TRUE)

  list(res_x = res_x, res_y = res_y)
}
