# SimplexTabularUtils.jl

Este módulo proporciona utilidades para implementar el método simplex en forma tabular usando Julia.

## 📦 Instalación

Actualmente, este módulo no está registrado. Para usarlo de forma local:

```julia
include("SimplexTabularUtils.jl")
using .SimplexTabularUtils
```

O desde GitHub:

```julia
using Pkg
Pkg.add(url="https://raw.githubusercontent.com/dbhmath/optimz/main/SimplexTabularUtils")
```

## 📚 Funcionalidades principales

- `buscar_var_salida(tabla::TablaSimplex)`
- `normalizar_fila_pivote(tabla::TablaSimplex)`
- `hacer_ceros(tabla::TablaSimplex)`
- `ajustar_fila_z(tabla::TablaSimplex, var::String)`
- `eliminar_columnas(tabla::TablaSimplex, columnas_a_eliminar::Vector{String})`
- `cambiar_fila_z(tabla::TablaSimplex, nombre::String, nueva_fila_z)`

Estas funciones permiten manipular tablas del método simplex paso a paso.

## 🧱 Dependencias

Este módulo usa:

- `DataFrames`
- `PrettyTables`
- `Latexify`
- `LaTeXStrings`

Asegúrate de tenerlas instaladas:

```julia
using Pkg
Pkg.add.(["DataFrames", "PrettyTables", "Latexify", "LaTeXStrings"])
```

## 👩‍🏫 Uso en notebooks

Puedes importar el módulo y trabajar con él en Google Colab usando Julia o en un entorno local con Jupyter.


