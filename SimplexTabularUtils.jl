module SimplexTabularUtils
using DataFrames, PrettyTables, Latexify, LaTeXStrings

"""
Estructura mutable que representa una tabla del método simplex.

# Campos
- `columnas::Vector{String}`: Nombres de las columnas de la tabla (por ejemplo, variables básicas y no básicas).
- `variables::Vector{String}`: Nombres de las variables básicas en cada fila.
- `matriz::Matrix{Float64}`: Matriz numérica que contiene los coeficientes del sistema.
- `pivote_fila::Int`: Índice de la fila del elemento pivote (inicialmente 0).
- `pivote_columna::Int`: Índice de la columna del elemento pivote (inicialmente 0).
"""
mutable struct TablaSimplex
    columnas::Vector{String}
    variables::Vector{String}
    matriz::Matrix{Float64}
    pivote_fila::Int
    pivote_columna::Int
end

"""
Constructor alternativo para `TablaSimplex` que permite usar una matriz de enteros (`Int64`).
Convierte la matriz automáticamente a `Float64`.

# Argumentos
- `columnas::Vector{String}`: Nombres de las columnas.
- `variables::Vector{String}`: Nombres de las variables básicas.
- `matriz::Matrix{Int64}`: Matriz entera de coeficientes.

# Retorna
Un objeto `TablaSimplex` con la matriz convertida a `Float64` y campos `pivote_fila` y `pivote_columna` inicializados en 0.
"""
function TablaSimplex(columnas::Vector{String}, variables::Vector{String}, matriz::Matrix{Int64})
    return TablaSimplex(copy(columnas), copy(variables), Float64.(matriz), 0, 0)
end


"""
Convierte un número racional a una cadena en formato LaTeX.

- Si el número es entero, lo devuelve tal cual.
- Si es una fracción negativa, usa el signo fuera del `\\frac`.
- Si no es racional, lo devuelve sin modificar.

# Argumentos
- `x`: Un número, preferentemente del tipo `Rational`.

# Retorna
- `LaTeXString` con la representación en LaTeX del número.
"""
function fraccion_latex(x)

    if x isa Rational
        num = numerator(x)
        den = denominator(x)
        if den == 1
            return LaTeXString("$(num)")  # Solo el entero
        elseif num < 0
            return LaTeXString("-\\frac{$(-num)}{$den}")
        else
            return LaTeXString("\\frac{$num}{$den}")
        end
    else
        return x
    end
end

"""
Muestra la tabla del método simplex en formato LaTeX con fracciones legibles.

Convierte los valores numéricos de la tabla en fracciones aproximadas,
resalta los encabezados como expresiones LaTeX y muestra la tabla con `latexify`.

# Argumentos
- `tablaS::TablaSimplex`: Una estructura que contiene `matriz`, `columnas`, `variables`.

# Retorna
- La misma tabla (`tablaS`) sin modificar su contenido.
"""
function latex_tabla(tablaS::TablaSimplex)
    #matriz_frac = fraccion_latex.(rationalize.(tablaS.matriz))
    matriz_frac = fraccion_latex.(rationalize.(tablaS.matriz, tol=1//100))
    encabezados = [LaTeXString(" "); LaTeXString.("\$" .* tablaS.columnas .* "\$")]
    df = DataFrame(hcat(tablaS.variables, matriz_frac), encabezados)
    display(latexify(df))
    println()
    return tablaS
end

"""
Imprime la tabla del método simplex en consola usando `PrettyTables.jl`.

Resalta visualmente la fila y columna pivote:
- En negro: celdas que no pertenecen a fila ni columna pivote.
- En azul: fila y columna pivote (excepto la columna de variables).

# Argumentos
- `tablaS::TablaSimplex`: Una estructura que contiene `matriz`, `columnas`, `variables`, `pivote_fila` y `pivote_columna`.

# Retorna
- La misma tabla (`tablaS`).
"""
function print_tabla(tablaS::TablaSimplex)
    matriz_redondeada = round.(tablaS.matriz, digits=3)
    data = hcat(tablaS.variables, matriz_redondeada)
    h0 = Highlighter(
    f      = (data, i, j) -> ( i != tablaS.pivote_fila && j != tablaS.pivote_columna+1  ),
    crayon = crayon"black")
    h1 = Highlighter(
        f      = (data, i, j) -> ((i == tablaS.pivote_fila || j == tablaS.pivote_columna+1) && j>1 ),
        crayon = crayon"blue")
    pretty_table(data, header=[" " ; tablaS.columnas],highlighters  = (h0,h1))
    return tablaS
end

"""
Muestra la tabla del método simplex en formato LaTeX con números decimales redondeados.

Redondea todos los valores de la matriz a 2 decimales y los presenta en una tabla LaTeX usando `latexify`.

# Argumentos
- `tablaS::TablaSimplex`: Una estructura que contiene `matriz`, `columnas`, `variables`.

# Retorna
- La misma tabla (`tablaS`).
"""
function latex_tabla_float(tablaS::TablaSimplex)
    matriz_redondeada = round.(tablaS.matriz, digits=2)
    df = DataFrame(hcat(tablaS.variables, matriz_redondeada), [" " ; tablaS.columnas])
    display(latexify(df))
    println()
    return tablaS
end

"""
Busca la variable con el mayor coeficiente positivo en la fila Z de la tabla simplex.

# Argumentos
- `tabla::TablaSimplex`: Tabla actual del método simplex.

# Comportamiento
- Ignora la primera columna (de variables básicas).
- Si no hay valores positivos, finaliza el proceso.

# Retorna
- La tabla modificada con `pivote_columna` asignado, o `nothing` si no se encuentra.
"""
function buscar_mas_positiva(tabla::TablaSimplex)
    fila_z = tabla.matriz[1, 2:end]  # Ignora la columna de variables básicas
    idx = findmax(fila_z[1:end-1])
    if idx[1] <= 0
        println("No hay valores positivos en la fila Z. Proceso terminado o requiere revisión.")
        tabla.pivote_columna = tabla.pivote_fila = 0
        return tabla
    end
    tabla.pivote_columna = idx[2] + 1
    println("Entra: ", tabla.columnas[tabla.pivote_columna])
    return tabla
end

"""
Busca la variable con el coeficiente más negativo en la fila Z de la tabla simplex.

# Argumentos
- `tabla::TablaSimplex`: Tabla actual del método simplex.

# Comportamiento
- Ignora la primera columna (de variables básicas).
- Si no hay valores negativos, finaliza el proceso.

# Retorna
- La tabla modificada con `pivote_columna` asignado, o `nothing` si no se encuentra.
"""
function buscar_mas_negativa(tabla::TablaSimplex)
    fila_z = tabla.matriz[1, 2:end]  # Ignora la columna de variables básicas
    idx = findmin(fila_z[1:end-1])
    if idx[1] >= 0
        println("No hay valores negativos en la fila Z. Proceso terminado o requiere revisión.")
        tabla.pivote_columna = tabla.pivote_fila = 0
        return tabla
    end
    tabla.pivote_columna = idx[2] + 1
    println("Entra: ", tabla.columnas[tabla.pivote_columna])
    return tabla
end

"""
Determina la variable de salida en la tabla simplex usando la razón mínimo positiva (criterio de factibilidad).

# Argumentos
- `tabla::TablaSimplex`: La tabla actual del método simplex con la columna pivote ya definida.

# Comportamiento
- Calcula los cocientes entre la columna de soluciones y la columna pivote (exceptuando la fila Z).
- Selecciona la fila con el cociente positivo mínimo como la fila pivote.
- Actualiza la variable básica correspondiente y asigna `pivote_fila`.

# Retorna
- La tabla modificada con `pivote_fila` asignado.

# Errores
- Lanza un error si no se ha definido la columna pivote (`pivote_columna == 0`).
- Lanza un error si no hay valores positivos en la columna pivote (problema ilimitado).
"""
function buscar_var_salida(tabla::TablaSimplex)
    columna_pivote = tabla.pivote_columna
    if columna_pivote == 0
        error("No se ha definido la columna pivote.")
        return tabla
    end
    num_filas = size(tabla.matriz, 1)
    columna = tabla.matriz[1:end, columna_pivote]
    soluciones = tabla.matriz[1:end, end]          # Última columna (Solución)
    #cocientes = [soluciones[i] / columna[i] for i in 1:length(columna) if columna[i] > 0]
    cocientes = []
    indices_validos = []
    for i in 2:lastindex(columna)
        if columna[i] > 0
            push!(cocientes, soluciones[i] / columna[i])
            push!(indices_validos, i)
        end
    end
    if isempty(cocientes)
        error("No hay elementos positivos en la columna pivote. El problema es ilimitado.")
        tabla.pivote_columna = 0
        return tabla
    end
    min_index = argmin(cocientes)
    fila_pivote = indices_validos[min_index]
    tabla.pivote_fila = fila_pivote
    #print(cocientes)
    #print(indices_validos)
    variable_salida = tabla.variables[fila_pivote]
    tabla.variables[fila_pivote] = tabla.columnas[columna_pivote]
    println("Sale : ", variable_salida, "\tCocientes:",cocientes)
    return tabla
end

"""
Busca la variable de entrada en la fila Z de la tabla simplex, según el criterio especificado.

# Argumentos
- `tabla::TablaSimplex`: Tabla actual del método simplex.
- `tipo::Symbol`: Criterio de búsqueda. Puede ser `:negativa` (default) o `:positiva`.

# Comportamiento
- Si `tipo == :negativa`, busca el valor más negativo en la fila Z (para maximización).
- Si `tipo == :positiva`, busca el valor más positivo (para minimización).
- Asigna la columna correspondiente como `pivote_columna`.

# Retorna
- La tabla modificada si se encuentra una variable de entrada.
- `nothing` si no hay valores válidos según el criterio.
"""
function buscar_var_entrada(tabla::TablaSimplex, tipo::Symbol=:negativa)
    fila_z = tabla.matriz[1, 2:end]  # Ignora la columna de variables básicas

    if tipo == :negativa
        return buscar_mas_negativa(tabla)
    elseif tipo == :positiva
        return buscar_mas_positiva(tabla)
    else
        error("El argumento 'tipo' debe ser :negativa o :positiva")
    end
    println("Entra: ", tabla.columnas[tabla.pivote_columna])
    return tabla
end

"""
Normaliza la fila pivote dividiendo todos sus elementos por el valor del elemento pivote.

# Argumentos
- `tabla::TablaSimplex`: La tabla actual del método simplex con fila y columna pivote ya definidas.

# Comportamiento
- Divide cada elemento de la fila pivote por el pivote para convertir ese elemento en 1.

# Retorna
- La tabla modificada con la fila pivote normalizada.

# Errores
- Si la fila o columna pivote no están definidas (`== 0`).
- Si el elemento pivote es cero.
"""
function normalizar_fila_pivote(tabla::TablaSimplex)
    #println("Normalizar fila pivote")
    if tabla.pivote_fila == 0 || tabla.pivote_columna == 0
        error("No se ha definido correctamente la fila o columna pivote.")        
    end

    fila = tabla.pivote_fila
    columna = tabla.pivote_columna

    # Obtener el elemento pivote
    pivote = tabla.matriz[fila, columna]
    if pivote == 0
        error("El elemento pivote es cero, no se puede dividir.")
    end

    # Dividir toda la fila pivote por el elemento pivote
    tabla.matriz[fila, :] /= pivote
    return tabla
end

"""
Elimina los valores distintos de cero en la columna pivote, fuera de la fila pivote.

# Argumentos
- `tablaS::TablaSimplex`: La tabla actual del método simplex con la fila y columna pivote ya definidas.

# Comportamiento
- Realiza combinaciones lineales de filas para hacer ceros en la columna pivote, excepto en la fila pivote.

# Retorna
- La tabla modificada con ceros en la columna pivote (excepto el pivote).
"""
function hacer_ceros(tablaS::TablaSimplex)
    #println("Hacer ceros")
    if tablaS.pivote_fila == 0 || tablaS.pivote_columna == 0
        error("No se ha definido correctamente la fila o columna pivote.")        
    end
    fila_pivote = tablaS.pivote_fila
    columna_pivote = tablaS.pivote_columna
    matriz = tablaS.matriz

    for i in 1:size(matriz, 1)
        if i != fila_pivote
            factor = matriz[i, columna_pivote]
            matriz[i, :] .-= factor .* matriz[fila_pivote, :]
        end
    end

    return tablaS
end

"""
Ajusta la fila Z para eliminar el efecto de una variable artificial.

# Argumentos
- `tabla::TablaSimplex`: Tabla actual del método simplex.
- `var::String`: Nombre de la variable artificial que se desea eliminar de la fila Z.

# Comportamiento
- Sustituye la fila Z combinándola linealmente con la fila correspondiente a la variable básica `var`.

# Retorna
- La tabla con la fila Z ajustada.

# Errores
- Si `var` no está en las columnas o no es una variable básica.
- Si el coeficiente usado para el ajuste es cero.
"""
function ajustar_fila_z(tabla::TablaSimplex, var::String)
    idx_col = findfirst(==(var), tabla.columnas)
    if idx_col === nothing
        error("La variable $var no se encuentra en la tabla.")
    end

    idx_fila = findfirst(x -> x == var, tabla.variables)
    if idx_fila === nothing
        error("La variable $var no es una variable básica.")
    end

    coef = tabla.matriz[idx_fila, idx_col]
    if coef == 0
        error("Coeficiente nulo, no se puede eliminar la variable artificial")
    end
    #@show(idx_fila, idx_col,coef)
    tabla.matriz[1, :] .-= (tabla.matriz[idx_fila, :] * tabla.matriz[1, idx_col]) / coef
    return tabla
end

"""
Elimina columnas especificadas de la tabla simplex.

# Argumentos
- `tabla::TablaSimplex`: La tabla actual.
- `columnas_a_eliminar::Vector{String}`: Nombres de columnas a eliminar.

# Comportamiento
- Elimina columnas y variables básicas asociadas a los nombres dados.

# Retorna
- Una nueva instancia de `TablaSimplex` sin las columnas especificadas.
"""
function eliminar_columnas(tabla::TablaSimplex, columnas_a_eliminar::Vector{String})
    indices_a_eliminar = findall(c -> c in columnas_a_eliminar, tabla.columnas)
    if indices_a_eliminar === nothing
        error("Las columnas $indices_a_eliminar no se encuentran en la tabla.")
    end
    nuevas_columnas = filter(c -> !(c in columnas_a_eliminar), tabla.columnas)
    nueva_matriz = tabla.matriz[:, setdiff(1:size(tabla.matriz, 2), indices_a_eliminar)]

    nuevas_variables = filter(v -> !(v in columnas_a_eliminar), tabla.variables)

    return TablaSimplex(nuevas_columnas, nuevas_variables, nueva_matriz, 0, 0)
end

"""
Reemplaza la fila Z con una nueva y actualiza su nombre.

# Argumentos
- `tabla::TablaSimplex`: Tabla actual.
- `nombre::String`: Nuevo nombre para la fila Z.
- `nueva_fila_z`: Vector o matriz con los nuevos coeficientes de la fila Z.

# Comportamiento
- Reemplaza la primera fila de la matriz por `nueva_fila_z`.
- Cambia el nombre de la fila Z en `variables` y `columnas`.

# Retorna
- La tabla modificada con la nueva fila Z.
"""
function cambiar_fila_z(tabla::TablaSimplex, nombre::String, nueva_fila_z)
    # Convertir a Vector{Float64} si es necesario
    if isa(nueva_fila_z, Matrix)
        nueva_fila_z = Float64.(vec(nueva_fila_z))
    elseif isa(nueva_fila_z, Vector)
        nueva_fila_z = Float64.(nueva_fila_z)
    else
        error("La nueva fila Z debe ser un Vector o Matrix.")
    end

    # Cambiar la primera fila de la matriz
    tabla.matriz[1, :] = nueva_fila_z

    # Actualizar el nombre en variables y columnas
    tabla.variables[1] = nombre
    tabla.columnas[1] = nombre
    return tabla
end

export TablaSimplex,
       ajustar_fila_z,
       buscar_mas_negativa,
       buscar_mas_positiva,
       buscar_var_entrada,
       buscar_var_salida,
       cambiar_fila_z,
       eliminar_columnas,
       fraccion_latex,
       hacer_ceros,
       latex_tabla,
       latex_tabla_float,
       normalizar_fila_pivote,
       print_tabla
end