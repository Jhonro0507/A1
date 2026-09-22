# ==============================================================
# Autor: Jhonatan Román Román
# Fecha: 22 de septiembre de 2026
# Descripción: Script de análisis para la Tarea 1 del curso
#              de Inferencia Causal.
# ==============================================================

# ------------------ Librerías ------------------
library(tidyverse)
library(knitr)
library(car)
library(sandwich)
library(lmtest)
library(haven)


# ------------------ Cargar datos ------------------
datos <- read_csv("data/data-salud.csv")


# ------------------ Pregunta 1 ------------------

# Pregunta 1 - Inciso (a): balance de covariables

alpha <- 0.10

caracteristicas <- c("edad", "ingreso", "educacion", "imc", "fumador",
                      "ejercicio", "cronica", "seguro", "urbano", "mujer")

tabla_balance <- map_dfr(caracteristicas, function(var) {
  modelo <- lm(reformulate("D", response = var), data = datos)
  coefs <- summary(modelo)$coefficients

  tibble(
    Característica = var,
    Coeficiente = coefs["D", "Estimate"],
    `Error estándar` = coefs["D", "Std. Error"],
    `Valor p` = coefs["D", "Pr(>|t|)"],
    Balanceada = `Valor p` > alpha
  )
})

kable(
  tabla_balance,
  format = "latex",
  booktabs = TRUE,
  longtable = TRUE,
  linesep = "",
  digits = 3,
  caption = "Balance de covariables entre grupos de tratamiento"
) %>%
  writeLines("figures/tabla_balance.tex")

# Pregunta 1 - Inciso (d): prueba F de significancia conjunta

modelo_conjunto <- lm(D ~ edad + ingreso + educacion + imc + fumador +
                         ejercicio + cronica + seguro + urbano + mujer,
                       data = datos)

prueba_f <- linearHypothesis(
  modelo_conjunto,
  c("edad = 0", "ingreso = 0", "educacion = 0", "imc = 0", "fumador = 0",
    "ejercicio = 0", "cronica = 0", "seguro = 0", "urbano = 0", "mujer = 0")
)

f_estadistico <- prueba_f$F[2]
f_valor_p <- prueba_f$`Pr(>F)`[2]
f_df1 <- prueba_f$Df[2]
f_df2 <- prueba_f$Res.Df[2]

cat("Estadístico F:", f_estadistico, "\n")
cat("Valor p:", f_valor_p, "\n")

tabla_resultados_d <- tibble(
  `Estadístico F` = round(f_estadistico, 4),
  `Grados de libertad` = paste0(f_df1, ", ", f_df2),
  `Valor p` = round(f_valor_p, 4)
)

kable(
  tabla_resultados_d,
  format = "latex",
  booktabs = TRUE,
  longtable = TRUE,
  linesep = "",
  caption = "Prueba F de significancia conjunta"
) %>%
  cat(sep = "\n", file = "figures/resultados_d.tex")


# ------------------ Pregunta 2 ------------------

# Pregunta 2 - Inciso (a): regresión corta

reg_corta <- lm(Y ~ D, data = datos)
coefs_corta <- summary(reg_corta)$coefficients

tabla_reg_corta <- tibble(
  Término = c("Intercepto", "D"),
  Coeficiente = round(coefs_corta[, "Estimate"], 4),
  `Error estándar` = round(coefs_corta[, "Std. Error"], 4),
  `Valor p` = format(coefs_corta[, "Pr(>|t|)"], scientific = TRUE, digits = 3),
  `R2` = c(round(summary(reg_corta)$r.squared, 4), NA)
)

kable(
  tabla_reg_corta,
  format = "latex",
  booktabs = TRUE,
  longtable = TRUE,
  linesep = "",
  digits = 4,
  caption = "Regresión corta: efecto del tratamiento sobre Y"
) %>%
  cat(sep = "\n", file = "figures/reg_corta.tex")

print(summary(reg_corta))

# Pregunta 2 - Inciso (c): regresión larga con controles

reg_larga <- lm(Y ~ D + edad + ingreso + educacion + imc + fumador +
                   ejercicio + cronica + seguro + urbano + mujer,
                 data = datos)
coefs_larga <- summary(reg_larga)$coefficients

tabla_reg_larga <- tibble(
  Término = rownames(coefs_larga),
  Coeficiente = round(coefs_larga[, "Estimate"], 4),
  `Error estándar` = round(coefs_larga[, "Std. Error"], 4),
  `Valor p` = format(coefs_larga[, "Pr(>|t|)"], scientific = TRUE, digits = 3)
)

kable(
  tabla_reg_larga,
  format = "latex",
  booktabs = TRUE,
  longtable = TRUE,
  linesep = "",
  digits = 4,
  caption = "Regresión larga: efecto del tratamiento sobre Y con controles"
) %>%
  cat(sep = "\n", file = "figures/reg_larga.tex")

print(summary(reg_larga))


# ------------------ Pregunta 3 ------------------
# Pregunta puramente teórica (sesgo de selección y consistencia de MCO);
# no requiere código. Ver desarrollo e incisos (a)-(b) en A1.tex.


# ------------------ Pregunta 4 ------------------

# Pregunta 4 - Preparación de datos
# NOTA: MERGE2023.dta pesa ~1.17 GB. Cargarlo con Rscript vía Git Bash/MSYS
# provoca un segmentation fault; este script se ejecuta desde PowerShell.
# clase2 clasifica a la población en ocupada (1) y desocupada (2); es la
# variable correcta de condición de ocupación (c_ocu11c clasifica el TIPO
# de ocupación/profesión, no la condición de ocupación).

datos4 <- read_dta("data/MERGE2023.dta")
var_ocup <- "clase2"

enoe_subset <- datos4 %>%
  select(anios_esc, ingocup, hrsocup, all_of(var_ocup))

write_csv(enoe_subset, "data/enoe_subset.csv")

cat("Variable de ocupación usada:", var_ocup, "\n")
cat("Filas en el subconjunto:", nrow(enoe_subset), "\n")
cat("Tamaño del archivo:", round(file.info("data/enoe_subset.csv")$size / 1e6, 2), "MB\n")

# Pregunta 4 - Inciso (a)/(b): muestra y función esperanza condicional (FEC)

enoe <- read_csv("data/enoe_subset.csv", show_col_types = FALSE) %>%
  filter(clase2 == 1, ingocup > 0, hrsocup > 0, anios_esc >= 0, anios_esc <= 25) %>%
  mutate(log_ingreso_semanal = log(ingocup / 4.33))

q_low <- quantile(enoe$log_ingreso_semanal, 0.01, na.rm = TRUE)
q_high <- quantile(enoe$log_ingreso_semanal, 0.99, na.rm = TRUE)

enoe <- enoe %>%
  filter(log_ingreso_semanal >= q_low, log_ingreso_semanal <= q_high)

cat("\nObservaciones finales para Pregunta 4:", nrow(enoe), "\n")

# Regresión con microdatos
reg_micro <- lm(log_ingreso_semanal ~ anios_esc, data = enoe)

# Medias por año de escolaridad (CEF muestral)
cef_esc <- enoe %>%
  group_by(anios_esc) %>%
  summarise(media_log = mean(log_ingreso_semanal), n = n(), .groups = "drop")

# Regresión ponderada sobre las medias
reg_medias <- lm(media_log ~ anios_esc, data = cef_esc, weights = n)

cat("\nCoeficiente anios_esc (microdatos):", coef(reg_micro)["anios_esc"], "\n")
cat("Coeficiente anios_esc (medias ponderadas):", coef(reg_medias)["anios_esc"], "\n")

tabla_reg_fec <- tibble(
  Regresión = c("Microdatos", "Medias ponderadas"),
  Intercepto = round(c(coef(reg_micro)["(Intercept)"], coef(reg_medias)["(Intercept)"]), 4),
  `Coeficiente años esc.` = round(c(coef(reg_micro)["anios_esc"], coef(reg_medias)["anios_esc"]), 4),
  `Error estándar` = round(c(
    summary(reg_micro)$coefficients["anios_esc", "Std. Error"],
    summary(reg_medias)$coefficients["anios_esc", "Std. Error"]
  ), 4),
  N = c(nrow(enoe), nrow(cef_esc))
)

kable(
  tabla_reg_fec,
  format = "latex",
  booktabs = TRUE,
  longtable = TRUE,
  linesep = "",
  digits = 4,
  caption = "Comparación: regresión con microdatos vs. regresión sobre medias condicionales (FEC)"
) %>%
  cat(sep = "\n", file = "figures/tabla_reg_fec.tex")

# Pregunta 4 - Inciso (c): gráfica de la FEC, estilo MHE figura 3.1.1
# Se agregan distribuciones condicionales verticales en los niveles
# educativos clave de México: primaria completa (6), secundaria completa (9),
# bachillerato completo (12), licenciatura completa (16), maestría completa
# (18) y doctorado completo (22).

niveles_clave <- c(6, 9, 12, 16, 18, 22)
ancho_max <- 1.4

distribuciones <- map_dfr(niveles_clave, function(x0) {
  y <- enoe %>% filter(anios_esc == x0) %>% pull(log_ingreso_semanal)
  dens <- density(y, n = 200, adjust = 1.8)
  escala <- ancho_max / max(dens$y)
  tibble(
    anios_esc = x0,
    x = c(x0, x0 + dens$y * escala, x0),
    y = c(dens$x[1], dens$x, dens$x[length(dens$x)])
  )
})

grafica_fec <- ggplot() +
  geom_polygon(
    data = distribuciones,
    aes(x = x, y = y, group = anios_esc),
    fill = "grey85", color = "black", linewidth = 0.4
  ) +
  geom_line(
    data = cef_esc, aes(x = anios_esc, y = media_log),
    color = "black", linewidth = 1
  ) +
  geom_point(
    data = cef_esc, aes(x = anios_esc, y = media_log),
    color = "black", size = 1.5
  ) +
  geom_abline(
    intercept = coef(reg_micro)["(Intercept)"],
    slope = coef(reg_micro)["anios_esc"],
    color = "black", linetype = "dashed", linewidth = 0.7
  ) +
  coord_cartesian(ylim = c(6, 9)) +
  labs(x = "Años de escolaridad", y = "Log ingreso semanal") +
  theme_minimal(base_size = 12) +
  theme(
    panel.grid.minor = element_blank(),
    panel.grid.major = element_line(color = "grey90"),
    plot.background = element_rect(fill = "white", color = NA),
    panel.background = element_rect(fill = "white", color = NA)
  )

ggsave("figures/figura_fec.pdf", grafica_fec, width = 6, height = 4)
ggsave("figures/figura_fec.png", grafica_fec, width = 6, height = 4, dpi = 300)


# ------------------ Pregunta 5 ------------------
# NOTA: se ejecuta desde PowerShell (ver nota de MERGE2023.dta más arriba).

datos5 <- read_dta("data/merged_all_surveys.dta")

covariables5 <- c(
  "yrs_experience_base", "is_fam_base", "age_base", "married_base",
  "in_federal_base", "in_guat_base", "university_base", "hh_earnings_g_8000",
  "sales_4w_base", "profits_4w_val_base", "any_emp_base", "num_emp_base",
  "keeps_accounts_base", "marketing_practices_base", "acc_fin_practices_base",
  "planning_practices_base", "bus_sector_food_base", "bus_sector_beauty_base",
  "bus_sector_handicrafts_base", "bus_sector_service_base", "essential_bus_base"
)

# Pregunta 5 - Inciso (a): media y desviación estándar de sales_4w_base

p5a <- tibble(
  Media = round(mean(datos5$sales_4w_base, na.rm = TRUE), 0),
  `Desviación estándar` = round(sd(datos5$sales_4w_base, na.rm = TRUE), 0)
)

kable(
  p5a,
  format = "latex",
  booktabs = TRUE,
  longtable = TRUE,
  linesep = "",
  caption = "Ventas del mes anterior (línea base): media y desviación estándar"
) %>%
  cat(sep = "\n", file = "figures/p5a.tex")

cat("Inciso (a) - Media:", p5a$Media, "SD:", p5a$`Desviación estándar`, "\n")

# Pregunta 5 - Inciso (b): media de sales_4w_base por grupo

p5b <- datos5 %>%
  group_by(treat_1_or_3) %>%
  summarise(media_ventas = round(mean(sales_4w_base, na.rm = TRUE), 0), .groups = "drop") %>%
  mutate(Grupo = ifelse(treat_1_or_3 == 1, "Tratamiento", "Control")) %>%
  select(Grupo, `Media de ventas` = media_ventas)

kable(
  p5b,
  format = "latex",
  booktabs = TRUE,
  longtable = TRUE,
  linesep = "",
  caption = "Ventas del mes anterior (línea base) por grupo"
) %>%
  cat(sep = "\n", file = "figures/p5b.tex")

cat("Inciso (b):\n")
print(p5b)

# Pregunta 5 - Inciso (c): prueba de balance de sales_4w_base

reg_p5c <- lm(sales_4w_base ~ treat_1_or_3 + factor(strata_base), data = datos5)
coefs_p5c <- summary(reg_p5c)$coefficients

p5c <- tibble(
  Coeficiente = round(coefs_p5c["treat_1_or_3", "Estimate"], 2),
  `Error estándar` = round(coefs_p5c["treat_1_or_3", "Std. Error"], 2),
  `Valor p` = round(coefs_p5c["treat_1_or_3", "Pr(>|t|)"], 4)
)

kable(
  p5c,
  format = "latex",
  booktabs = TRUE,
  longtable = TRUE,
  linesep = "",
  caption = "Prueba de balance: ventas del mes anterior en línea base"
) %>%
  cat(sep = "\n", file = "figures/p5c.tex")

cat("Inciso (c) - Valor p de treat_1_or_3:", p5c$`Valor p`, "\n")

# Pregunta 5 - Inciso (d): prueba F conjunta de las covariables

formula_p5d <- as.formula(
  paste("treat_1_or_3 ~", paste(covariables5, collapse = " + "), "+ factor(strata_base)")
)
reg_p5d <- lm(formula_p5d, data = datos5)

prueba_f_p5d <- linearHypothesis(
  reg_p5d,
  paste0(covariables5, " = 0")
)

f_p5d <- prueba_f_p5d$F[2]
p_p5d <- prueba_f_p5d$`Pr(>F)`[2]
df1_p5d <- prueba_f_p5d$Df[2]
df2_p5d <- prueba_f_p5d$Res.Df[2]

p5d <- tibble(
  `Estadístico F` = round(f_p5d, 4),
  `Grados de libertad` = paste0(df1_p5d, ", ", df2_p5d),
  `Valor p` = round(p_p5d, 4)
)

kable(
  p5d,
  format = "latex",
  booktabs = TRUE,
  longtable = TRUE,
  linesep = "",
  caption = "Prueba F conjunta: covariables como predictores del tratamiento"
) %>%
  cat(sep = "\n", file = "figures/p5d.tex")

cat("Inciso (d) - Valor p conjunto:", p5d$`Valor p`, "\n")


# ------------------ Pregunta 6 ------------------
# NOTA: se ejecuta desde PowerShell (ver nota de MERGE2023.dta más arriba).

# Pregunta 6 - Inciso (a): media de sales_4w_end para el grupo de control

p6a <- tibble(
  `Media de control` = round(mean(datos5$sales_4w_end[datos5$treat_1_or_3 == 0], na.rm = TRUE), 0)
)

kable(
  p6a,
  format = "latex",
  booktabs = TRUE,
  longtable = TRUE,
  linesep = "",
  caption = "Ventas 2 meses post-intervención: media del grupo de control"
) %>%
  cat(sep = "\n", file = "figures/p6a.tex")

cat("\nInciso (a) - Media control (sales_4w_end):", p6a$`Media de control`, "\n")

# Pregunta 6 - Inciso (b): efecto del tratamiento con errores robustos HC1

reg_p6 <- lm(sales_4w_end ~ treat_1_or_3 + factor(strata_base), data = datos5)

ee_hc1 <- coeftest(reg_p6, vcov = vcovHC(reg_p6, type = "HC1"))

p6b <- tibble(
  Coeficiente = round(ee_hc1["treat_1_or_3", "Estimate"], 2),
  `Error estándar (HC1)` = round(ee_hc1["treat_1_or_3", "Std. Error"], 2),
  `Valor p` = round(ee_hc1["treat_1_or_3", "Pr(>|t|)"], 4)
)

kable(
  p6b,
  format = "latex",
  booktabs = TRUE,
  longtable = TRUE,
  linesep = "",
  caption = "Efecto del tratamiento sobre ventas post-intervención (errores robustos HC1)"
) %>%
  cat(sep = "\n", file = "figures/p6b.tex")

cat("Inciso (b) - Coef:", p6b$Coeficiente, "SE (HC1):", p6b$`Error estándar (HC1)`, "p:", p6b$`Valor p`, "\n")

# Pregunta 6 - Inciso (c): errores estándar agrupados por estrato (cluster-robust)

ee_cluster <- coeftest(reg_p6, vcov = vcovCL(reg_p6, cluster = datos5$strata_base, type = "HC1"))

p6c <- tibble(
  Especificación = c("HC1 (heterocedasticidad)", "Cluster por estrato", "Tabla 2 (Davies et al. 2023)"),
  Coeficiente = c(
    round(ee_hc1["treat_1_or_3", "Estimate"], 0),
    round(ee_cluster["treat_1_or_3", "Estimate"], 0),
    4112
  ),
  `Error estándar` = c(
    round(ee_hc1["treat_1_or_3", "Std. Error"], 0),
    round(ee_cluster["treat_1_or_3", "Std. Error"], 0),
    1461
  )
)

kable(
  p6c,
  format = "latex",
  booktabs = TRUE,
  longtable = TRUE,
  linesep = "",
  caption = "Comparación de errores estándar: HC1 vs. cluster por estrato vs. Tabla 2"
) %>%
  cat(sep = "\n", file = "figures/p6c.tex")

cat("Inciso (c) - SE cluster:", round(ee_cluster["treat_1_or_3", "Std. Error"], 0), "\n")
