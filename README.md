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

El dashboard final es una herramienta interactiva de 3 páginas, diseñada en "dark mode" para un análisis de alto impacto y una lectura clara.

### Página 1: Panorama Nacional
Esta página principal ofrece un resumen ejecutivo de la seguridad en el país, respondiendo "¿Cómo estamos?".
* **KPIs Estratégicos:** Se muestran 6 tarjetas principales, incluyendo las métricas de contexto (`Población Total: 126.01 mill.`, `Delitos Totales: 21.24 mill.`) y las métricas de análisis clave: `Incidencia (Tasa x 100k): 17 mil` y `Crecimiento Interanual: 10.54%`.
* **Tarjetas Dinámicas (TOP 1):** Dos tarjetas avanzadas usan DAX (`TOPN`) para mostrar en tiempo real el `Delito Principal` (ej. "Robo") y la `Entidad con Mayor Incidencia` (ej. "México"), las cuales se actualizan según los filtros aplicados.
* **Mapa Coroplético (Visual Central):** El mapa de México está configurado con formato condicional (verde-amarillo-rojo) basado en la `Tasa Delitos x 100k` relativa. Esto permite identificar visualmente los "puntos calientes" del país de un solo vistazo.
* **Gráfico de Tendencia (YoY):** Un gráfico combinado de barras apiladas que compara la `Tasa Delitos` (Año Actual, barras blancas) contra la `Tasa Delitos AA` (Año Anterior, línea), permitiendo una comparativa visual inmediata.

### Página 2: Análisis Estatal (Drill-through)
Esta página se activa al hacer clic derecho en un estado del mapa, respondiendo "¿Qué está pasando *dentro* de esta entidad?".
* **KPIs Estatales:** Las tarjetas principales se filtran para mostrar la `Tasa Delitos`, `Crecimiento % vs AA` y `Total Delitos` basados en el estado seleccionado.
* **Rankings Estatales y Municipales:** Dos gráficos de barras identifican los "Estados con Alta Incidencia" (Top 5 en rojo) y los "Municipios con Alta Incidencia" (Bottom 5 en verde), ambos basados en su `Incidencia`.
* **Análisis de Estacionalidad:** Un gráfico de líneas (`Tasa Delitos por Mes`) muestra la tendencia mensual de la tasa *dentro* de ese estado, permitiendo identificar patrones estacionales (ej. picos en marzo, valles en diciembre).

### Página 3: Análisis por Tipo de Delito
Esta página desglosa *qué* delitos están ocurriendo.
* **Ranking de Incidencia:** Un gráfico de barras (`Incidencia por delito`) clasifica los delitos más comunes, destacando "Robo", "Lesiones" y "Daño a la propiedad" como los principales.
* **Tendencia Trimestral (Top 5):** Un gráfico de líneas compara las tendencias trimestrales de los 5 delitos con mayor incidencia, permitiendo ver si, por ejemplo, "Robo" sube mientras "Lesiones" baja.
* **Desglose de Sub-Delito (Treemap):** Un mapa de árbol (`Treemap`) muestra visualmente la proporción de todos los sub-delitos, permitiendo identificar rápidamente categorías problemáticas como "Robo a casa habitación" o "Violencia familiar".

---

## 6. Enlace al Dashboard Interactivo

*Link para interactuar con el dashboard*

**https://app.powerbi.com/view?r=eyJrIjoiODEzYjNlMzctNWQ2Zi00N2NhLTgyOWYtNDZlZDhjODIzOGE5IiwidCI6ImIwM2EzOWY4LWVlNDAtNDk3My1hNDUwLTIyOGExYzY3YWI0YSJ9**

**Pagina 1: Panorama Nacional**
<img width="1210" height="676" alt="image" src="https://github.com/user-attachments/assets/04051588-9276-49b8-81b5-1fd21ffcdef7" />


**Pagina 1: Análisis Estatal**
<img width="1214" height="680" alt="image" src="https://github.com/user-attachments/assets/81f53543-bd65-4524-bc9e-e51d35936fbd" />


**Análisis por Delito**
<img width="1214" height="679" alt="image" src="https://github.com/user-attachments/assets/a405d2de-f714-47e7-8338-9fea448c9de8" />


