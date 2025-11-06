DROP VIEW IF EXISTS v_IncidenciaLimpia;

-- PASO 2: Creamos la vista nueva con las columnas de Clave_Ent y Cve. Municipio
CREATE VIEW v_IncidenciaLimpia AS

-- CTE para "des-pivotear" las columnas de meses
WITH UnpivotedData AS (
    SELECT
        -- --- ¡COLUMNAS AÑADIDAS! ---
        r."Clave_Ent",
        r."Cve. Municipio",
        -- ---------------------------
        r."Año",
        r."Entidad",
        r."Municipio",
        r."Tipo de delito",
        r."Subtipo de delito",
        r."Modalidad",
        
        m.Mes_Nombre,
        m.Mes_Numero,
        
        CASE
            WHEN m.Mes_Nombre = 'Enero' THEN r."Enero"
            WHEN m.Mes_Nombre = 'Febrero' THEN r."Febrero"
            WHEN m.Mes_Nombre = 'Marzo' THEN r."Marzo"
            WHEN m.Mes_Nombre = 'Abril' THEN r."Abril"
            WHEN m.Mes_Nombre = 'Mayo' THEN r."Mayo"
            WHEN m.Mes_Nombre = 'Junio' THEN r."Junio"
            WHEN m.Mes_Nombre = 'Julio' THEN r."Julio"
            WHEN m.Mes_Nombre = 'Agosto' THEN r."Agosto"
            WHEN m.Mes_Nombre = 'Septiembre' THEN r."Septiembre"
            WHEN m.Mes_Nombre = 'Octubre' THEN r."Octubre"
            WHEN m.Mes_Nombre = 'Noviembre' THEN r."Noviembre"
            WHEN m.Mes_Nombre = 'Diciembre' THEN r."Diciembre"
        END AS TotalDelitos
        
    FROM
        incidencia_raw r
    
    CROSS JOIN LATERAL (
        VALUES
            ('Enero', 1), ('Febrero', 2), ('Marzo', 3), ('Abril', 4),
            ('Mayo', 5), ('Junio', 6), ('Julio', 7), ('Agosto', 8),
            ('Septiembre', 9), ('Octubre', 10), ('Noviembre', 11), ('Diciembre', 12)
    ) AS m(Mes_Nombre, Mes_Numero)
)

-- Selección final y creación de la columna de Fecha
SELECT
    -- --- ¡COLUMNAS AÑADIDAS! ---
    ud."Clave_Ent",
    ud."Cve. Municipio",
    -- ---------------------------
    make_date(ud."Año", ud.Mes_Numero, 1) AS Fecha,
    ud."Año",
    ud.Mes_Nombre AS Mes,
    ud."Entidad",
    ud."Municipio",
    ud."Tipo de delito" AS Tipo_Delito,
    ud."Subtipo de delito" AS Subtipo_Delito,
    ud."Modalidad",
    ud.TotalDelitos
FROM
    UnpivotedData ud
WHERE
    ud.TotalDelitos IS NOT NULL AND ud.TotalDelitos > 0;
	