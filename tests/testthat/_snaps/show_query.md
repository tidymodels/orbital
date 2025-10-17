# show_query works

    Code
      show_query(orbital_obj, con = con)
    Output
      CASE WHEN ((`disp` IS NULL)) THEN 230.721875 WHEN NOT ((`disp` IS NULL)) THEN `disp` END AS disp
      (`disp` - 230.721875) / 123.938693831382 AS disp
      20.090625 + (`disp` * -5.10814813429143) AS .pred

