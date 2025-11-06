# Análisis de Incidencia Delictiva en México (SQL, PostgreSQL y Power BI)

Este es un proyecto de Business Intelligence de nivel avanzado que analiza la incidencia delictiva en México. El proyecto maneja el ciclo de vida completo del análisis de datos, desde la ingesta y transformación (ETL) de millones de registros con SQL, hasta el modelado de datos complejo y la creación de un dashboard interactivo de nivel ejecutivo en Power BI.

---

## 1. Problema de Negocio

Los datos públicos sobre delincuencia en México (proporcionados por el SESNSP) son masivos, crudos y están en un formato "ancho" (meses como columnas). Esto los hace imposibles de analizar en Excel.

Además, un análisis simple basado en "totales" es engañoso. Una entidad con más población (como el Estado de México) siempre parecerá más peligrosa que una con menos (como Colima). El verdadero desafío es entender la **tasa de delincuencia** (delitos por cada 100k habitantes) y sus tendencias.

## 2. Objetivo

Construir un dashboard interactivo que permita a los usuarios (periodistas, consultores de seguridad, ciudadanos) explorar y entender los patrones reales de la incidencia delictiva en México, respondiendo a preguntas como:
* ¿Cuál es la **tasa real** de delitos por cada 100,000 habitantes en cada estado?
* ¿Cómo ha cambiado esta tasa año tras año?
* ¿Cuáles son los municipios ("puntos calientes") con mayor tasa delictiva dentro de un estado?
* ¿Cuál es el delito más común y cómo ha variado su tendencia?

## 3. Herramientas y Metodología

* **PostgreSQL (SQL):** Se usó como base de datos para manejar el gran volumen de datos (+3 millones de filas). Indispensable para el proceso de **ETL (Extracción, Transformación y Carga)**.
* **Power Query:** Se utilizó para la ingesta y limpieza de la fuente de datos secundaria (Población del INEGI).
* **Power BI (DAX y Modelado):** Se utilizó para el modelado de datos, la creación de métricas avanzadas (Inteligencia de Tiempo, Tasas) y el diseño del dashboard interactivo.

---

## 4. Proceso de Ingeniería y Modelado de Datos

Este proyecto requirió una fuerte fase de ingeniería de datos antes de la visualización.

### Fase 1: ETL (Extracción, Transformación y Carga) con SQL

1.  **Extracción:** Se descargaron los datos crudos del **Secretariado Ejecutivo del Sistema Nacional de Seguridad Pública (SESNSP)**.
2.  **Carga:** El CSV masivo se cargó en una tabla `incidencia_raw` en **PostgreSQL** usando la línea de comandos (`psql \copy`), ya que la interfaz gráfica fallaba con el tamaño del archivo.
3.  **Transformación (UNPIVOT):** Los datos venían en formato "ancho" (columnas: `Enero`, `Febrero`, `Marzo`...). Se creó una **VISTA** en SQL (`v_IncidenciaLimpia`) para "des-pivotear" los datos a un formato "largo" (filas: `Mes`, `TotalDelitos`). Esta vista también añadió las claves geográficas (`Clave_Ent`, `Cve. Municipio`).

### Fase 2: Modelado de Datos (Power BI)

Este fue el desafío más complejo del proyecto.
1.  **Integración de Datos:** Se importó una segunda fuente de datos: el Censo de Población **INEGI 2020**, que se limpió en Power Query para obtener la población por municipio.
2.  **Tabla Calendario:** Se creó una tabla `Calendario` maestra con DAX.
3.  **Relaciones Complejas:**
    * **Problema:** Los datos de Delitos y Población no se podían unir por nombre (homónimos) ni por claves simples.
    * **Solución:** Se realizó **Ingeniería de Características** en Power Query, creando una **clave compuesta** (`Cve. Municipio` = `Clave_Ent * 1000 + MUN`) en la tabla `Poblacion`.
    * Se estableció una relación **Uno a Muchos (1:*)** entre `Poblacion[Cve. Municipio]` y `v_incidencialimpia[Cve. Municipio]`.
    * Se cambió la **Dirección de Filtro Cruzado a `Ambas`** para permitir que el mapa (tabla "Muchos") filtre la población (tabla "Uno"), permitiendo el cálculo de tasas dinámicas.

### Fase 3: Métricas DAX Avanzadas

Se creó una tabla de `_Medidas` para centralizar los cálculos, incluyendo:
* `Total Delitos = SUM(...)`
* `Poblacion Total = SUM(...)`
* **`Tasa Delitos x 100k = DIVIDE([Total Delitos], [Poblacion Total]) * 100000`** (La métrica maestra).
* `Total Delitos AA` (Inteligencia de Tiempo).
* `Crecimiento % vs AA`.
* `Delito Más Común = TOPN(...)` (Para la tarjeta dinámica).
* `Estado Mayor Tasa = TOPN(...)` (Para la tarjeta dinámica).

---

## 5. El Dashboard: Hallazgos Clave

El dashboard final se compone de 3 páginas interactivas diseñadas en "dark mode" para un impacto visual profesional.

### Página 1: Panorama Nacional
* Muestra los KPIs nacionales, incluyendo la **Tasa por 100k Hab.**, el **Crecimiento Interanual** y las tarjetas dinámicas del **Delito Principal** y la **Entidad con Mayor Incidencia**.
* El visual central es un **mapa coroplético** de México, coloreado por la `Tasa Delitos x 100k`. La escala de color es **relativa** (basada en Mínimo, Mediana, Máximo) para reaccionar a los filtros de año o delito.
* Un gráfico de barras y líneas muestra la tendencia histórica del volumen de delitos (barras) vs. su crecimiento porcentual (línea).

### Página 2: Análisis Estatal (Drill-through)
* Se accede haciendo clic derecho en un estado del mapa principal.
* Muestra los KPIs filtrados para ese estado.
* El visual principal es un **ranking de municipios por Tasa de Delitos**, identificando los "puntos calientes" dentro de la entidad.

### Página 3: Análisis por Delito
* Muestra un ranking de los delitos más comunes por volumen total.
* Un gráfico de líneas filtrado por `Top 5` muestra las tendencias históricas de los 5 delitos principales.
* Un Treemap desglosa los `Subtipos de Delito` (ej. "Robo a transeúnte", "Robo de vehículo").

---

## 6. Enlace al Dashboard Interactivo

*Link para interactuar con el dashboard*

**https://app.powerbi.com/view?r=eyJrIjoiODEzYjNlMzctNWQ2Zi00N2NhLTgyOWYtNDZlZDhjODIzOGE5IiwidCI6ImIwM2EzOWY4LWVlNDAtNDk3My1hNDUwLTIyOGExYzY3YWI0YSJ9**

**Pagina 1: Panorama Nacional**
<img width="1215" height="680" alt="image" src="https://github.com/user-attachments/assets/a61326a2-13a9-4d6c-aff4-02817ce77277" />

**Pagina 1: Análisis Estatal**
<img width="1210" height="676" alt="image" src="https://github.com/user-attachments/assets/0085fdac-4359-4234-a650-eb1877fc634b" />


**Análisis por Delito**
<img width="1211" height="677" alt="image" src="https://github.com/user-attachments/assets/34dcd563-2ea3-45e3-81ee-0e3ad2e0d645" />

