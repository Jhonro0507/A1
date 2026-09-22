# Tarea 1 — Inferencia Causal

Proyecto de la Tarea 1 del curso de Inferencia Causal (Maestría). Contiene el
documento de respuestas en LaTeX (6 preguntas) y el script de análisis en R
que genera todas las tablas y figuras que el documento incluye.

**Autor:** Jhonatan Román Román
**Fecha:** 22 de septiembre de 2026

## Estructura de carpetas

```
A1/
├── A1.tex          # Documento principal (XeLaTeX), preguntas 1-6
├── code.R          # Script de análisis en R (genera todo lo de figures/)
├── data/           # Datos de entrada
├── figures/        # Tablas .tex y figuras generadas por code.R
├── build/          # Archivos generados al compilar A1.tex (PDF, aux, log)
└── .vscode/
    └── settings.json  # Configuración de LaTeX Workshop
```

## Correr el script de R

**Importante: ejecutar `code.R` desde PowerShell, no desde Git Bash/MSYS.**
El archivo `data/MERGE2023.dta` pesa ~1.17 GB y `Rscript` lanzado desde
Git Bash produce un segmentation fault al leerlo (incluso limitando filas
con `n_max`); el mismo comando funciona sin problema desde PowerShell.

1. Colocar los datos de entrada en `data/` (ver lista de archivos abajo).
2. Desde PowerShell, en la raíz de `A1/`:

```powershell
Rscript code.R
```

El script es autocontenido: corre de principio a fin sobre los datos crudos
y genera automáticamente todas las tablas (`.tex`) y figuras (`.pdf`/`.png`)
en `figures/`, además de un subconjunto intermedio (`data/enoe_subset.csv`)
usado en la Pregunta 4.

## Compilar el documento (.tex)

El documento se compila con **XeLaTeX**. Todos los archivos generados
(PDF, `.aux`, `.log`, `.synctex.gz`, etc.) se guardan en `build/`.

- **Desde VS Code:** con la extensión LaTeX Workshop instalada, abrir
  `A1.tex` y compilar (recipe `xelatex` configurado en
  `.vscode/settings.json`). El PDF resultante queda en `build/A1.pdf`.
- **Desde la terminal:**

```bash
xelatex -synctex=1 -interaction=nonstopmode -file-line-error -output-directory=build A1.tex
```

El preámbulo de `A1.tex` incluye un parche para un conflicto conocido entre
`booktabs`+`longtable` y `polyglossia` (idioma español) que de otro modo
produce el error `Undefined control sequence \cmrsideswitch` en tablas
largas; no requiere ninguna acción adicional.

## Datos de entrada (`data/`)

| Archivo | Descripción | Usado en | ¿En el repo? |
|---|---|---|---|
| `data-salud.csv` | Ensayo clínico simulado (915 pacientes, índice de salud, tratamiento `D`, 10 características) | Preguntas 1-2 | Sí |
| `MERGE2023.dta` | ENOE 2023 (INEGI), encuesta de ocupación y empleo de México, ~1.17 GB, 331 variables | Pregunta 4 | No (ver abajo) |
| `merged_all_surveys.dta` | Datos de evaluación de impacto de un programa de capacitación empresarial (Davies et al. 2023) | Preguntas 5-6 | No (ver abajo) |
| `enoe_subset.csv` | Subconjunto de `MERGE2023.dta` (generado por `code.R`; no editar a mano) | Pregunta 4 | Sí |

`MERGE2023.dta` y `merged_all_surveys.dta` están excluidos del repositorio
(ver `.gitignore`) por su tamaño y/o restricciones de distribución. Para
reproducir el análisis desde cero, colocarlos manualmente en `data/`:

- **`MERGE2023.dta`**: ENOE 2023, descargable desde el sitio del INEGI
  (https://www.inegi.org.mx/programas/enoe/15ymas/).
- **`merged_all_surveys.dta`**: datos de Davies et al. (2023),
  disponibles bajo solicitud a los autores (ver
  https://doi.org/10.1016/j.jdeveco.2023.103244).

## Tablas y figuras generadas (`figures/`)

| Archivo | Pregunta | Contenido |
|---|---|---|
| `tabla_balance.tex` | 1(a) | Balance de las 10 covariables entre grupos de tratamiento |
| `resultados_d.tex` | 1(d) | Prueba F de significancia conjunta (covariables → D) |
| `reg_corta.tex` | 2(a) | Regresión corta $Y \sim D$ |
| `reg_larga.tex` | 2(c) | Regresión larga $Y \sim D + \text{controles}$ |
| `tabla_reg_fec.tex` | 4(b) | Comparación regresión con microdatos vs. medias condicionales (FEC) |
| `figura_fec.pdf` / `.png` | 4(c) | Figura estilo MHE 3.1.1: FEC muestral + distribuciones condicionales |
| `p5a.tex` | 5(a) | Media y SD de `sales_4w_base` |
| `p5b.tex` | 5(b) | Media de `sales_4w_base` por grupo |
| `p5c.tex` | 5(c) | Prueba de balance de `sales_4w_base` (efectos fijos de estrato) |
| `p5d.tex` | 5(d) | Prueba F conjunta de las 21 covariables de la Tabla 1 |
| `p6a.tex` | 6(a) | Media de `sales_4w_end` en el grupo de control |
| `p6b.tex` | 6(b) | Efecto del tratamiento sobre `sales_4w_end` (errores robustos HC1) |
| `p6c.tex` | 6(c) | Comparación de errores estándar: HC1 vs. cluster por estrato vs. Tabla 2 del artículo |

## Versiones

- **R:** 4.5.2 (2025-10-31 ucrt)
- **Paquetes usados y versión instalada:**
  - `tidyverse` 2.0.0
  - `knitr` 1.51
  - `car` 3.1.5
  - `sandwich` 3.1.1
  - `lmtest` 0.9.40
  - `haven` 2.5.5
